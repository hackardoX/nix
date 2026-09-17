{
  flake.modules.nixvim.dev = {
    keymaps =
      map
        (key: {
          inherit key;
          action = "<Nop>";
          mode = [
            "n"
            "v"
            "x"
            "o"
            "i"
          ];
          options.desc = "Disabled arrow key";
        })
        [
          "<Up>"
          "<Down>"
          "<Left>"
          "<Right>"
        ];
  };
}
