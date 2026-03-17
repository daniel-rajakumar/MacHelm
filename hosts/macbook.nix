{ pkgs, ... }: {
  users.users.danielrajakumar = {
    name = "danielrajakumar";
    home = "/Users/danielrajakumar";
  };

  # System-wide packages
  environment.systemPackages = [
    pkgs.vim
    pkgs.git
  ];

  # Use Nix-Darwin to manage system defaults
  system.primaryUser = "danielrajakumar";
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  # Auto-upgrade nix package and the daemon service.
  nix.enable = false;
  nix.settings.experimental-features = "nix-command flakes";

  # Set compatibility version
  system.stateVersion = 4;
}
