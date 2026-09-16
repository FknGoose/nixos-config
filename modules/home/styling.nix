{ config, lib, pkgs, inputs, ... }: {
imports = [
  inputs.stylix.homeModules.stylix 
];
fonts.fontconfig = {
    hinting = "slight";
    subpixelRendering = "rgb";
  };
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/brewer.yaml";
    image = ./wallpaper.png;
    polarity = "dark";
    fonts = {
      sizes = {
        applications = 10;
        terminal = 10;
        desktop = 10;
        popups = 10;
      };
      serif = {
        package = pkgs.liberation_ttf;
        name = "Liberation Serif";
      };
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
      };
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
    };
    cursor = {
      name = "phinger-cursors-dark";
      package = pkgs.phinger-cursors;
      size = 24;
    };
    icons = {
      enable = true;
      dark = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    targets.zen-browser.enable = false;
    targets.gtk.extraCss = ''
      window.csd, window.csd decoration {
        box-shadow: none;
        border-radius: 0;
      }
    '';
  };
}
