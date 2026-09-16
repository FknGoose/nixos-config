{ config, lib, pkgs, inputs, ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://yukigram.github.io/yukigram"
        "https://yukigram-official.cachix.org"
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
        "https://mirrors.ustc.edu.cn/nix-channels/store"
        "https://mirror.sjtu.edu.cn/nix-channels/store"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "yukigram-nixos-binary-cache:JY9MpP2ESUmPx3cfIpcSRpBK9HQ1/mzHemsvjv1aiYU="
        "yukigram-official.cachix.org-1:PmmKVD/46LWDxfPWKol4rvoqvcdLqFq0aTtG/E1gdA8="
      ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  age.identityPaths = [ "/home/fkngoose/.ssh/id_ed25519" ];

  users.users.fkngoose = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    packages = with pkgs; [ ];
    homeMode = "700";
    initialPassword = "1234"; # Don't forget to set a password with ‘passwd’
  }; 
  nixpkgs.config.allowUnfree = true;
  security.rtkit.enable = true;
  hardware.enableRedistributableFirmware = true;
  i18n.extraLocales = [ "en_IE.UTF-8/UTF-8" ];
}
