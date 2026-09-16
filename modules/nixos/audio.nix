{ config, lib, pkgs, inputs, ... }:

{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber.enable = true;
  };

  # Disable UCM due to https://github.com/alsa-project/alsa-ucm-conf/issues/785
  environment.sessionVariables = {
    ALSA_CONFIG_UCM2 = "/dev/null";
  };
  systemd = {
    user.services = {
      pipewire.environment.ALSA_CONFIG_UCM2 = "/dev/null";
      wireplumber.environment.ALSA_CONFIG_UCM2 = "/dev/null";
    };
    services.alsa-volumes = {
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
  };
}
