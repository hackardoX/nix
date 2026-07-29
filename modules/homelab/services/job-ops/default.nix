{
  config,
  ...
}:
let
  jobOpsUid = 902;
  jobOpsGid = 902;
  jobOpsUser = "job-ops";
  jobOpsGroup = "job-ops";
  jobOpsAppDir = "/var/lib/containers/job-ops";
  jobOpsDataDir = "/var/lib/data/job-ops";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.job-ops;

  jobOpsImage = "ghcr.io/dakheera47/job-ops:v0.11.0";
  jobOpsPort = 3001;
  jobOpsModel = "deepseek-v4-flash-free";
  jobOpsLlmProvider = "openai_compatible";
  jobOpsLlmBaseUrl = "https://opencode.ai/zen/v1/chat/completions";

  jobOpsPublicBaseUrl = "https://${hosts.jobs}";
  jobOpsBasicAuthUser = "admin";

  jobOpsLlmApiKeyFile = "/run/secrets/job-ops/llm_api_key";
  jobOpsBasicAuthPasswordFile = "/run/secrets/job-ops/basic_auth_password";
  jobOpsRxresumeApiKeyFile = "/run/secrets/job-ops/rxresume_api_key";
  jobOpsRxresumeUrl = "https://${hosts.rxresume}";
  jobOpsGmailOauthClientId = "776086063215-ue41fr70dcfbqs70pg5p26r9emndv7m1.apps.googleusercontent.com";
  jobOpsGmailOauthSecretFile = "/run/secrets/job-ops/gmail_oauth_secret";
  jobOpsAdzunaAppId = "47ca24d5";
  jobOpsAdzunaAppKeyFile = "/run/secrets/job-ops/adzuna_api_key";

  mkHomepageLabels = config.flake.lib.mkHomepageLabels;
