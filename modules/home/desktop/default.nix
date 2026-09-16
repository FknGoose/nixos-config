{ config, lib, pkgs, inputs, ... }:

let

  accentRed = "#${config.lib.stylix.colors.base08}";

  record-border = pkgs.callPackage ../../../pkgs/record-border { };

  niri-layout-notify = pkgs.writeShellScriptBin "niri-layout-notify" ''
    export PATH="${pkgs.niri}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"

    niri msg --json event-stream | while read -r line; do
      case "$line" in
        *'"KeyboardLayoutSwitched"'*)
          idx=$(echo "$line" | jq -r '.KeyboardLayoutSwitched.idx // empty')
          if [ "$idx" = "0" ]; then
            notify-send -a layout-osd -h string:x-canonical-private-synchronous:layout-osd "EN"
          elif [ "$idx" = "1" ]; then
            notify-send -a layout-osd -h string:x-canonical-private-synchronous:layout-osd "RU"
          fi
          ;;
      esac
    done
  '';

  screenshot-area = pkgs.writeShellScriptBin "screenshot-area" ''
    export PATH="${pkgs.wayfreeze}/bin:${pkgs.grim}/bin:${pkgs.slurp}/bin:${pkgs.swappy}/bin:${pkgs.wl-clipboard}/bin:$PATH"

    wayfreeze &
    FREEZE_PID=$!
    trap 'kill $FREEZE_PID 2>/dev/null || true' EXIT INT TERM
    sleep 0.05

    TARGET="$1"
    GEOM=$(slurp)

    if [ -z "$GEOM" ]; then
      exit 0
    fi

    TMP_SHOT=$(mktemp --suffix=.png)
    grim -g "$GEOM" "$TMP_SHOT"
    kill $FREEZE_PID 2>/dev/null || true

    case "$TARGET" in
      "swappy")
        swappy -f "$TMP_SHOT" -o - | wl-copy
        ;;
      "clipboard")
        wl-copy < "$TMP_SHOT"
        ;;
      "edit-only")
        swappy -f "$TMP_SHOT"
        ;;
    esac

    rm -f "$TMP_SHOT"
  '';

  screen-record-toggle = pkgs.writeShellScriptBin "screen-record-toggle" ''
    export PATH="${pkgs.slurp}/bin:${pkgs.procps}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:$PATH"

    stop_recording() {
      pkill -f -SIGINT gpu-screen-recorder 2>/dev/null || true
      pkill -x record-border 2>/dev/null || true
    }

    if pgrep -f gpu-screen-recorder >/dev/null; then
      stop_recording
      notify-send -a record-notify -t 3000 "GPU Screen Recorder" "Recording saved" 2>/dev/null || true
      exit 0
    fi

    GEOM_RAW=$(slurp -f "%x %y %w %h" -d -c "${accentRed}" -b "#00000022")
    if [ -z "$GEOM_RAW" ]; then
      exit 0
    fi

    read -r X Y W H <<< "$GEOM_RAW"
    GEOM="''${W}x''${H}+''${X}+''${Y}"
    OUT_DIR="$HOME/Videos/Screencasts"
    mkdir -p "$OUT_DIR"
    OUT_FILE="$OUT_DIR/video-$(date +%Y-%m-%d_%H-%M-%S).mp4"

    ${record-border}/bin/record-border "$X" "$Y" "$W" "$H" "${accentRed}" &
    notify-send -a record-notify -t 2500 "GPU Screen Recorder" "Recording of ''${GEOM} started" 2>/dev/null || true

    ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder \
      -w "$GEOM" \
      -f 60 \
      -a default_output \
      -o "$OUT_FILE"

    stop_recording
  '';

