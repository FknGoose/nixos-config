{
config,
pkgs,
lib,
inputs,
...
}:

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

  yukigram-sandbox =
    (inputs.yukigram.d.${pkgs.stdenv.hostPlatform.system}.override (prev: {
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
  home.packages = [
    yukigram-sandbox
    zen-sandbox.config.env
  ];
}
