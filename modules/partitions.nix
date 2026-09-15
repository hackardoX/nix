{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.partitions ];

  partitionedAttrs = {
    darwinConfigurations = "laptops";
    nixosConfigurations = "homelab";
  };

  partitions = {
    laptops.extraInputsFlake = ../partitions/laptops;
    homelab.extraInputsFlake = ../partitions/homelab;
  };
}
