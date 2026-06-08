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
        system.activationScripts.myWelcomeSetup = {
            text = ''
                mkdir -p /etc/welcome-dir
                echo '${config.services.myWelcome.text}' > /etc/welcome-dir/message.txt
            '';
            deps = [ "etc" ];
        };
    };
}
