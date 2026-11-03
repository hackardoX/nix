let
  mkGlanceKeymap =
    {
      key,
      action,
      desc,
    }:
    {
      key = "gp${key}";
      action = "<cmd>Glance ${action}<CR>";
      options = {
        inherit desc;
      };
    };
in
{
  flake.modules.nixvim.dev = {
    plugins.glance = {
      enable = true;
      lazyLoad.settings.cmd = [ "Glance" ];
      settings.border.enable = true;
    };
    keymaps = map mkGlanceKeymap [
      {
        key = "d";
        action = "definitions";
        desc = "Peek definition";
      }
      {
        key = "t";
        action = "type_definitions";
        desc = "Peek type definition";
      }
      {
        key = "i";
        action = "implementations";
        desc = "Peek implementations";
      }
      {
        key = "r";
        action = "references";
        desc = "Peek references";
      }
    ];
  };
}
