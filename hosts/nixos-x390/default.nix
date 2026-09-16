{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "nixos-x390";
  boot = {
    extraModprobeConfig = ''
    options thinkpad_acpi fan_control=1
    '';
    kernelParams = [
      "snd_intel_dspcfg.dsp_driver=3" # Force kernel to use SOF driver
      # Silent boot
      "quiet"
      "loglevel=3"
      "systemd.show_status=auto"
      "udev.log_level=3"
    ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.windows = {
        "11-Pro" = {
          efiDeviceHandle = "FS0";
          sortKey = "a";
        };
      };
    };
  };
  
  services = {
    tlp = {
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
    thinkfan = {
      enable = true;
      settings = {
        sensors = [
          {
            hwmon = "/sys/class/hwmon";
            name = "coretemp";
            indices = [
              1
              2
              3
              4
              5
            ];
          }
        ];
        fans = [
          {
            tpacpi = "/proc/acpi/ibm/fan";
          }
        ];
        levels = [
          [
            0
            0
            48
          ]
          [
            1
            44
            54
          ]
          [
            2
            50
            58
          ]
          [
            3
            54
            63
          ]
          [
            6
            60
            70
          ]
          [
            7
            65
            75
          ]
          [
            "level full-speed"
            75
            32767
          ]
        ];
      };
    };
  };
  system.stateVersion = "25.11"; #Change might cause damage.
}
