{ config, lib, pkgs, inputs, ... }:

let
  local = import ../../../pkgs { inherit pkgs; };
in
{
  home.packages = [
    local.sysmenu
    local.tray-host
  ];

  systemd.user.services.tray-host = {
    Unit = {
      Description = "Headless system tray host";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      # Some apps register their tray icon only once at startup; the watcher must exist first.
      Before = [
        "network-manager-applet.service"
        "blueman-applet.service"
      ];
    };
    Service = {
      ExecStart = "${lib.getExe local.tray-host} daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.desktopEntries.sysmenu = {
    name = "System Menu";
    genericName = "System controls";
    exec = "sysmenu";
    icon = "preferences-system";
    categories = [ "System" "Utility" ];
  };
}
