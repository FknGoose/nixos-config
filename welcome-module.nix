{ config, lib, pkgs, ... }:

{
    imports = [

    ];

    options = {
        services.myWelcome.enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable custom welcome script";
        };
        services.myWelcome.text = lib.mkOption {
            type = lib.types.str;
            default = "Hello!";
            description = "Welcome text";
        };
    };

    config = lib.mkIf config.services.myWelcome.enable {
        environment.systemPackages = [
            (pkgs.writeShellScriptBin "welcome-custom" "echo '${config.services.myWelcome.text}'")
        ];
        systemd.services.myWelcome = {
            description = "Write welcome text to /etc/welcome.txt";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.writeShellScript "welcome-custom" ''
                touch /etc/welcome.txt
                echo "${config.services.myWelcome.text}" >> /etc/welcome.txt #Yes, I want to store all of
                #them
                ''}";
            };
        };
    };

}
