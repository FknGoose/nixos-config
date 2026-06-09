{ config, lib, pkgs, osConfig ? null, ... }:

let
  hostName = if osConfig != null then osConfig.networking.hostName else "nixos-x390";
in
{
    home.packages = [
        (pkgs.writeShellScriptBin "nix-deploy" ''
        set -e

        git add -A

        if [ "$1" = "--amend" ]; then
            git commit --amend --no-edit || echo "No changes to amend"

        elif [ "$2" = "--amend" ]; then
            git commit --amend -m "$1" || echo "No changes to amend"

        else
            COMMIT_MSG=''${1:-"deploy: $(date '+%Y-%m-%d %H:%M')"}
            git commit -m "$COMMIT_MSG" || echo "No changes to commit"
        fi

        sudo rsync -trq --chown=root:root \
        --include={"configuration.nix","hardware-configuration.nix","flake.nix","flake.lock"} \
        --exclude="*" \
        /home/fkngoose/nixos-config/ /etc/nixos/

        sudo nixos-rebuild switch --flake .#${hostName}
        '')
    ];

}