in
  {

  imports = [
    ./waybar.nix
  ];

  home.packages = [
    screenshot-area
    screen-record-toggle
    niri-layout-notify
    pkgs.pavucontrol
    pkgs.gsimplecal
    pkgs.swayimg
    pkgs.grim
    pkgs.slurp
    pkgs.swappy
    pkgs.wl-clipboard
    pkgs.rofi-rbw-wayland
    pkgs.wtype
    pkgs.xwayland-satellite
    pkgs.hyprsunset
  ];

  programs = {
    fuzzel = {
      enable = true;
      settings = {
        main = {
          layer = "overlay";
          fields = "filename,name,generic,keywords";
          terminal = "${pkgs.kitty}/bin/kitty -e";
        };
        border = {
          width = 2;
          radius = 4;
        };
      };
    };



    swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        clock = true;
        indicator = true;
        timestr = "%H:%M";
        datestr = "%A, %d.%m.%y";
      };
    };

    mpv = {
      enable = true;
      config = {
        hwdec = "auto-safe";
        vo = "gpu-next";
        gpu-context = "wayland";
        profile = "fast";
        keep-open = "yes";
        force-window = "immediate";
        autofit = "50%x50%";
      };
    };
  };

  services = {
    batsignal = {
      enable = true;
      extraArgs = [
        "-w"
        "20"
        "-c"
        "10"
        "-d"
        "5"
      ];
    };
    mako = {
      enable = true;
      settings = {
        border-radius = 4;
        default-timeout = 5000;
        margin = "10";
        padding = "8";
        border-size = 2;
      };
      extraConfig = ''
        [app-name=layout-osd]
        anchor=center
        default-timeout=400
        width=140
        height=90
        text-alignment=center
        border-radius=4
        border-size=2
        border-color=#${config.lib.stylix.colors.base0D}
        background-color=#${config.lib.stylix.colors.base00}
        text-color=#${config.lib.stylix.colors.base05}
        font=${config.stylix.fonts.monospace.name} 32
      '';
    };
    swayosd.enable = true;
    hyprpolkitagent.enable = true;
    blueman-applet.enable = true;
    network-manager-applet.enable = true;
    cliphist = {
      enable = true;
      allowImages = true;
    };
    swayidle = {
      enable = true;
      events = {
        before-sleep = "${pkgs.swaylock-effects}/bin/swaylock -f && ${pkgs.rbw}/bin/rbw lock";
        lock = "${pkgs.swaylock-effects}/bin/swaylock -f && ${pkgs.rbw}/bin/rbw lock";
      };
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.swaylock-effects}/bin/swaylock -f";
        }
        {
          timeout = 600;
          command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        }
        {
          timeout = 900;
          command = "systemctl suspend";
        }
      ];
    };
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "Swaybg wallpaper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill";
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
  xdg = {
    desktopEntries = {
      "kvantummanager" = {
        name = "Kvantum Manager";
        noDisplay = true;
      };
      "qt5ct" = {
        name = "Qt5 Settings";
        noDisplay = true;
      };
      "qt6ct" = {
        name = "Qt6 Settings";
        noDisplay = true;
      };
      "cups" = {
        name = "Manage Printing";
        noDisplay = true;
      };
      "nixos-manual" = {
        name = "NixOS Manual";
        noDisplay = true;
      };
      "blueman-adapters" = {
        name = "Bluetooth Adapters";
        noDisplay = true;
      };
    };
    configFile = {
      "xdg-desktop-portal/niri-portals.conf".text = ''
        [preferred]
        default=gnome;gtk
        org.freedesktop.impl.portal.FileChooser=termfilechooser
      '';
      "xdg-desktop-portal-termfilechooser/config".text = ''
        [filechooser]
        cmd=yazi-chooser
        default_dir=$HOME/Downloads
        open_mode=suggested
        save_mode=last
      '';
      "rofi-rbw.rc".text = ''
        selector=fuzzel
        clipboarder=wl-copy
        typer=wtype
        target=menu
      '';
      "swappy/config".text = ''
        [Default]
        save_dir=${config.home.homeDirectory}/Pictures/Screenshots
        save_filename_format=screenshot-%Y-%m-%d_%H-%M-%S.png
        save_command=
      '';
      "niri/config.kdl".source = ./config.kdl;
      "niri/binds.kdl".source = ./binds.kdl;

      "niri/colors.kdl".text = ''
        layout {
            focus-ring {
                on
                width 2
                active-color "#${config.lib.stylix.colors.base0D}"
                inactive-color "#${config.lib.stylix.colors.base02}"
            }
            border {
                off
            }
            tab-indicator {
                active-color "#${config.lib.stylix.colors.base0B}"
                inactive-color "#${config.lib.stylix.colors.base03}"
                width 4
            }
        }
        overview {
            backdrop-color "#${config.lib.stylix.colors.base00}"
        }
      '';
    };

  };
}
