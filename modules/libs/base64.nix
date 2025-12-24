{ lib, ... }:
let
  # Shared constants
  base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  base64Lookup = lib.stringToCharacters base64Chars;

  # Create reverse lookup for decoding
  base64Map =
    let
      chars = lib.stringToCharacters base64Chars;
      indices = builtins.genList (i: i) 64;
    in
    lib.listToAttrs (
      lib.zipListsWith (c: i: {
        name = c;
        value = i;
      }) chars indices
    );

  # Shared utilities
  sliceN =
    size: list: n:
    lib.sublist (n * size) size list;
  join = builtins.concatStringsSep "";

  # ASCII character conversion
  asciiTable = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
  intToChar =
    i:
    if i == 0 then
      "\x00"
    else if i == 9 then
      "\t"
    else if i == 10 then
      "\n"
    else if i == 13 then
      "\r"
    else if i < 32 then
      "?"
    else if i < 127 then
      builtins.substring (i - 32) 1 asciiTable
    else
      "?";

in
{
  flake.lib.toBase64 =
    text:
    let
      # Convert 3 bytes to 4 base64 characters
      convertTriplet =
        bytes:
        let
          combined = builtins.foldl' (acc: val: acc * 256 + val) 0 bytes;
          sextets = map (pow: lib.mod (combined / pow) 64) [
            262144
            4096
            64
            1
          ]; # 64^3, 64^2, 64^1, 64^0
        in
        lib.concatMapStrings (builtins.elemAt base64Lookup) sextets;

      # Handle the last incomplete slice with padding
      convertLastSlice =
        slice:
        let
          len = builtins.length slice;
        in
        if len == 0 then
          ""
        else if len == 1 then
          builtins.substring 0 2 (
            convertTriplet (
              slice
              ++ [
                0
                0
              ]
            )
          )
          + "=="
        # len == 2
        else
          builtins.substring 0 3 (convertTriplet (slice ++ [ 0 ])) + "=";

      bytes = map lib.stringscharToInt (lib.stringToCharacters text);
      len = builtins.length bytes;
      nFullSlices = len / 3;
      tripletAt = sliceN 3 bytes;
      fullTriplets = builtins.genList (i: convertTriplet (tripletAt i)) nFullSlices;
      lastTriplet = convertLastSlice (tripletAt nFullSlices);
    in
    join (fullTriplets ++ [ lastTriplet ]);

  flake.lib.fromBase64 =
    text:
    let
      # Convert base64 char to value (null for padding)
      charToVal = c: if c == "=" then null else base64Map.${c};

      # Convert 4 base64 chars to up to 3 bytes
      convertQuartet =
        chars:
        let
          vals = map charToVal chars;
          a = builtins.elemAt vals 0;
          b = builtins.elemAt vals 1;
          c = builtins.elemAt vals 2;
          d = builtins.elemAt vals 3;

          # Combine 6-bit values into 24-bit number
          combined =
            (if a != null then a * 262144 else 0)
            # << 18
            + (if b != null then b * 4096 else 0)
            # << 12
            + (if c != null then c * 64 else 0)
            # << 6
            + (if d != null then d else 0); # << 0

          # Extract bytes
          bytes = [
            (combined / 65536) # >> 16
            (lib.mod (combined / 256) 256) # >> 8 & 0xFF
            (lib.mod combined 256) # & 0xFF
          ];
        in
        if c == null then
          [
            builtins.elemAt
            bytes
            0
          ] # 2 padding = 1 byte
        else if d == null then
          lib.sublist 0 2 bytes # 1 padding = 2 bytes
        else
          bytes; # no padding = 3 bytes

      # Split into 4-char groups and process
      len = builtins.stringLength text;
      numQuartets = len / 4;
      getQuartet =
        i:
        map (j: builtins.substring (i * 4 + j) 1 text) [
          0
          1
          2
          3
        ];
      allBytes = lib.lists.flatten (map convertQuartet (builtins.genList getQuartet numQuartets));
    in
    join (map intToChar allBytes);
}
