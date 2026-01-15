{ lib, ... }:
{
  flake.modules.nixvim.dev.globals =
    [
      "mapleader"
      "maplocalleader"
    ]
    |> map (lib.flip lib.nameValuePair ",")
    |> lib.listToAttrs;
}
