{ config, pkgs, ... }:

{
  imports = [
    ./scripts.nix
  ];

  home.username = "fkngoose";
  home.homeDirectory = "/home/fkngoose";

  programs.git = {
    enable = true;
    settings = {
      user.name = "FknGoose";
      user.email = "busygose@gmail.com";
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };


  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "JetBrainsMono Nerd Font Mono" ];
      serif = [ "Liberation Serif" ];
      sansSerif = [ "Inter" ];
    };
    hinting = "slight";
    subpixelRendering = "rgb";
  };


  home.packages = [
    pkgs.htop
    pkgs.freerdp
    pkgs.wireproxy
  ];

  home.enableNixpkgsReleaseCheck = false;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";
}
