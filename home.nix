{ config, pkgs, ... }:

{

  home.username = "fkngoose";
  home.homeDirectory = "/home/fkngoose";

  programs.git = {
    enable = true;
    userName = "fkngoose";
    userEmail = "busygose@gmail.com";
  };

  home.packages = [
    pkgs.htop
    pkgs.freerdp
    pkgs.wireproxy
  ];

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
