# Scheduled OpenCode jobs. Each declared job becomes a launchd agent that runs
# `opencode2 run` inside the nono sandbox with a free-form prompt. No jobs are
# declared by default.
#
# Example (in a user or host module):
#
#   programs.opencodeJobs = {
#     # Plain prompt.
#     review-queue = {
#       schedule = [ { Hour = 8; Minute = 0; } ];
#       cwd = "/Users/aaccardo/GitLab/proton/monorepo/project/calendar/web";
#       prompt = "List the merge requests waiting for my review and summarise each one.";
#     };
#     # Skill plus prompt: the skill is loaded before the prompt runs.
#     dependency-audit = {
#       schedule = [ { Hour = 8; Minute = 0; Weekday = 1; } ];
#       cwd = "/Users/aaccardo/GitLab/proton/monorepo/project/calendar/web";
#       skill = "dependency-audit";
#       prompt = "Check the workspace dependencies and report outdated ones.";
#       timeout = "1h";
#     };
#   };
{ inputs, ... }:
{
  flake.modules.homeManager.opencode-jobs =
    hmArgs@{ lib, pkgs, ... }:
    let
      cfg = hmArgs.config.programs.opencodeJobs;
      isDarwin = pkgs.stdenv.hostPlatform.isDarwin;

      nono = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.nono;
      opencodeBin = lib.getExe' hmArgs.config.programs.opencode.package "opencode2";
      profileFile = hmArgs.config.sops.templates."nono-opencode.json".path;
      logRoot = "${hmArgs.config.xdg.stateHome}/opencode-jobs";

      promptFiles = lib.mapAttrs (
        name: job:
        pkgs.writeText "opencode-job-${name}.md" (
          lib.optionalString (job.skill != null) "Load the `${job.skill}` skill and follow it.\n\n"
          + job.prompt
        )
      ) cfg;

      # Runs outside the sandbox. Arguments: job name, agent, timeout, prompt file.
      runner = pkgs.writeShellApplication {
        name = "opencode-job";
        runtimeInputs = [
          nono
          pkgs.coreutils
        ];
        text = ''
          umask 077

          # Values go in as argv, never into the AppleScript source.
          notify() { /usr/bin/osascript -e 'on run argv' -e 'display notification (item 1 of argv) with title "opencode job"' -e 'end run' "$1" || true; }

          name="$1"
          agent="$2"
          timeout_spec="$3"
          prompt_file="$4"

          job_dir=${lib.escapeShellArg logRoot}/"$name"
          mkdir -p "$job_dir"
          chmod 700 ${lib.escapeShellArg logRoot} "$job_dir"

          # macOS has no flock: an atomic mkdir works as the lock. A lock whose
          # owner is gone (no pid, or pid not running) is stale and is reclaimed.
          lock="$job_dir/.lock"
          if ! mkdir "$lock" 2>/dev/null; then
            pid="$(cat "$lock/pid" 2>/dev/null || true)"
            if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
              echo "opencode-job: $name skipped: still running"
              exit 0
            fi
            rm -rf "$lock"
            if ! mkdir "$lock" 2>/dev/null; then
              echo "opencode-job: $name skipped: still running"
              exit 0
            fi
          fi
          echo "$$" > "$lock/pid"
          trap 'rm -rf "$lock"' EXIT

          # Wait for the sops-rendered nono profile (it may land after login).
          profile_file=${lib.escapeShellArg profileFile}
          for _ in $(seq 1 30); do [ -s "$profile_file" ] && break; sleep 1; done
          if [ ! -s "$profile_file" ]; then
            echo "opencode-job: $name profile missing" >&2
            notify "$name failed: nono profile missing"
            exit 1
          fi

          # launchd's environment is minimal; nono's profile expands $XDG_* variables.
          export PATH="$PATH:${hmArgs.config.home.profileDirectory}/bin:/run/current-system/sw/bin"
          export XDG_CONFIG_HOME=${lib.escapeShellArg hmArgs.config.xdg.configHome}
          export XDG_DATA_HOME=${lib.escapeShellArg hmArgs.config.xdg.dataHome}
          export XDG_CACHE_HOME=${lib.escapeShellArg hmArgs.config.xdg.cacheHome}
          export XDG_STATE_HOME=${lib.escapeShellArg hmArgs.config.xdg.stateHome}
          TMPDIR="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR)"
          export TMPDIR

          out="$job_dir/$(date +%Y-%m-%dT%H%M%S).jsonl"
          echo "opencode-job: $name start $(date -Is) agent=$agent timeout=$timeout_spec"

          set +e
          timeout "$timeout_spec" nono run --silent --profile "$profile_file" --allow-cwd -- \
            ${opencodeBin} run --standalone --format json --agent "$agent" "$(cat "$prompt_file")" > "$out"
          rc=$?
          set -e

          echo "opencode-job: $name end $(date -Is) rc=$rc"

          if [ "$rc" -ne 0 ]; then
            notify "$name failed (rc=$rc)"
            exit "$rc"
          fi
        '';
      };
    in
    {
      options.programs.opencodeJobs = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              schedule = lib.mkOption {
                type = lib.types.listOf lib.types.attrs;
                description = "launchd StartCalendarInterval entries. The job runs at each one.";
              };
              cwd = lib.mkOption {
                type = lib.types.str;
                description = "Working directory for the job (launchd WorkingDirectory), passed to nono as --allow-cwd.";
              };
              prompt = lib.mkOption {
                type = lib.types.lines;
                description = "Free-form prompt given to `opencode2 run`. The prompt is stored in the Nix store (world-readable): never put secrets in it.";
              };
              skill = lib.mkOption {
                type = lib.types.nullOr (lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9._-]*");
                default = null;
                description = "Optional skill id. When set, the prompt starts by asking the agent to load this skill.";
              };
              agent = lib.mkOption {
                type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9._-]*";
                default = "main";
                description = "OpenCode agent that runs the prompt.";
              };
              timeout = lib.mkOption {
                type = lib.types.strMatching "[0-9]+[smhd]?";
                default = "30m";
                description = "Maximum run time, passed to timeout(1) (for example 30m or 1h).";
              };
            };
          }
        );
        default = { };
        description = "Scheduled OpenCode jobs, each run as a launchd agent inside the nono sandbox. No jobs are declared by default.";
      };

      config = {
        assertions =
          lib.mapAttrsToList (name: _: {
            assertion = builtins.match "[a-zA-Z0-9][a-zA-Z0-9._-]*" name != null;
            message = "programs.opencodeJobs.${name}: job names must match [a-zA-Z0-9][a-zA-Z0-9._-]*.";
          }) cfg
          ++ lib.mapAttrsToList (name: job: {
            assertion =
              lib.hasPrefix "/" job.cwd
              && job.cwd != "/"
              && job.cwd != hmArgs.config.home.homeDirectory
              && job.cwd != hmArgs.config.xdg.stateHome
              && job.cwd != hmArgs.config.xdg.configHome;
            message = "programs.opencodeJobs.${name}.cwd: must be an absolute path that is not /, the home directory or the XDG state/config directories. nono grants the cwd read-write (--allow-cwd).";
          }) cfg;

        # launchd cannot create the log directory, so it must exist before the first run.
        xdg.stateFile = lib.mkIf (cfg != { }) {
          "opencode-jobs/.keep".text = "";
        };

        launchd.agents = lib.mkIf isDarwin (
          lib.mapAttrs' (
            name: job:
            lib.nameValuePair "opencode-job-${name}" {
              enable = true;
              config = {
                ProgramArguments = [
                  "${runner}/bin/opencode-job"
                  name
                  job.agent
                  job.timeout
                  "${promptFiles.${name}}"
                ];
                WorkingDirectory = job.cwd;
                StartCalendarInterval = job.schedule;
                StandardOutPath = "${logRoot}/${name}.log";
                StandardErrorPath = "${logRoot}/${name}.err.log";
              };
            }
          ) cfg
        );
      };
    };
}
