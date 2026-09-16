{ config, lib, pkgs, inputs, ... }:
let

  yazi-chooser = pkgs.writeShellScriptBin "yazi-chooser" ''
    set -e

    multiple="$1"
    directory="$2"
    save="$3"
    path="$4"
    out="$5"

    cmd="${pkgs.yazi}/bin/yazi"
    termcmd="${pkgs.kitty}/bin/kitty --class=yazi-filechooser -e"

    if [ "$save" = "1" ]; then
      exec $termcmd $cmd "$path" --chooser-file="$out"
    elif [ "$directory" = "1" ]; then
      exec $termcmd $cmd "$path" --chooser-file="$out" --cwd-file="$out"
    else
      exec $termcmd $cmd "$path" --chooser-file="$out"
    fi
  '';

in
{
  home = {
    packages = [
      yazi-chooser
      pkgs.brightnessctl
      pkgs.btop
      pkgs.psmisc
    ];
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
      TERMINAL = "kitty";
    };
  };
  programs = { 
    kitty = {
      enable = true;
      settings = {
        tab_bar_style = "hidden";
        hide_window_decorations = "yes";
        window_padding_width = 4;
        enable_audio_bell = false;
        confirm_os_window_close = 0;
      };
      keybindings = {
        "ctrl+shift+enter" = "no_op";
        "ctrl+shift+t" = "no_op";
        "ctrl+shift+w" = "no_op";
        "ctrl+shift+n" = "no_op";
        "ctrl+shift+]" = "no_op";
        "ctrl+shift+[" = "no_op";
      };
    };

    yazi = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        mgr = {
          show_hidden = true;
          sort_by = "natural";
          sort_dir_first = true;
        };
      };
      keymap = {
        mgr.prepend_keymap = [
          {
            on = [ "р" ];
            run = "leave";
            desc = "Left (h)";
          }
          {
            on = [ "о" ];
            run = "arrow 1";
            desc = "Down (j)";
          }
          {
            on = [ "л" ];
            run = "arrow -1";
            desc = "Up (k)";
          }
          {
            on = [ "д" ];
            run = "enter";
            desc = "Right (l)";
          }
        ];
      };
    };
  };
}
