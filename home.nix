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
      app.binPath = "bin/zen";
      flatpak.appId = "app.zen_browser.Zen";
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
    globals.mapleader = " ";
    opts = {
      mouse = "a";
      number = true;
      relativenumber = false;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      cursorline = true;
      clipboard = "unnamedplus";
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
        sources = [ "filesystem" ];
        window.width = 26;
        filesystem = {
          follow_current_file.enabled = true;
          hijack_netrw_behavior = "open_default";
          filtered_items.hide_dotfiles = false;
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
    autoCmd = [
      {
        event = [ "VimEnter" ];
        command = "Neotree show";
      }
    ];
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
      {
        mode = "n";
        key = "<leader>x";
        action = "<cmd>lua require('render-markdown').toggle()<CR>";
        options.desc = "Toggle Markdown checkbox";
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

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 24;
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
      autofit = "60%";
    };
  };

  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets = {
      subscription = {
        file = ./secrets/subscription.age;
        symlink = false; # Else fails to update subscription
        path = "${config.home.homeDirectory}/.config/Throne/config/groups/1.json";
        mode = "600";
      };
      rdp-proxy = {
        file = ./secrets/rdp-proxy.age;
        path = "${config.home.homeDirectory}/.config/wireproxy/wireproxy.conf";
        mode = "600";
      };
      rdp-pass = {
        file = ./secrets/rdp-pass.age;
        mode = "600";
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
  };

  services = {
    mako.enable = true;
    swayosd.enable = true;
    hyprpolkitagent.enable = true;
    blueman-applet.enable = true;
    network-manager-applet.enable = true;
    cliphist = {
      enable = true;
      allowImages = true;
    };
    wlsunset = {
      enable = true;
      latitude = "29.54";
      longitude = "-39.38";
      temperature.day = 4500;
      temperature.night = 4500;
    };

    swayidle = {
      enable = true;
      events = {
        before-sleep = "${pkgs.swaylock-effects}/bin/swaylock -f";
        lock = "${pkgs.swaylock-effects}/bin/swaylock -f";
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
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.packages = [
    pkgs.btop
    pkgs.freerdp
    pkgs.nixpkgs-fmt
    inputs.nixpkgs-mattermost.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mattermost-desktop
    yukigram-sandbox
    zen-sandbox.config.env
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
    pkgs.pinentry-gnome3
    pkgs.tauon
  ];

  xdg = {
    configFile = {
      "rofi-rbw.rc".text = ''
        selector=fuzzel
        clipboarder=wl-copy
        typer=wtype
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
      '';
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
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
