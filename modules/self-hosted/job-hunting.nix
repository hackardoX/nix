{ config, ... }:
let
  domain = config.flake.meta.reverse-proxy.domain;
  port = config.flake.meta.reverse-proxy.ports.job-ops;
  gmailOauthClientId = "776086063215-ue41fr70dcfbqs70pg5p26r9emndv7m1.apps.googleusercontent.com";
  adzunaAppId = "47ca24d5";
  appSubDomain = "jobs";
in
{
  flake.modules.nixos.homelab = {
    services.caddy.virtualHosts."${appSubDomain}.${domain}" = {
      useACMEHost = domain;
      extraConfig = ''
        import reverse_proxy_common
        reverse_proxy localhost:${toString port}
      '';
    };
  };

  flake.modules.homeManager."${config.flake.meta.job-ops.user}@homelab" = hmArgs: {
    services.job-ops = {
      enable = true;
      port = port;
      publicBaseUrl = "https://${appSubDomain}.${domain}";
      basicAuthUser = "admin";
      basicAuthPasswordFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.jobOpsBasicAuthPasswordPath;
      llmApiKeyFile = hmArgs.config.services.onepassword-secrets.secretPaths.jobOpsLlmApiKeyPath;
      rxresume.apiKeyFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.jobOpsRxresumeApiKeyPath;
      rxresume.url = "https://rxresume.${domain}";
      gmail.oauthClientId = gmailOauthClientId;
      gmail.oauthClientSecretFile =
        hmArgs.config.services.onepassword-secrets.secretPaths.jobOpsGmailSecretPath;
      adzuna.appId = adzunaAppId;
      adzuna.appKeyFile = hmArgs.config.services.onepassword-secrets.secretPaths.jobOpsAdzunaKeyPath;
    };

    programs.onepassword-secrets.secrets = {
      jobOpsBasicAuthPasswordPath = {
        path = "/run/secrets/job-ops/basic_auth_password";
        reference = "op://Homelab/Job Ops/Auth/password";
        owner = config.flake.meta.job-ops.user;
        group = config.flake.meta.job-ops.group;
      };

      jobOpsLlmApiKeyPath = {
        path = "/run/secrets/job-ops/llm_api_key";
        reference = "op://Homelab/Job Ops/AI Api Keys/opencode zen";
        owner = config.flake.meta.job-ops.user;
        group = config.flake.meta.job-ops.group;
      };

      jobOpsRxresumeApiKeyPath = {
        path = "/run/secrets/job-ops/rxresume_api_key";
        reference = "op://Homelab/Job Ops/RxResume/api key";
        owner = config.flake.meta.job-ops.user;
        group = config.flake.meta.job-ops.group;
      };

      jobOpsGmailSecretPath = {
        path = "/run/secrets/job-ops/gmail_oauth_secret";
        reference = "op://Homelab/Job Ops/Gmail/oauth secret";
        owner = config.flake.meta.job-ops.user;
        group = config.flake.meta.job-ops.group;
      };

      jobOpsAdzunaKeyPath = {
        path = "/run/secrets/job-ops/adzuna_api_key";
        reference = "op://Homelab/Job Ops/Adzuna/api key";
        owner = config.flake.meta.job-ops.user;
        group = config.flake.meta.job-ops.group;
      };
    };
  };
}
