{ config, lib, ... }: {
  options.flake.meta.git = lib.mkOption { 
    type = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Login/user name.";
        };

        email = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Email address of the user.";
        };
      };
    };
    default = { };
    description = "Info about git user";  
  };
  
  config.flake.meta.git = {
    email = config.flake.lib.fromBase64 "aGFja2FyZG9AZ21haWwuY29t";
    name = "hackardo";
  };
}
