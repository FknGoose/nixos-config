{
config,
pkgs,
lib,
inputs,
...
}:
let 

  rdp-connect = pkgs.writeShellScriptBin "rdp-connect" ''
        set -e

        export PATH="${pkgs.coreutils}/bin:${pkgs.freerdp}/bin:$PATH"

        RDP_PASS_FILE="${config.age.secrets.rdp-pass.path}"
        LOCAL_SHARE="${config.home.homeDirectory}/Windows"
        RDP_SERVER="192.168.49.2:3389"

        mkdir -p "$LOCAL_SHARE"

        ARGS_FILE=$(mktemp -p /dev/shm rdp-args.XXXXXX)
        chmod 600 "$ARGS_FILE"

        cleanup() {
          if [ -n "$ARGS_FILE" ] && [ -f "$ARGS_FILE" ]; then
            rm -f "$ARGS_FILE"
          fi
        }
        trap cleanup EXIT INT TERM

        cat << EOF > "$ARGS_FILE"
    /v:$RDP_SERVER
    /u:v_perminov
    /p:$(cat "$RDP_PASS_FILE")
    /drive:Windows,$LOCAL_SHARE
    +dynamic-resolution
    -grab-keyboard
    +clipboard
    /cert:ignore
    /network:auto
    +auto-reconnect
    EOF

        echo "Connecting directly to $RDP_SERVER..."
        xfreerdp /args-from:file:"$ARGS_FILE"
  '';

in
  {
  imports = [
    inputs.agenix.homeManagerModules.default
    ./styling.nix
    ./desktop
    ./apps/terminal.nix
    ./apps/nixvim.nix
    ./apps/sandboxes.nix
    ./apps/mime.nix
  ];
  home = {
    stateVersion = "25.11";
    username = "fkngoose";
    homeDirectory = "/home/fkngoose";
    sessionVariables.TZ = "Europe/Moscow";
    language = {
      base = "en_US.UTF-8";
      time = "en_IE.UTF-8";
    };
    packages = [
      rdp-connect
      pkgs.onlyoffice-desktopeditors
      pkgs.nixfmt
      pkgs.freerdp
      pkgs.tauon
    ];

  };

  programs = {
    git = {
      enable = true;
      settings.user = {
        name = "FknGoose";
        email = "busygose@gmail.com";
      };
    };
    ssh = {
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
    nh = {
      enable = true;
      flake = "${config.home.homeDirectory}/nixos-config";
      clean = {
        enable = true;
        extraArgs = "--keep-since 4d --keep 3";
      };
    };
    rbw = {
      enable = true;
      settings = {
        email = "busygose@gmail.com";
        pinentry = pkgs.pinentry-gnome3;
      };
    };
    vesktop.enable = true;
  };
  age = {
    identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
    secrets = {
      rdp-pass = {
        file = ../../secrets/rdp-pass.age;
        mode = "600";
      };
    };
  };
}
