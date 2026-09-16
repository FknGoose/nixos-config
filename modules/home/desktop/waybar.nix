{ config, lib, pkgs, inputs, ... }:
{
 programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = ''
      #custom-recorder {
        color: #${config.lib.stylix.colors.base08};
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 16;
        modules-left = [
          "niri/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "niri/language"
          "pulseaudio"
          "battery"
          "tray"
          "custom/recorder"
        ];
        "niri/workspaces" = {
          format = "{index}";
        };
        clock = {
          format = "{:%H:%M | %A, %d.%m.%y}";
          on-click = "gsimplecal";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        "niri/language" = {
          format = "{}";
          format-en = "US";
          format-ru = "RU";
        };
        "custom/recorder" = {
          exec-if = "pgrep -f gpu-screen-recorder";
          exec = "echo ' REC'";
          interval = 1;
          on-click = "screen-record-toggle";
        };
        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pavucontrol";
        };

        battery = {
          states = {
            warning = 20;
            critical = 10;
          };
          format = "{icon} {capacity}%";
          format-charging = "󱐥 {capacity}%";
          format-plugged = "󰚥 {capacity}%";
          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰁀"
            "󰁁"
            "󰁂"
            "󰁃"
            "󰁄"
          ];
        };

        tray = {
          icon-size = 16;
          spacing = 10;
        };
      };
    };
  };
}
