# { config, ... }:
# {
#   flake.modules.homeManager.base.programs.git = {
#     settings = {
#       core = mkIf config.${namespace}.programs.graphical.editors.vscode.enable {
#         editor = "code --wait --new-window";
#       };
#     };
#   };
# }
