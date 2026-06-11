{ config, lib, pkgs, osConfig ? null, ... }:

let
  hostName = if osConfig != null then osConfig.networking.hostName else "nixos-x390";
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "nix-deploy" ''
      set -e

      if [ ! -f "flake.nix" ]; then
          echo "error: there is no flake.nix" >&2
          exit 1
      fi

      nixpkgs-fmt .

      git add -A

      CURRENT_DATE=$(date "+%Y-%m-%d %H:%M")

      if [ "$1" = "--amend" ]; then
          git commit --amend --no-edit || echo "No changes to amend"

      elif [ "$2" = "--amend" ]; then
          git commit --amend -m "$1" || echo "No changes to amend"

      else
          COMMIT_MSG=''${1:-"deploy: $CURRENT_DATE"}
          git commit -m "$COMMIT_MSG" || echo "No changes to commit"
      fi

      sudo rsync -trq --chown=root:root \
      --include={"configuration.nix","hardware-configuration.nix","flake.nix","flake.lock"} \
      --exclude="*" \
      ./ /etc/nixos/

      sudo nixos-rebuild switch --flake .#${hostName}
    '')
    (pkgs.writeShellScriptBin "rdp-connect" ''
      set -e

      WP_CONFIG="${config.age.secrets.rdp-proxy.path}"
      RDP_PASS_FILE="${config.age.secrets.rdp-pass.path}"
      LOCAL_SHARE="${config.home.homeDirectory}/Windows"

      if [ ! -f "$WP_CONFIG" ] || [ ! -f "$RDP_PASS_FILE" ]; then
          echo "error: agenix secrets are not decrypted yet." >&2
          exit 1
      fi

      mkdir -p "$LOCAL_SHARE"

      echo "Starting userspace Wireguard tunnel..."
      ${pkgs.wireproxy}/bin/wireproxy -c "$WP_CONFIG" &
      WP_PID=$!

      cleanup() {
          echo "Stopping Wireguard tunnel (PID $WP_PID)..."
          kill "$WP_PID" 2>/dev/null || true
      }
      trap cleanup EXIT

      sleep 2

      echo "Connecting to Windows server via RDP..."
      cat "$RDP_PASS_FILE" | ${pkgs.freerdp}/bin/xfreerdp /v:127.0.0.1:3389 \
        /u:v_perminov \
        /drive:Windows,"$LOCAL_SHARE" \
        +dynamic-resolution \
        +clipboard \
        /cert:ignore
    '')
  ];
}
