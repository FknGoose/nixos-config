{ config, pkgs, lib, inputs, ... }:
let
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  zen-sandbox = mkNixPak {
    config = { sloth, ... }: {
      app.package = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.beta;
      app.binPath = "bin/zen";
      bubblewrap = {
        network = true;
        bind.rw = [
          (sloth.concat' sloth.homeDir "/Downloads")
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/zen"))
        ];
        bind.dev = [
          "/dev/dri"
          "/dev/video0"
          "/dev/video1"
        ];
      };
      flatpak.appId = "app.zen_browser.Zen";
      dbus.enable = true;
      dbus.policies = {
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.Notifications" = "talk";
      };
    };
  };

  myZenPackage = zen-sandbox.config.env // {
    override = _: myZenPackage;
    overrideAttrs = _: myZenPackage;
  };

  geary-sandbox = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.geary;
      app.binPath = "bin/geary";
      flatpak.appId = "org.gnome.Geary";
      dbus.enable = true;
      dbus.policies = {
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.Notifications" = "talk";
        "org.freedesktop.secrets" = "talk";
        "org.freedesktop.portal.Desktop" = "talk";
        "org.freedesktop.portal.Documents" = "talk";
        "org.gnome.Geary" = "own";
      };
      bubblewrap = {
        network = true;
        bind.rw = [
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/geary"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.local/share/geary"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.cache/geary"))
          (sloth.concat [ (sloth.env "XDG_RUNTIME_DIR") "/" (sloth.env "WAYLAND_DISPLAY") ])
        ];
        bind.dev = [ "/dev/dri" ];
        bind.ro = [
          "/etc/fonts"
          "/tmp/.X11-unix"
          (sloth.concat' sloth.homeDir "/.Xauthority")
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

  home.username = "fkngoose";
  home.homeDirectory = "/home/fkngoose";

  programs.git = {
    enable = true;
    settings = {
      user.name = "FknGoose";
      user.email = "busygose@gmail.com";
    };
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
        path = "${config.home.homeDirectory}/.config/Throne/config/groups/1.json";
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

  programs.zen-browser = {
    enable = true;
    package = myZenPackage;
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DisableAppUpdate = true;
    };
  };

  xdg.desktopEntries = {
    "org.gnome.Geary" = {
      name = "Geary";
      exec = "geary %U";
      icon = "org.gnome.Geary";
      comment = "Send and receive email";
      categories = [ "Network" "Email" ];
      mimeType = [ "x-scheme-handler/mailto" ];
      settings = {
        StartupWMClass = "org.gnome.Geary";
      };
    };
  };

  home.packages = [
    pkgs.htop
    pkgs.freerdp
    pkgs.wireproxy
    pkgs.nixpkgs-fmt
    pkgs.bitwarden-desktop
    inputs.nixpkgs-mattermost.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mattermost-desktop
    inputs.yukigram.packages.${pkgs.stdenv.hostPlatform.system}.nixpak
    geary-sandbox.config.env
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
