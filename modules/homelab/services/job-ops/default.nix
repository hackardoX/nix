{ lib, config, ... }:
{
  flake.meta.job-ops = {
    user = "job-ops";
    group = "job-ops";
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.job-ops.user} = {
      isSystemUser = true;
      group = config.flake.meta.job-ops.group;
      createHome = true;
      home = "/var/lib/${config.flake.meta.job-ops.user}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${config.flake.meta.job-ops.group} = { };
  };

  flake.homelab.services.job-ops.user = config.flake.meta.job-ops.user;

  flake.modules.homeManager.homelab =
    hmArgs:
    let
      cfg = hmArgs.config.services.job-ops;
      networkName = "job-ops";
    in
    {
      options.services.job-ops = {
        enable = lib.mkEnableOption "Job-Ops";

        image = lib.mkOption {
          type = lib.types.str;
          default = "ghcr.io/dakheera47/job-ops:latest";
          description = "Docker image to use for Job-Ops";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 3001;
          description = "Host port to expose Job-Ops on";
        };

        appDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/containers/job-ops";
          description = "Base directory for Job-Ops persistent data";
        };

        model = lib.mkOption {
          type = lib.types.str;
          default = "deepseek-v4-flash-free";
          description = "LLM model to use for job scoring and CV tailoring";
        };

        llmProvider = lib.mkOption {
          type = lib.types.str;
          default = "openai_compatible";
          description = "LLM provider (openrouter, openai, gemini, ollama, openai_compatible)";
        };

        llmBaseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "https://opencode.ai/zen/v1/chat/completions";
          description = "Base URL for OpenAI-compatible LLM endpoints";
        };

        llmApiKeyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to file containing the LLM API key";
        };

        publicBaseUrl = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Public base URL for tracer links. If null, auto-generated from domain.";
        };

        basicAuthUser = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Username for basic authentication. If null, auth is disabled.";
        };

        basicAuthPasswordFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to file containing the basic auth password";
        };

        rxresume = {
          apiKeyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to file containing the Reactive Resume v5 API key";
          };

          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "URL for self-hosted Reactive Resume instance";
          };
        };

        gmail = {
          oauthClientId = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Gmail OAuth client ID";
          };

          oauthClientSecretFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to file containing the Gmail OAuth client secret";
          };
        };

        adzuna = {
          appId = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Adzuna API app ID";
          };

          appKeyFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = "Path to file containing the Adzuna API app key";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        services.podman.networks.${networkName} = {
          driver = "bridge";
        };

        services.podman.containers.job-ops = {
          image = cfg.image;
          autoStart = true;
          userNS = "keep-id";
          network = [ "${networkName}.network" ];
          networkAlias = [ "job-ops" ];
          ports = [ "${toString cfg.port}:3001" ];

          monitoring.enable = true;

          labels = config.flake.lib.mkHomepageLabels {
            category = "Productivity";
            name = "Job-Ops";
            description = "AI Job Application Assistant";
            icon = "mdi-briefcase-outline";
            href = "http://localhost:${toString cfg.port}";
          };

          volumes = [ "${cfg.appDir}/data:/app/data" ];

          environment = {
            MODEL = cfg.model;
            LLM_PROVIDER = cfg.llmProvider;
            UKVISAJOBS_HEADLESS = "true";
          }
          // lib.optionalAttrs (cfg.llmBaseUrl != null) {
            OPENAI_BASE_URL = cfg.llmBaseUrl;
          }
          // lib.optionalAttrs (cfg.publicBaseUrl != null) {
            JOBOPS_PUBLIC_BASE_URL = cfg.publicBaseUrl;
          }
          // lib.optionalAttrs (cfg.basicAuthUser != null) {
            BASIC_AUTH_USER = cfg.basicAuthUser;
          }
          // lib.optionalAttrs (cfg.rxresume.url != null) {
            RXRESUME_URL = cfg.rxresume.url;
          }
          // lib.optionalAttrs (cfg.gmail.oauthClientId != null) {
            GMAIL_OAUTH_CLIENT_ID = cfg.gmail.oauthClientId;
          }
          // lib.optionalAttrs (cfg.adzuna.appId != null) {
            ADZUNA_APP_ID = cfg.adzuna.appId;
          };

          secrets =
            lib.optionalAttrs (cfg.llmApiKeyFile != null) {
              OPENAI_API_KEY = cfg.llmApiKeyFile;
            }
            // lib.optionalAttrs (cfg.basicAuthPasswordFile != null) {
              BASIC_AUTH_PASSWORD = cfg.basicAuthPasswordFile;
            }
            // lib.optionalAttrs (cfg.rxresume.apiKeyFile != null) {
              RXRESUME_API_KEY = cfg.rxresume.apiKeyFile;
            }
            // lib.optionalAttrs (cfg.gmail.oauthClientSecretFile != null) {
              GMAIL_OAUTH_CLIENT_SECRET = cfg.gmail.oauthClientSecretFile;
            }
            // lib.optionalAttrs (cfg.adzuna.appKeyFile != null) {
              ADZUNA_APP_KEY = cfg.adzuna.appKeyFile;
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
