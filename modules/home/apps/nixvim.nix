{ config, lib, pkgs, inputs, ... }:
{

  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.useGlobalPackages = true;
    opts = {
      mouse = "a";
      number = true;
      relativenumber = false;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      cursorline = true;
      clipboard = "unnamedplus";
      langmap = lib.concatStringsSep "," [
        "ёйцукенгшщзхъфывапролджэячсмитьбю;`qwertyuiop[]asdfghjkl\\;'zxcvbnm\\,."
        "ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ;~QWERTYUIOP{}ASDFGHJKL:\\\"ZXCVBNM<>"
        "№;#"
      ];
    };
    plugins.treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
      };
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        kdl
        nix
        json
        python
      ];
    };
    plugins.neo-tree = {
      enable = true;
      settings = {
        sources = [
          "filesystem"
          "git_status"
        ];
        close_if_last_window = true;
        sort_case_insensitive = true;
        window.width = 26;
        filesystem = {
          use_libuv_file_watcher = true;
          follow_current_file.enabled = true;
          hijack_netrw_behavior = "open_default";
          filtered_items = {
            hide_dotfiles = false;
            hide_gitignored = false;
          };
        };
      };
    };
    plugins.render-markdown = {
      enable = true;
      settings = {
        checkbox = {
          enabled = true;
          unchecked = {
            icon = "󰄱 ";
          };
          checked = {
            icon = "󰱒 ";
          };
        };
        heading = {
          enabled = true;
          sign = false;
          icons = [
            ""
            ""
            ""
            ""
            ""
            ""
          ]; # Без иконок
          backgrounds = [
            "RenderMarkdownH1Bg"
            "RenderMarkdownH2Bg"
            "RenderMarkdownH3Bg"
            "RenderMarkdownH4Bg"
            "RenderMarkdownH5Bg"
            "RenderMarkdownH6Bg"
          ];
        };
      };
    };
    plugins.toggleterm = {
      enable = true;
      settings = {
        direction = "horizontal";
        size = 14;
        open_mapping = "[[<F4>]]";
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<F3>";
        action = "<cmd>Neotree toggle<CR>";
        options.desc = "Toggle file tree";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<F4>";
        action = "<cmd>ToggleTerm<CR>";
        options.desc = "Toggle terminal";
      }
    ];
  };
}

