{ config, ... }:
{
  flake.meta.users.root = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    description = "System administrator";
    name = "root";
    uid = 0;
  };

  flake.modules.nixos.homelab = {
    users.users.${config.flake.meta.users.root.name} = {
      inherit (config.flake.meta.users.root) description uid;
      isNormalUser = false;
      hashedPassword = "$6$bmMY3k2VAqr5sg2I$C14qsnZx7xxTs.XxTyL7/hYKsq4cjEfzibmEjqQQMc/2.fmt.N6qqhtGa1ckqpdqdnzurboSeZ/F/F4DuzySM/";
    };
  };
}
