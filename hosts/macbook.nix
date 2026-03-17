{ pkgs, ... }: {
  # System-wide packages
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
  ];

  # Use Nix-Darwin to manage system defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
    NSGlobalDomain.AppleAccentColor = 1; # Green (corresponds to MacHelm vision)
  };

  # Auto-upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # Set compatibility version
  system.stateVersion = 4;
}
