{ pkgs, ... }: {
  home.username = "danielrajakumar";
  home.homeDirectory = "/Users/danielrajakumar";
  home.stateVersion = "23.11";

  # User-specific packages
  home.packages = [
    pkgs.htop
    pkgs.fzf
    pkgs.ripgrep
    pkgs.starship
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
  
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git = {
    enable = true;
    settings.user.email = "daniel@example.com";
    settings.user.name = "Daniel Rajakumar";
  };
}
