# Job-Ops Module (Podman)

AI-powered job application assistant running in Podman.

## Usage

```nix
services.job-ops = {
  enable = true;
  port = 3001;                              # default: 3001
  model = "deepseek-v4-flash-free";         # default
  llmProvider = "openai_compatible";        # default
  llmBaseUrl = "https://opencode.ai/zen/v1/chat/completions";
  llmApiKeyFile = /path/to/api/key;
  publicBaseUrl = "https://jobs.example.com";

  # optional: basic auth
  basicAuthUser = "admin";
  basicAuthPasswordFile = /path/to/password;

  # optional: Reactive Resume integration
  rxresume = {
    apiKeyFile = /path/to/rxresume/key;
    url = "https://resume.example.com";
  };

  # optional: Gmail OAuth
  gmail = {
    oauthClientId = "your-client-id";
    oauthClientSecretFile = /path/to/secret;
  };

  # optional: Adzuna job search
  adzuna = {
    appId = "your-app-id";
    appKeyFile = /path/to/key;
  };
};
```

Access the UI at `http://<host>:3001`.
