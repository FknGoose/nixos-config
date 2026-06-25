{ config, lib, pkgs, osConfig ? null, ... }:

let
  hostName = if osConfig != null then osConfig.networking.hostName else "nixos-x390";

  nix-deploy = pkgs.writeShellScriptBin "nix-deploy" ''
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
  '';

  rdp-connect = pkgs.writeShellScriptBin "rdp-connect" ''
    set -e

    export PATH="${pkgs.wireproxy}/bin:${pkgs.coreutils}/bin:${pkgs.netcat-openbsd}/bin:$PATH"

    WG_CONF="${config.age.secrets.rdp-proxy.path}"
    RDP_PASS_FILE="${config.age.secrets.rdp-pass.path}"
    LOCAL_SHARE="${config.home.homeDirectory}/Windows"
    RDP_SERVER_IP="192.168.49.2"
    RDP_SERVER_PORT="3389"
    PROXY_PORT="33890"

    mkdir -p "$LOCAL_SHARE"

    cleanup() {
      echo "Stopping tunnel..."
      if [ -n "$WIREPROXY_PID" ]; then
        kill "$WIREPROXY_PID" 2>/dev/null || true
      fi
    }
    trap cleanup EXIT INT TERM

    echo "Checking direct connectivity to $RDP_SERVER_IP..."
    if nc -z -w 1 "$RDP_SERVER_IP" "$RDP_SERVER_PORT" >/dev/null 2>&1; then
      echo "Direct connection is available. Bypassing WireGuard proxy..."
      RDP_CONNECT_TARGET="$RDP_SERVER_IP:$RDP_SERVER_PORT"
    else
      echo "Direct connection unavailable. Starting userspace WireGuard proxy..."
      wireproxy -c "$WG_CONF" >/dev/null 2>&1 &
      WIREPROXY_PID=$!
      echo "Waiting for tunnel to establish on port $PROXY_PORT..."
      timeout=50

      while ! nc -z 127.0.0.1 "$PROXY_PORT" >/dev/null 2>&1; do
        sleep 0.1
        timeout=$((timeout - 1))
        if [ "$timeout" -le 0 ]; then
          echo "Error: Tunnel failed to start" >&2
          exit 1
        fi
      done
      echo "Tunnel is ready."
      RDP_CONNECT_TARGET="127.0.0.1:$PROXY_PORT"
    fi

    echo "Starting xfreerdp to $RDP_CONNECT_TARGET..."
    ${pkgs.freerdp}/bin/xfreerdp /v:"$RDP_CONNECT_TARGET" \
      /u:v_perminov \
      /from-stdin:force \
      /drive:Windows,"$LOCAL_SHARE" \
      +dynamic-resolution \
      -grab-keyboard \
      +clipboard \
      /cert:ignore < "$RDP_PASS_FILE"
  '';
in
{
  home.packages = [
    rdp-connect
    nix-deploy
  ];
}
