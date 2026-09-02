{
  self,
  ...
}:
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    let
      diagramContent =
        showSecrets:
        import ../scripts/generate-diagram.nix {
          inherit lib showSecrets;
          modulesDir = "${self}/modules";
        };

      basePackages = {
        diagram = pkgs.writeText "module-diagram.md" "```mermaid\n${diagramContent false}\n```\n";

        diagram-with-secrets = pkgs.writeText "module-diagram.md" "```mermaid\n${diagramContent true}\n```\n";
      };

      linuxPackages = lib.optionalAttrs pkgs.stdenv.isLinux {
        diagram-svg =
          pkgs.runCommand "module-diagram.svg"
            {
              nativeBuildInputs = [ pkgs.mermaid-cli ];
            }
            ''
              cat > diagram.mmd << 'MERMAID_EOF'
              ${diagramContent false}
              MERMAID_EOF
              mmdc -i diagram.mmd -o $out -b transparent
            '';

        diagram-with-secrets-svg =
          pkgs.runCommand "module-diagram.svg"
            {
              nativeBuildInputs = [ pkgs.mermaid-cli ];
            }
            ''
              cat > diagram.mmd << 'MERMAID_EOF'
              ${diagramContent true}
              MERMAID_EOF
              mmdc -i diagram.mmd -o $out -b transparent
            '';
      };
    in
    {
      packages = basePackages // linuxPackages;
    };
}
