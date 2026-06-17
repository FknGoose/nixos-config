# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix = {
    settings = {
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

  # BOOT
  boot.kernelParams = [ "snd_intel_dspcfg.dsp_driver=3" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.windows = {
    "11-Pro" = {
      efiDeviceHandle = "FS0";
      sortKey = "a";
    };
  };

  # NETWORK
  networking.hostName = "nixos-x390";
  networking.networkmanager.enable = true;

  # Font packages
  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      liberation_ttf
      noto-fonts-color-emoji
      noto-fonts
      corefonts
    ];
  };

  # X11
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };

  # USERS
  users.users.fkngoose = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    packages = with pkgs; [ ];
    homeMode = "700";
    initialPassword = "1234"; # Don't forget to set a password with ‘passwd’
  };

  # PROGRAMS
  programs.firefox.enable = true;
  programs.git.enable = true;
  programs.throne.enable = true;
  programs.throne.tunMode.enable = true;

  # SERVICES
  services.libinput.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
  };
  services.printing.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    pd.enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
      START_CHARGE_THRESH_BAT0 = 70;
      STOP_CHARGE_THRESH_BAT0 = 80;
    };
  };
  systemd.services.declarative-alsa-volumes = {
    description = "Set ALSA volumes for Realtek ALC257 on boot";
    enable = true;
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set Capture 75% unmute cap
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set "PGA2.0 2 Master" 60%
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set "Mic Boost" 0%
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set "Internal Mic Boost" 0%
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
  };


  # MISC
  nixpkgs.config.allowUnfree = true; # For propietary drivers
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  security.rtkit.enable = true;
  hardware.enableRedistributableFirmware = true;
  i18n.extraLocales = [ "en_IE.UTF-8/UTF-8" ];

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}

