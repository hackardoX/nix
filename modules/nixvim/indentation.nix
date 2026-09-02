{
  flake.modules.nixvim.dev = {
    keymaps =
      map
        (key: {
          inherit key;
          action = "${key}gv";
          mode = "v";
        })
        [
          "<"
          ">"
        ];
    opts = {
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
    };
    plugins.guess-indent.enable = true;
  };
}
