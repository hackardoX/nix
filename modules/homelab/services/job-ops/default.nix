{
  config,
  lib,
  ...
}:
let
  jobOpsUser = "job-ops";
  jobOpsGroup = "job-ops";
  jobOpsAppDir = "/var/lib/containers/job-ops";

  domain = config.flake.meta.reverse-proxy.domain;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.job-ops;

  jobOpsImage = "ghcr.io/dakheera47/job-ops:latest";
  jobOpsPort = 3001;
  jobOpsModel = "deepseek-v4-flash-free";
  jobOpsLlmProvider = "openai_compatible";
  jobOpsLlmBaseUrl = "https://opencode.ai/zen/v1/chat/completions";

  jobOpsPublicBaseUrl = "https://jobs.${domain}";
  jobOpsBasicAuthUser = "admin";

  # Secret file paths — configure before enabling
  jobOpsLlmApiKeyFile = "/run/secrets/job-ops/llm_api_key";
  jobOpsBasicAuthPasswordFile = "/run/secrets/job-ops/basic_auth_password";
  jobOpsRxresumeApiKeyFile = "/run/secrets/job-ops/rxresume_api_key";
  jobOpsRxresumeUrl = "https://rxresume.${domain}";
  jobOpsGmailOauthClientId = "776086063215-ue41fr70dcfbqs70pg5p26r9emndv7m1.apps.googleusercontent.com";
  jobOpsGmailOauthSecretFile = "/run/secrets/job-ops/gmail_oauth_secret";
  jobOpsAdzunaAppId = "47ca24d5";
  jobOpsAdzunaAppKeyFile = "/run/secrets/job-ops/adzuna_api_key";

  mkHomepageLabels = config.flake.lib.mkHomepageLabels;
in
{
  flake.modules.nixos.job-ops = {
    users.users.${jobOpsUser} = {
      isSystemUser = true;
      group = jobOpsGroup;
      extraGroups = [ "podman" ];
      createHome = true;
      home = "/var/lib/${jobOpsUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${jobOpsGroup} = { };

    home-manager.users.${jobOpsUser} = {
      imports = [
        config.flake.modules.homeManager.backup
        config.flake.modules.homeManager.job-ops
        config.flake.modules.homeManager.podman-secrets
      ];
    };

    services.caddy.virtualHosts."jobs.${domain}" = {
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.job-ops =
    hmArgs@{ osConfig, ... }:
    let
      env = {
        TZ = osConfig.time.timeZone;
        MODEL = jobOpsModel;
        LLM_PROVIDER = jobOpsLlmProvider;
        UKVISAJOBS_HEADLESS = "true";
        UKVISAJOBS_FILE_DIR = "/app/data";
      }
      // lib.optionalAttrs (jobOpsLlmBaseUrl != "") {
        OPENAI_BASE_URL = jobOpsLlmBaseUrl;
      }
      // lib.optionalAttrs (jobOpsPublicBaseUrl != "") {
        JOBOPS_PUBLIC_BASE_URL = jobOpsPublicBaseUrl;
      }
      // lib.optionalAttrs (jobOpsBasicAuthUser != "") {
        BASIC_AUTH_USER = jobOpsBasicAuthUser;
      }
      // lib.optionalAttrs (jobOpsRxresumeUrl != "") {
        RXRESUME_URL = jobOpsRxresumeUrl;
      }
      // lib.optionalAttrs (jobOpsGmailOauthClientId != "") {
        GMAIL_OAUTH_CLIENT_ID = jobOpsGmailOauthClientId;
      }
      // lib.optionalAttrs (jobOpsAdzunaAppId != "") {
        ADZUNA_APP_ID = jobOpsAdzunaAppId;
      };
    in
    {
      config = {
        programs.onepassword-secrets.secrets = {
          jobOpsBasicAuthPassword = {
            path = "/run/secrets/job-ops/basic_auth_password";
            reference = "op://Homelab/Job Ops/Authentication/password";
            owner = jobOpsUser;
            group = jobOpsGroup;
          };
          jobOpsLlmApiKey = {
            path = "/run/secrets/job-ops/llm_api_key";
            reference = "op://Homelab/Job Ops/AI Api Keys/opencode zen";
            owner = jobOpsUser;
            group = jobOpsGroup;
          };
          jobOpsRxresumeApiKey = {
            path = "/run/secrets/job-ops/rxresume_api_key";
            reference = "op://Homelab/Job Ops/RxResume/api key";
            owner = jobOpsUser;
            group = jobOpsGroup;
          };
          jobOpsGmailSecret = {
            path = "/run/secrets/job-ops/gmail_oauth_secret";
            reference = "op://Homelab/Job Ops/Gmail/oauth secret";
            owner = jobOpsUser;
            group = jobOpsGroup;
          };
          jobOpsAdzunaKey = {
            path = "/run/secrets/job-ops/adzuna_api_key";
            reference = "op://Homelab/Job Ops/Adzuna/api key";
            owner = jobOpsUser;
            group = jobOpsGroup;
          };
          backupJobOpsEncryptionKey = {
            path = "/run/secrets/job-ops/backup_encryption_key";
            reference = "op://Homelab/Backup/job-ops/password";
            owner = jobOpsUser;
            group = jobOpsGroup;
          };
        };

        services.backup.jobs.job-ops = {
          paths = [ "${jobOpsAppDir}/data" ];
          schedule = "daily";
          retention = "standard";
          providers = [ "koofr" ];
          encryptionKey = hmArgs.config.services.onepassword-secrets.secretPaths.backupJobOpsEncryptionKey;
        };

        services.podman.enable = true;
        services.podman.networks.job-ops.driver = "bridge";

        services.podman.containers.job-ops = {
          image = jobOpsImage;
          autoStart = true;
          userNS = "keep-id";
          network = [ "job-ops.network" ];
          networkAlias = [ "job-ops" ];
          ports = [ "${toString reverseProxyPort}:${toString jobOpsPort}" ];

          labels = mkHomepageLabels {
            category = "Productivity";
            name = "Job-Ops";
            description = "AI Job Application Assistant";
            icon = "mdi-briefcase-outline";
            href = "http://localhost:${toString reverseProxyPort}";
          };

          volumes = [ "${jobOpsAppDir}/data:/app/data" ];

          environment = env;

          secrets =
            { }
            // lib.optionalAttrs (jobOpsLlmApiKeyFile != "") {
              OPENAI_API_KEY = jobOpsLlmApiKeyFile;
            }
            // lib.optionalAttrs (jobOpsBasicAuthPasswordFile != "") {
              BASIC_AUTH_PASSWORD = jobOpsBasicAuthPasswordFile;
            }
            // lib.optionalAttrs (jobOpsRxresumeApiKeyFile != "") {
              RXRESUME_API_KEY = jobOpsRxresumeApiKeyFile;
            }
            // lib.optionalAttrs (jobOpsGmailOauthSecretFile != "") {
              GMAIL_OAUTH_CLIENT_SECRET = jobOpsGmailOauthSecretFile;
            }
            // lib.optionalAttrs (jobOpsAdzunaAppKeyFile != "") {
              ADZUNA_APP_KEY = jobOpsAdzunaAppKeyFile;
            };

          extraConfig.Container = {
            HealthCmd = "curl -f http://localhost:3001/health || exit 1";
            HealthInterval = "30s";
            HealthTimeout = "5s";
            HealthRetries = 3;
            NoNewPrivileges = true;
          };
        };
      };
    };
}
