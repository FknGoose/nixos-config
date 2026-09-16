{ config, pkgs, lib, inputs, ... }:


let

  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  zen-sandbox = mkNixPak {
    config = { sloth, ... }: {
      imports = [
        inputs.nixpak.nixpakModules.gui-base
        inputs.nixpak.nixpakModules.network
      ];
      app.package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
      app.binPath = "bin/zen-beta";
      flatpak.appId = "app.zen_browser.Zen";
      dbus = {
        enable = true;
        policies = {
          "org.freedesktop.DBus" = "talk";
          "org.freedesktop.portal.*" = "talk";
          "org.mozilla.zen.*" = "own";
          "org.mozilla.firefox.*" = "own";
          "org.mpris.MediaPlayer2.*" = "own";
        };
      };
      bubblewrap = {
        bind.rw = [
          "/dev/shm"
          (sloth.concat' sloth.homeDir "/Downloads")
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/zen"))
        ];
        bind.ro = [
          "/etc/passwd"
          "/run/current-system/sw/share/themes"
          "/run/current-system/sw/share/hunspell"
          "/sys"
        ];
        bind.dev = [
          "/dev/video0"
          "/dev/video1"
        ];
        sockets = {
          pipewire = true;
        };
      };
    };
  };

  yukigram-sandbox = (inputs.yukigram.d.${pkgs.stdenv.hostPlatform.system}.override (prev: {
    nixpak.yukigram = prev.nixpak.yukigram.override {
      customNixpakConfig = { sloth, ... }: {
        bubblewrap = {
          bind.rw = [
            # Bind additional folders for convenience
            (sloth.concat' sloth.homeDir "/Downloads")
            (sloth.mkdir (sloth.concat' sloth.appDataDir "/io.github.yukigram"))
            (sloth.concat' sloth.xdgDataHome "/io.github.yukigram")
          ];
        };
      };
    };
  })).packages.nixpak;

  pwa-mattermost = pkgs.writeShellScriptBin "pwa-mattermost" ''
    exec ${zen-sandbox.config.env}/bin/zen-beta --new-window \
      "data:text/html,<script>window.open('https://mattermost.baumanracing.ru','_self','menubar=no,toolbar=no,location=no,status=no');</script>"
  '';
 
  pwa-aistudio = pkgs.writeShellScriptBin "pwa-aistudio" ''
    exec ${zen-sandbox.config.env}/bin/zen-beta --new-window \
      "data:text/html,<script>window.open('https://aistudio.google.com','_self','menubar=no,toolbar=no,location=no,status=no');</script>"
  '';

in
{
  imports = [
    ./scripts.nix
    inputs.agenix.homeManagerModules.default
    inputs.stylix.homeModules.stylix
    inputs.nixvim.homeModules.nixvim
  ];

  home = {
    username = "fkngoose";
    homeDirectory = "/home/fkngoose";
    sessionVariables = {
      TZ = "Europe/Moscow";
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";      
      TERMINAL = "kitty";   
    };
    language = {
      base = "en_US.UTF-8";
      time = "en_IE.UTF-8";
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "FknGoose";
      email = "busygose@gmail.com";
    };
  };

  programs.kitty = {
    enable = true;
    settings = {
      tab_bar_style = "hidden";
      hide_window_decorations = "yes";
      window_padding_width = 4;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
    };
    keybindings = {
      "ctrl+shift+enter" = "no_op";
      "ctrl+shift+t" = "no_op";
      "ctrl+shift+w" = "no_op";
      "ctrl+shift+n" = "no_op";
      "ctrl+shift+]" = "no_op";
      "ctrl+shift+[" = "no_op";
    };
  };

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.useGlobalPackages = true;
    opts = {
      mouse = "a";
      number = true;
      relativenumber = false;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      cursorline = true;
      clipboard = "unnamedplus";
      langmap = lib.concatStringsSep "," [
        "ёйцукенгшщзхъфывапролджэячсмитьбю;`qwertyuiop[]asdfghjkl\\;'zxcvbnm\\,."
        "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;~QWERTYUIOP{}ASDFGHJKL:\\\"ZXCVBNM<>"
        "№;#"
      ];
    };
    plugins.treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        kdl
        nix
        json
        python
      ];
    };
    plugins.neo-tree = {
      enable = true;
      settings = {
        sources = [ "filesystem" "git_status" ];
        close_if_last_window = true;
        sort_case_insensitive = true;
        window.width = 26;
        filesystem = {
          use_libuv_file_watcher = true;
          follow_current_file.enabled = true;
          hijack_netrw_behavior = "open_default";
          filtered_items = {
            hide_dotfiles = false;
            hide_gitignored = false;
          };
        };
      };
    };
    plugins.render-markdown = {
      enable = true;
      settings = {
        checkbox = {
          enabled = true;
          unchecked = { icon = "󰄱 "; };
          checked = { icon = "󰱒 "; };
        };
        heading = {
          enabled = true;
          sign = false;
          icons = [ "" "" "" "" "" "" ]; # Без иконок
          backgrounds = [
            "RenderMarkdownH1Bg"
            "RenderMarkdownH2Bg"
            "RenderMarkdownH3Bg"
            "RenderMarkdownH4Bg"
            "RenderMarkdownH5Bg"
            "RenderMarkdownH6Bg"
          ];
        };
      };
    };
    plugins.toggleterm = {
      enable = true;
      settings = {
        direction = "horizontal";
        size = 14;
        open_mapping = "[[<F4>]]";
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<F3>";
        action = "<cmd>Neotree toggle<CR>";
        options.desc = "Toggle file tree";
      }
      {
        mode = [ "n" "t" ];
        key = "<F4>";
        action = "<cmd>ToggleTerm<CR>";
        options.desc = "Toggle terminal";
      }
    ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
    };
  };

  programs.vesktop = {
    enable = true;
  };
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
            default = [ "󰕿" "󰖀" "󰕾" ];
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
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰁀" "󰁁" "󰁂" "󰁃" "󰁄" ];
        };

        tray = {
          icon-size = 16;
          spacing = 10;
        };
      };
    };
  };

  programs.fuzzel = {
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

  programs.rbw = {
    enable = true;
    settings = {
      email = "busygose@gmail.com";
      pinentry = pkgs.pinentry-gnome3;
    };
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      mgr = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };
    keymap = {
      mgr.prepend_keymap = [
        { on = [ "р" ]; run = "leave"; desc = "Left (h)"; }
        { on = [ "о" ]; run = "arrow 1"; desc = "Down (j)"; }
        { on = [ "л" ]; run = "arrow -1"; desc = "Up (k)"; }
        { on = [ "д" ]; run = "enter"; desc = "Right (l)"; }
      ];
    };
  };

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      clock = true;
      indicator = true;
      timestr = "%H:%M";
      datestr = "%A, %d.%m.%y";
    };
  };

  programs.mpv = {
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

  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets = { 
      rdp-pass = {
        file = ./secrets/rdp-pass.age;
        mode = "600";
      };
    };
  };

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

  home.packages = [
    pkgs.btop
    pkgs.freerdp
    pkgs.nixpkgs-fmt
    yukigram-sandbox
    zen-sandbox.config.env
    pwa-mattermost
    pwa-aistudio
    pkgs.onlyoffice-desktopeditors
    pkgs.pavucontrol
    pkgs.gsimplecal
    pkgs.swayimg
    pkgs.brightnessctl
    pkgs.grim
    pkgs.slurp
    pkgs.swappy
    pkgs.wl-clipboard
    pkgs.psmisc
    pkgs.rofi-rbw-wayland
    pkgs.wtype
    pkgs.tauon
    pkgs.xwayland-satellite
    pkgs.hyprsunset
  ];

  xdg = {
    desktopEntries = {
      "kvantummanager"    = { name = "Kvantum Manager"; noDisplay = true; };
      "qt5ct"             = { name = "Qt5 Settings"; noDisplay = true; };
      "qt6ct"             = { name = "Qt6 Settings"; noDisplay = true; };
      "cups"              = { name = "Manage Printing"; noDisplay = true; };
      "nixos-manual"      = { name = "NixOS Manual"; noDisplay = true; };
      "blueman-adapters"  = { name = "Bluetooth Adapters"; noDisplay = true; };
      "mattermost-pwa" = {
        name = "Mattermost";
        genericName = "Team Messenger";
        exec = "${pwa-mattermost}/bin/pwa-mattermost";
        icon = "mattermost";
        terminal = false;
        categories = [ "Network" "InstantMessaging" ];
      };

      "aistudio-pwa" = {
        name = "Google AI Studio";
        genericName = "AI Workspace";
        exec = "${pwa-aistudio}/bin/pwa-aistudio";
        icon = "google-gemini";
        terminal = false;
        categories = [ "Development" "Utility" ];
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
    mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "yazi.desktop";

        "application/pdf" = "zen-beta.desktop";
        "text/html" = "zen-beta.desktop";
        "application/xhtml+xml" = "zen-beta.desktop";
        "x-scheme-handler/http" = "zen-beta.desktop";
        "x-scheme-handler/https" = "zen-beta.desktop";
        "x-scheme-handler/about" = "zen-beta.desktop";
        "x-scheme-handler/unknown" = "zen-beta.desktop";

        "application/msword" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.ms-word.document.macroenabled.12" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.text-template" = "onlyoffice-desktopeditors.desktop";
        "application/rtf" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.ms-excel.sheet.macroenabled.12" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.spreadsheet-template" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.template" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.openxmlformats-officedocument.presentationml.slideshow" = "onlyoffice-desktopeditors.desktop";
        "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop";

        "image/png" = "swayimg.desktop";
        "image/jpeg" = "swayimg.desktop";
        "image/pjpeg" = "swayimg.desktop";
        "image/gif" = "swayimg.desktop";
        "image/webp" = "swayimg.desktop";
        "image/bmp" = "swayimg.desktop";
        "image/tiff" = "swayimg.desktop";
        "image/svg+xml" = "swayimg.desktop";
        "image/avif" = "swayimg.desktop";
        "image/heic" = "swayimg.desktop";
        "image/heif" = "swayimg.desktop";
        "image/x-icon" = "swayimg.desktop";
        "image/x-portable-anymap" = "swayimg.desktop";
        "image/x-portable-bitmap" = "swayimg.desktop";
        "image/x-portable-graymap" = "swayimg.desktop";
        "image/x-portable-pixmap" = "swayimg.desktop";

        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "video/x-flv" = "mpv.desktop";
        "video/x-ms-wmv" = "mpv.desktop";
        "video/mpeg" = "mpv.desktop";
        "video/ogg" = "mpv.desktop";
        "video/3gpp" = "mpv.desktop";
        "video/3gpp2" = "mpv.desktop";
        "video/mp2t" = "mpv.desktop";

        "audio/mpeg" = "mpv.desktop";
        "audio/mp3" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/wav" = "mpv.desktop";
        "audio/x-wav" = "mpv.desktop";
        "audio/vnd.wave" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/aac" = "mpv.desktop";
        "audio/opus" = "mpv.desktop";
        "audio/mp4" = "mpv.desktop";
        "audio/webm" = "mpv.desktop";
        "audio/x-matroska" = "mpv.desktop";

        "text/plain" = "nvim.desktop";
        "text/markdown" = "nvim.desktop";
        "text/csv" = "nvim.desktop";
        "text/tab-separated-values" = "nvim.desktop";
        "text/css" = "nvim.desktop";
        "text/javascript" = "nvim.desktop";
        "text/x-c" = "nvim.desktop";
        "text/x-python" = "nvim.desktop";
        "text/x-shellscript" = "nvim.desktop";
        "application/json" = "nvim.desktop";
        "application/yaml" = "nvim.desktop";
        "application/xml" = "nvim.desktop";
        "application/x-yaml" = "nvim.desktop";
        "application/x-sh" = "nvim.desktop";
        "application/x-shellscript" = "nvim.desktop";

        "x-scheme-handler/tg" = "yukigram.desktop";
      };
    };
  };

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
