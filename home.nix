{ config, pkgs, lib, inputs, ... }:

let
  pkgsInsecure = import inputs.nixpkgs { # Due to https://github.com/NixOS/nixpkgs/issues/526914
    inherit (pkgs.stdenv.hostPlatform) system;
    config.permittedInsecurePackages = [ "electron-39.8.10" ];
  };

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

  myZenPackage = zen-sandbox.config.env // { # Else fails to build
    override = _: myZenPackage;
    overrideAttrs = _: myZenPackage;
  };

  myYukigram = (inputs.yukigram.d.${pkgs.stdenv.hostPlatform.system}.override (prev: {
    nixpak.yukigram = prev.nixpak.yukigram.override {
      customNixpakConfig = { sloth, ... }: {
        bubblewrap = {
          bind.rw = [ # Bind additional folders for convenience
            (sloth.concat' sloth.homeDir "/Downloads")
            (sloth.mkdir (sloth.concat' sloth.appDataDir "/io.github.yukigram"))
            (sloth.concat' sloth.xdgDataHome "/io.github.yukigram")
          ];
          env = {
            QT_USE_PORTAL = "0";
            GTK_USE_PORTAL = "0";
          };
        };
      };
    };
  })).packages.nixpak;

  balsa-sandbox = mkNixPak { # Complex and fragile. Consider removal
    config = { sloth, ... }: {
      imports = [
        inputs.nixpak.nixpakModules.gui-base
        inputs.nixpak.nixpakModules.network
      ];
      app.package = pkgs.balsa;
      app.binPath = "bin/balsa";
      flatpak.appId = "org.gnome.Balsa";
      dbus.policies = {
        "org.desktop.Balsa" = "own";
        "org.gnome.Balsa" = "own";
        "org.freedesktop.secrets" = "talk";
      };
      bubblewrap = {
        bind.rw = [
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/balsa"))
          (sloth.mkdir (sloth.concat' sloth.appCacheDir "/balsa"))
          (sloth.mkdir (sloth.concat' sloth.xdgStateHome "/balsa"))
          (sloth.mkdir (sloth.concat' sloth.xdgDataHome "/org.desktop.Balsa"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/mail"))
          (sloth.concat' sloth.homeDir "/mailbox")
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.gnupg"))
        ];
        bind.ro = [
          "/etc/passwd"
          "/run/current-system/sw/share/themes"
          "/run/current-system/sw/share/hunspell"
          "/etc/cups"
          "/sys"
        ];
      };
    };
  };

in
{
  imports = [
    ./scripts.nix
    inputs.agenix.homeManagerModules.default
    inputs.zen-browser.homeModules.beta
  ];

  home = {
    username = "fkngoose";
    homeDirectory = "/home/fkngoose";
    sessionVariables.TZ = "Europe/Moscow";
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

  programs.zen-browser = {
    enable = true;
    package = myZenPackage;
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

  home.packages = [
    pkgs.htop
    pkgs.freerdp
    pkgs.nixpkgs-fmt
    pkgsInsecure.bitwarden-desktop
    inputs.nixpkgs-mattermost.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mattermost-desktop
    myYukigram
    balsa-sandbox.config.env
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