in
{
  flake.modules.nixos.homelab-job-ops = {
    users.users.${jobOpsUser} = {
      uid = jobOpsUid;
      isSystemUser = true;
      group = jobOpsGroup;
      extraGroups = [
        "homelab-users"
        "rclone"
      ];
      createHome = true;
      home = "/var/lib/${jobOpsUser}";
      autoSubUidGidRange = true;
      linger = true;
    };

    users.groups.${jobOpsGroup} = {
      gid = jobOpsGid;
    };

    systemd.tmpfiles.rules = [
      "d ${jobOpsAppDir} 0750 ${jobOpsUser} ${jobOpsGroup} -"
      "d ${jobOpsDataDir} 0750 ${jobOpsUser} ${jobOpsGroup} -"
      "d ${jobOpsAppDir}/containers 0750 ${jobOpsUser} ${jobOpsGroup} -"
    ];

    systemd.services."home-manager-${jobOpsUser}" = {
      after = [ "user@${toString jobOpsUid}.service" ];
      wants = [ "user@${toString jobOpsUid}.service" ];
    };

    boot.initrd.impermanence.persist.directories = [
      {
        directory = jobOpsAppDir;
        user = jobOpsUser;
        group = jobOpsGroup;
        mode = "0750";
      }
    ];

    home-manager.users.${jobOpsUser} = {
      imports = with config.flake.modules.homeManager; [
        base
        backup
        podman-secrets
        homelab-docker-socket-proxy
        homelab-job-ops
      ];
      home.username = jobOpsUser;
      home.stateVersion = "26.05";
      services.rclone.remotes = [ "koofr" ];
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.job-ops-docker-socket-proxy;
      };

    };

    services.onepassword-secrets.secrets = {
      jobOpsBasicAuthPassword = {
        path = jobOpsBasicAuthPasswordFile;
        reference = "op://Homelab/Job Ops/Authentication/password";
        owner = jobOpsUser;
        group = jobOpsGroup;
      };
      jobOpsLlmApiKey = {
        path = jobOpsLlmApiKeyFile;
        reference = "op://Homelab/Job Ops/AI Api Keys/opencode zen";
        owner = jobOpsUser;
        group = jobOpsGroup;
      };
      jobOpsRxresumeApiKey = {
        path = jobOpsRxresumeApiKeyFile;
        reference = "op://Homelab/Job Ops/RxResume/api key";
        owner = jobOpsUser;
        group = jobOpsGroup;
      };
      jobOpsGmailSecret = {
        path = jobOpsGmailOauthSecretFile;
        reference = "op://Homelab/Job Ops/Gmail/oauth secret";
        owner = jobOpsUser;
        group = jobOpsGroup;
      };
      jobOpsAdzunaKey = {
        path = jobOpsAdzunaAppKeyFile;
        reference = "op://Homelab/Job Ops/Adzuna/api key";
        owner = jobOpsUser;
        group = jobOpsGroup;
      };
      backupJobOpsEncryptionKey = {
        path = "/run/secrets/job-ops/backup_encryption_key";
        reference = "op://Homelab/Backup/Job Ops/password";
        owner = jobOpsUser;
        group = jobOpsGroup;
      };
    };

    services.caddy.virtualHosts."${hosts.jobs}" = {
      extraConfig = ''
        import auth_protected
        import reverse_proxy_common
        reverse_proxy localhost:${toString reverseProxyPort}
      '';
    };
  };

  flake.modules.homeManager.homelab-job-ops = { osConfig, ... }: {
    xdg.configFile."containers/storage.conf".text = ''
      [storage]
      graphroot = "${jobOpsAppDir}/containers"
    '';

    services.backup.jobs.job-ops = {
      paths = [ jobOpsDataDir ];
      schedule = "daily";
      retention = "standard";
      providers = [ "koofr" ];
      encryptionKey = osConfig.services.onepassword-secrets.secretPaths.backupJobOpsEncryptionKey;
    };

    services.podman.enable = true;
    services.podman.networks.job-ops.driver = "bridge";

    services.podman.containers.job-ops = {
      image = jobOpsImage;
      autoStart = true;
      userNS = "keep-id";
      user = "%U";
      group = "%G";
      network = [ "job-ops.network" ];
      networkAlias = [ "job-ops" ];
      ports = [ "${toString reverseProxyPort}:${toString jobOpsPort}" ];

      labels = mkHomepageLabels {
        category = "Productivity";
        name = "Job-Ops";
        description = "AI Job Application Assistant";
        icon = "mdi-briefcase-outline";
        href = "https://${hosts.jobs}";
        siteMonitor = "http://localhost:${toString reverseProxyPort}";
      };

      volumes = [ "${jobOpsDataDir}:/app/data" ];

      environment = {
        TZ = osConfig.time.timeZone;
        MODEL = jobOpsModel;
        LLM_PROVIDER = jobOpsLlmProvider;
        UKVISAJOBS_HEADLESS = "true";
        OPENAI_BASE_URL = jobOpsLlmBaseUrl;
        JOBOPS_PUBLIC_BASE_URL = jobOpsPublicBaseUrl;
        RXRESUME_URL = jobOpsRxresumeUrl;
        GMAIL_OAUTH_CLIENT_ID = jobOpsGmailOauthClientId;
        ADZUNA_APP_ID = jobOpsAdzunaAppId;
        BASIC_AUTH_USER = jobOpsBasicAuthUser;
      };

      secrets = {
        OPENAI_API_KEY = jobOpsLlmApiKeyFile;
        BASIC_AUTH_PASSWORD = jobOpsBasicAuthPasswordFile;
        RXRESUME_API_KEY = jobOpsRxresumeApiKeyFile;
        GMAIL_OAUTH_CLIENT_SECRET = jobOpsGmailOauthSecretFile;
        ADZUNA_APP_KEY = jobOpsAdzunaAppKeyFile;
      };

      extraConfig = {
        Container = {
          LogDriver = "journald";
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
