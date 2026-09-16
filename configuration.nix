{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
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
  boot.extraModprobeConfig = ''
    options thinkpad_acpi fan_control=1
  '';
  boot.kernelParams = [
    "snd_intel_dspcfg.dsp_driver=3" # Force kernel to use SOF driver
    # Silent boot
    "quiet"
    "loglevel=3"
    "systemd.show_status=auto"
    "udev.log_level=3"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.windows = {
    "11-Pro" = {
      efiDeviceHandle = "FS0";
      sortKey = "a";
    };
  };

  # NETWORK
  networking = {
    hostName = "nixos-x390";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      checkReversePath = "loose";
      trustedInterfaces = [ "Meta" ];
      extraCommands = ''
        iptables -I OUTPUT -o lo -p tcp -m multiport --dports 7890,9090 \
        -m owner ! --uid-owner 1000 \
        -m owner ! --uid-owner 0 \
        -j REJECT --reject-with tcp-reset
      '';
    };
  };
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
      };
    };
  };
  # Font packages
  fonts = {
    packages = with pkgs; [
      inter
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
      noto-fonts
      corefonts
    ];
  };

  # Desktop Environment
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = lib.concatStringsSep " " [
          "${pkgs.tuigreet}/bin/tuigreet"
          "--time"
          "--time-format '%H:%M | %A, %d.%m.%y'"
          "--greeting 'Access restricted to authorised personnel only'"
          "--remember"
          "--remember-session"
          "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
          "--cmd niri-session"
        ];
        user = "greeter";
      };
    };
  };
  programs.niri.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-termfilechooser ];

  # USERS
  users.users.fkngoose = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [ ];
    homeMode = "700";
    initialPassword = "1234"; # Don't forget to set a password with ‘passwd’
  };

  # PROGRAMS:
  programs.gpu-screen-recorder.enable = true;

  # SERVICES
  services.blueman.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;
  };
  services.mihomo = {
    enable = true;
    tunMode = true;
    processesInfo = true;
    webui = pkgs.metacubexd;
    configFile = config.age.secrets.mihomo.path;
  };
  services.printing.enable = true;
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
  services.thinkfan = {
    enable = true;
    settings = {
      sensors = [
        {
          hwmon = "/sys/class/hwmon";
          name = "coretemp";
          indices = [ 1 2 3 4 5 ];
        }
      ];
      fans = [
        {
          tpacpi = "/proc/acpi/ibm/fan";
        }
      ];
      levels = [
        [ 0 0 48 ]
        [ 1 44 54 ]
        [ 2 50 58 ]
        [ 3 54 63 ]
        [ 6 60 70 ]
        [ 7 65 75 ]
        [ "level full-speed" 75 32767 ]
      ];
    };
  };
  # Disable UCM due to https://github.com/alsa-project/alsa-ucm-conf/issues/785
  environment.sessionVariables = {
    ALSA_CONFIG_UCM2 = "/dev/null";
  };
  systemd.user.services.pipewire.environment.ALSA_CONFIG_UCM2 = "/dev/null";
  systemd.user.services.wireplumber.environment.ALSA_CONFIG_UCM2 = "/dev/null";
  systemd.services.alsa-volumes = {
    # Preserve settings after reinstallation
    description = "Set ALSA volumes for Realtek ALC257 on boot";
    enable = true;
    script = ''
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set Capture 100% unmute cap
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set "PGA2.0 2 Master" 35%
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set "Mic Boost" 0%
      ${pkgs.alsa-utils}/bin/amixer -c sofhdadsp set "Internal Mic Boost" 0%
    '';
    wantedBy = [ "multi-user.target" ];
    after = [ "sound.target" ];
  };


  # MISC
  age.identityPaths = [ "/home/fkngoose/.ssh/id_ed25519" ];
  age.secrets.mihomo = {
    file = ./secrets/mihomo.yaml.age;
    mode = "400";
  };
  nixpkgs.config.allowUnfree = true;
  security.rtkit.enable = true;
  hardware.enableRedistributableFirmware = true;
  i18n.extraLocales = [ "en_IE.UTF-8/UTF-8" ];
  security.pam.services.swaylock = { };

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

