{ lib, ... }:
let
  inherit (lib)
    mod
    stringToCharacters
    concatMapStrings
    sublist
    ;
  inherit (lib.strings) charToInt;
  inherit (builtins)
    substring
    foldl'
    genList
    elemAt
    length
    concatStringsSep
    stringLength
    ;

  # Shared constants
  base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  base64Lookup = stringToCharacters base64Chars;

  # Create reverse lookup for decoding
  base64Map =
    let
      chars = stringToCharacters base64Chars;
      indices = genList (i: i) 64;
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
    sublist (n * size) size list;
  join = concatStringsSep "";

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
      substring (i - 32) 1 asciiTable
    else
      "?";

in
{
  toBase64 =
    text:
    let
      # Convert 3 bytes to 4 base64 characters
      convertTriplet =
        bytes:
        let
          combined = foldl' (acc: val: acc * 256 + val) 0 bytes;
          sextets = map (pow: mod (combined / pow) 64) [
            262144
            4096
            64
            1
          ]; # 64^3, 64^2, 64^1, 64^0
        in
        concatMapStrings (elemAt base64Lookup) sextets;

      # Handle the last incomplete slice with padding
      convertLastSlice =
        slice:
        let
          len = length slice;
        in
        if len == 0 then
          ""
        else if len == 1 then
          substring 0 2 (
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
          substring 0 3 (convertTriplet (slice ++ [ 0 ])) + "=";

      bytes = map charToInt (stringToCharacters text);
      len = length bytes;
      nFullSlices = len / 3;
      tripletAt = sliceN 3 bytes;
      fullTriplets = genList (i: convertTriplet (tripletAt i)) nFullSlices;
      lastTriplet = convertLastSlice (tripletAt nFullSlices);
    in
    join (fullTriplets ++ [ lastTriplet ]);

  fromBase64 =
    text:
    let
      # Convert base64 char to value (null for padding)
      charToVal = c: if c == "=" then null else base64Map.${c};

      # Convert 4 base64 chars to up to 3 bytes
      convertQuartet =
        chars:
        let
          vals = map charToVal chars;
          a = elemAt vals 0;
          b = elemAt vals 1;
          c = elemAt vals 2;
          d = elemAt vals 3;

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
            (mod (combined / 256) 256) # >> 8 & 0xFF
            (mod combined 256) # & 0xFF
          ];
        in
        if c == null then
          [
            elemAt
            bytes
            0
          ] # 2 padding = 1 byte
        else if d == null then
          sublist 0 2 bytes # 1 padding = 2 bytes
        else
          bytes; # no padding = 3 bytes

      # Split into 4-char groups and process
      len = stringLength text;
      numQuartets = len / 4;
      getQuartet =
        i:
        map (j: substring (i * 4 + j) 1 text) [
          0
          1
          2
          3
        ];
      allBytes = lib.lists.flatten (map convertQuartet (genList getQuartet numQuartets));
    in
    join (map intToChar allBytes);
}
