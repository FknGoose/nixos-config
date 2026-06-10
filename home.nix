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
          "/dev/shm"
          (sloth.concat' sloth.homeDir "/Downloads")
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/zen"))
          (sloth.concat [ (sloth.env "XDG_RUNTIME_DIR") "/pulse" ])
          (sloth.concat [ (sloth.env "XDG_RUNTIME_DIR") "/pipewire-0" ])
        ];
        bind.ro = [
          "/etc/passwd"
          "/etc/fonts"
          "/etc/ssl/certs"
          "/etc/static/ssl/certs"
          "/run/current-system/sw/share/themes"
          "/run/current-system/sw/share/hunspell"
          "/run/current-system/sw/share/mime"
          "/run/current-system/sw/share/icons"
          "/tmp/.X11-unix"
          "/run/opengl-driver"
          "/run/opengl-driver-32"
          (sloth.concat' sloth.homeDir "/.config/gtk-3.0")
          (sloth.concat' sloth.homeDir "/.config/dconf")
          (sloth.concat' sloth.homeDir "/.Xauthority")
          (sloth.env "XAUTHORITY")
          "/sys"
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
        "org.freedesktop.portal.Desktop" = "talk";
        "org.freedesktop.portal.Documents" = "talk";
        "org.freedesktop.portal.FileChooser" = "talk";
      };
    };
  };

  myZenPackage = zen-sandbox.config.env // {
    override = _: myZenPackage;
    overrideAttrs = _: myZenPackage;
  };

  mkExtension = pluginId: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
    installation_mode = "force_installed";
  };

  balsa-sandbox = mkNixPak {
    config = { sloth, ... }: {
      app.package = pkgs.balsa;
      app.binPath = "bin/balsa";

      flatpak.appId = "org.gnome.Balsa";

      dbus.enable = true;
      dbus.policies = {
        "org.freedesktop.DBus" = "talk";
        "org.freedesktop.Notifications" = "talk";
        "org.freedesktop.secrets" = "talk";
        "org.freedesktop.portal.Desktop" = "talk";
        "org.freedesktop.portal.Documents" = "talk";
        "org.desktop.Balsa" = "own";
        "org.gnome.Balsa" = "own";
      };

      bubblewrap = {
        network = true;
        bind.rw = [
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.config/balsa"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.cache/balsa"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.local/state/balsa"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.local/share/org.desktop.Balsa"))
          (sloth.mkdir (sloth.concat' sloth.homeDir "/mail"))
          (sloth.concat' sloth.homeDir "/mailbox")
          (sloth.mkdir (sloth.concat' sloth.homeDir "/.gnupg"))
          (sloth.concat [ (sloth.env "XDG_RUNTIME_DIR") "/" (sloth.env "WAYLAND_DISPLAY") ])
        ];
        bind.ro = [
          "/etc/passwd"
          "/etc/fonts"
          "/etc/ssl/certs"
          "/etc/static/ssl/certs"
          "/run/current-system/sw/share/themes"
          "/run/current-system/sw/share/hunspell"
          "/run/current-system/sw/share/mime"
          "/run/current-system/sw/share/icons"
          "/etc/cups"
          "/tmp/.X11-unix"
          "/run/opengl-driver"
          (sloth.concat' sloth.homeDir "/.config/gtk-3.0")
          (sloth.concat' sloth.homeDir "/.config/dconf")
          (sloth.concat' sloth.homeDir "/.Xauthority")
          (sloth.env "XAUTHORITY")
          "/sys"
        ];
        bind.dev = [ "/dev/dri" ];
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

  home.packages = [
    pkgs.htop
    pkgs.freerdp
    pkgs.wireproxy
    pkgs.nixpkgs-fmt
    pkgs.bitwarden-desktop
    inputs.nixpkgs-mattermost.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mattermost-desktop
    inputs.yukigram.packages.${pkgs.stdenv.hostPlatform.system}.nixpak
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
