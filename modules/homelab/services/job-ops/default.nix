{
  config,
  ...
}:
let
  jobOpsUid = 902;
  jobOpsGid = 902;
  jobOpsUser = "job-ops";
  jobOpsGroup = "job-ops";
  jobOpsAppDir = "/var/lib/podman/job-ops";
  jobOpsDataDir = "/var/lib/data/job-ops";

  hosts = config.flake.meta.reverse-proxy.hosts;
  reverseProxyPort = config.flake.meta.reverse-proxy.ports.job-ops;

  jobOpsImage = "ghcr.io/dakheera47/job-ops:v0.11.0";
  jobOpsPort = 3001;
  jobOpsModel = "deepseek-v4-flash";
  jobOpsLlmProvider = "openai_compatible";
  jobOpsLlmBaseUrl = "https://opencode.ai/zen/go/v1/chat/completions";

  jobOpsPublicBaseUrl = "https://${hosts.jobs}";
  jobOpsBasicAuthUser = "admin";

  jobOpsRxresumeUrl = "https://${hosts.rxresume}";
  jobOpsGmailOauthClientId = "776086063215-ue41fr70dcfbqs70pg5p26r9emndv7m1.apps.googleusercontent.com";
  jobOpsAdzunaAppId = "47ca24d5";

in
{
  flake.meta.homepage.services.job-ops = {
    category = "Productivity";
    name = "Job-Ops";
    description = "AI Job Application Assistant";
    icon = "mdi-briefcase-outline";
    href = "https://${hosts.jobs}";
    siteMonitor = "http://localhost:${toString reverseProxyPort}";
    container = "job-ops";
    dockerServer = "job-ops";
    dockerSocketProxyPort = config.flake.meta.reverse-proxy.ports.job-ops-docker-socket-proxy;
    pingPort = reverseProxyPort;
    widget = config.flake.lib.beszel.mkWidget {
      systemId = "Job Ops";
    };
  };

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
      "f ${jobOpsDataDir}/jobs.db 0640 ${jobOpsUser} ${jobOpsGroup} -"
      "f ${jobOpsDataDir}/jobs.db-shm 0640 ${jobOpsUser} ${jobOpsGroup} -"
      "f ${jobOpsDataDir}/jobs.db-wal 0640 ${jobOpsUser} ${jobOpsGroup} -"
    ];

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
        homelab-beszel-agent
        homelab-job-ops
      ];
      home.username = jobOpsUser;
      home.stateVersion = "26.05";
      services.rclone.remotes = [ "koofr" ];
      services.homelab-docker-socket-proxy = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.job-ops-docker-socket-proxy;
      };
      services.homelab-beszel-agent = {
        enable = true;
        port = config.flake.meta.reverse-proxy.ports.beszel-agent-job-ops;
      };
    };

    services.onepassword-secrets.secrets = {
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
        reference = "op://Homelab/Backup/Job Ops/password";
        owner = jobOpsUser;
        group = jobOpsGroup;
        mode = "0640";
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
    services.backup.jobs.job-ops = {
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
      userNS = "keep-id:uid=0,gid=0";
      network = [ "job-ops.network" ];
      networkAlias = [ "job-ops" ];
      ports = [ "${toString reverseProxyPort}:${toString jobOpsPort}" ];

      volumes = [
        "${jobOpsAppDir}:/app/data"
        "${jobOpsDataDir}/jobs.db:/app/data/jobs.db"
        "${jobOpsDataDir}/jobs.db-shm:/app/data/jobs.db-shm"
        "${jobOpsDataDir}/jobs.db-wal:/app/data/jobs.db-wal"
      ];

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
        OPENAI_API_KEY = osConfig.services.onepassword-secrets.secretPaths.jobOpsLlmApiKey;
        BASIC_AUTH_PASSWORD = osConfig.services.onepassword-secrets.secretPaths.jobOpsBasicAuthPassword;
        RXRESUME_API_KEY = osConfig.services.onepassword-secrets.secretPaths.jobOpsRxresumeApiKey;
        GMAIL_OAUTH_CLIENT_SECRET = osConfig.services.onepassword-secrets.secretPaths.jobOpsGmailSecret;
        ADZUNA_APP_KEY = osConfig.services.onepassword-secrets.secretPaths.jobOpsAdzunaKey;
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
