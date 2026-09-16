{ config, lib, pkgs, inputs, ... }:
{
  security.pam.services.swaylock = { };

  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
      noto-fonts
      corefonts
    ];
  };

  services = {
    printing.enable = true;


    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = lib.concatStringsSep " " [
            "${pkgs.tuigreet}/bin/tuigreet"
            "--time"
            "--time-format '%H:%M | %A, %d.%m.%y'"
            "--greeting 'Access restricted to authorised personnel only'"
            "--remember"
            "--remember-session"
            "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
            "--cmd niri-session"
          ];
          user = "greeter";
        };
      };
    };
  };
  programs = {
    gpu-screen-recorder.enable = true;
    niri.enable = true;
  };
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];
}
