{
  config,
  lib,
  namespace,
  ...
}:
{
  home.file = {
    ".continue/config.json" = lib.mkIf config.${namespace}.suites.development.aiEnable {
      text = builtins.toJSON {
        name = "Codestral";
        version = "1.0.0";
        schema = "v1";
        context = [
          { provider = "code"; }
          { provider = "docs"; }
          { provider = "diff"; }
          { provider = "terminal"; }
          { provider = "problems"; }
          { provider = "folder"; }
          { provider = "codebase"; }
          { provider = "currentFile"; }
        ];
        docs = [

          {
            "name" = "Next.js";
            "startUrl" = "https://nextjs.org/docs";
          }
          {
            "name" = "React";
            "startUrl" = "https://react.dev/";
          }
          {
            "name" = "Zod";
            "startUrl" = "https://zod.dev/";
          }
          {
            "name" = "Prisma";
            "startUrl" = "https://www.prisma.io/docs/";
          }
          {
            "name" = "Tailwind CSS";
            "startUrl" = "https://tailwindcss.com/docs";
          }
          {
            "name" = "React Hook Form";
            "startUrl" = "https://react-hook-form.com/docs";
          }
          {
            "name" = "Shadcn UI";
            "startUrl" = "https://ui.shadcn.com/docs";
          }
        ];
        models = [
          {
            name = "Codestral";
            provider = "mistral";
            model = "codestral-latest";
            apiKey = "ctCciWYtB3PaMOscLihRm9VHAxCwLjI4";
            apiBase = "https://codestral.mistral.ai/v1";
            roles = [
              "chat"
              "edit"
              "apply"
              "autocomplete"
              "embed"
              "rerank"
            ];
          }
        ];
        rules = [
          {
            name = "Next.js Rules";
            globs = [
              "**/*.tsx"
              "**/*.ts"
            ];
            rule = "
          - Follow Next.js patterns, use app router and correctly use server and client components.
          - Use Tailwind v4 CSS for styling. Always sort classes following the Tailwind CSS class order.
          - Use React Hook Form for form handling.
          - Use Zod for validation.
          - Use React Context for state management.
          - Use Prisma for database access.
          - Follow AirBnB style guide for code formatting.
          - Use PascalCase when creating new React files. UserCard, not user-card.
          - Use named exports when creating new react components.
          - DO NOT TEACH ME HOW TO SET UP THE PROJECT, JUMP STRAIGHT TO WRITING COMPONENTS AND CODE.
        ";
          }
        ];
      };
    };
  };
}
