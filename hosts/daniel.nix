{ pkgs, ... }: {
  home.stateVersion = "23.11";

  # User-specific packages
  home.packages = [
    pkgs.htop
    pkgs.fzf
    pkgs.ripgrep
  ];

  # Dotfiles / Program configurations
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      rebuild = "/Users/danielrajakumar/code/MacHelm/scripts/nix/rebuild-dashboard.sh";
    };
  };

  programs.git = {
    enable = true;
    userName = "Daniel Rajakumar";
    userEmail = "daniel@example.com"; # Placeholder
  };
}
