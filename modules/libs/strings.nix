{ lib, ... }:
let
  capitalize =
    s:
    let
      chars = lib.stringToCharacters s;
    in
    lib.concatStrings (lib.singleton (lib.toUpper (lib.head chars)) ++ lib.tail chars);
in
{
  flake.lib.capitalize = capitalize;

  flake.lib.toCamelCase =
    s:
    let
      parts = lib.splitString "-" s;
      capitalizedParts = map (part: if part == "" then "" else capitalize part) parts;
    in
    lib.concatStrings (lib.singleton (lib.head parts) ++ lib.tail capitalizedParts);
}
