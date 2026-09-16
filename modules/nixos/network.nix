{ config, lib, pkgs, inputs, ... }:
{
  networking = {
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

  services.blueman.enable = true;
  services.mihomo = {
    enable = true;
    tunMode = true;
    processesInfo = true;
    webui = pkgs.metacubexd;
    configFile = config.age.secrets.mihomo.path;
  };
  age.secrets.mihomo = {
    file = ../../secrets/mihomo.yaml.age;
    mode = "400";
  };
}
