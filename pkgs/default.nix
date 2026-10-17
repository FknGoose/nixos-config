{ pkgs }:
{
  record-border = pkgs.callPackage ./record-border { };
  sysmenu = pkgs.callPackage ./sysmenu { };
  tray-host = pkgs.callPackage ./tray-host { };
}

