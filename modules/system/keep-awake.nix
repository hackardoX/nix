{
  flake.modules.homeManager.aaccardo = {
    # Keep the machine from idle-sleeping:
    #   -i  prevent idle sleep
    #   -s  prevent system sleep, but only while on AC power, so battery
    #       behaviour is untouched; the display may still sleep.
    launchd.agents.keep-awake = {
      enable = true;
      config = {
        ProgramArguments = [
          "/usr/bin/caffeinate"
          "-i"
          "-s"
        ];
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}
