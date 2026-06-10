{ inputs, pkgs, ... }:

let
  mkExtension = pluginId: {
    install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
    installation_mode = "force_installed";
  };
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];
  programs.zen-browser = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisablePocket = true;
      DisableAppUpdate = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      ExtensionSettings = {
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtension "bitwarden-password-manager";
        "addon@darkreader.org" = mkExtension "darkreader";
        "enhancerforyoutube@maximerf.addons.mozilla.org" = mkExtension "enhancer-for-youtube";
        "soundfixer@unrelenting.technology" = mkExtension "soundfixer";
        "sponsorBlocker@ajay.app" = mkExtension "sponsorblock";
        "uBlock0@raymondhill.net" = mkExtension "ublock-origin";
      };
    };
    profiles.default = {
      isDefault = true;
      name = "Default Profile";
      id = 0;
      mods = [
        "1e86cf37-a127-4f24-b919-d265b5ce29a0" # Lean
        "f7c71d9a-bce2-420f-ae44-a64bd92975ab" # Better Unloaded Tabs
        "7190e4e9-bead-4b40-8f57-95d852ddc941" # Tab title fixes
        "fd24f832-a2e6-4ce9-8b19-7aa888eb7f8e" # Quietify
        "cb15abdb-0514-4e09-8ce5-722cf1f4a20f" # Hide Extension Name
        "35f24f2c-b211-43e2-9fe4-2c3bc217d9f7" # Compact tabs title
        "72f8f48d-86b9-4487-acea-eb4977b18f21" # Better CtrlTab Panel
        "ae7868dc-1fa1-469e-8b89-a5edf7ab1f24" # Load Bar
        "a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec" # Cleaned URL bar
        "4a222d82-2803-4ed2-a390-90abfce4f195" # Back Fwd Always Hidden
        "642854b5-88b4-4c40-b256-e035532109df" # Transparent Zen
      ];
      containersForce = true;
      containers = {
        "Personal" = {
          id = 1;
          color = "blue";
          icon = "fingerprint";
        };
        "Work" = {
          id = 2;
          color = "orange";
          icon = "briefcase";
        };
      };
      spacesForce = true;
      spaces = {
        "Personal" = {
          id = "151b67cb-94f6-4b94-8b35-ae5da6b757a6";
          position = 1000;
          icon = "1";
          container = 1;
        };
        "Work" = {
          id = "4a3be8fb-10d6-4484-96fe-ab3da6b757a6";
          position = 2000;
          icon = "2";
          container = 2;
        };
      };
      settings = {
        "network.proxy.type" = 1;
        "network.proxy.http" = "127.0.0.1";
        "network.proxy.http_port" = 52080;
        "network.proxy.socks" = "127.0.0.1";
        "network.proxy.socks_port" = 52080;
        "network.proxy.ssl" = "127.0.0.1";
        "network.proxy.ssl_port" = 52080;
        "network.proxy.share_proxy_settings" = true;
        "mod.lean.hide-zoom" = true;
        "mod.lean.show-translation" = true;
        "mod.lean.show-pageactions" = true;
        "mod.lean.top-workspace" = false;
        "mod.lean.pinned-ext" = true;
        "mod.lean.bottom-buttons" = true;
        "mod.lean.ninja-top-buttons" = true;
        "mod.lean.bookmarks" = true;
        "mod.lean.pinned-ext.workspaces" = true;
        "mod.cleanedurlbar.customcolor" = "hsl(0 0 10)";
        "mod.cleanedurlbar.customselectcolor" = "rgba(80, 80, 250, 0.75)";
        "mod.cleanedurlbar.customselectfontcolor" = "rgba(255,255,255,1)";
        "mod.cleanedurlbar.customtransparency" = "100%";
        "font.name.monospace.x-cyrillic" = "JetBrainsMono NFM";
        "font.name.sans-serif.x-cyrillic" = "Inter";
        "font.size.variable.x-western" = 14;
        "intl.accept_languages" = "ru-ru,en-us,ru,en";
        "intl.regional_prefs.use_os_locales" = true;
        "browser.contentblocking.category" = "strict";
        "privacy.fingerprintingProtection" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.query_stripping.enabled" = true;
        "zen.view.compact.enable-at-startup" = true;
        "zen.workspaces.continue-where-left-off" = true;
        "zen.glance.activation-method" = "alt";
        "general.autoScroll" = true;
        "browser.ctrlTab.sortByRecentlyUsed" = true;
        "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
        "zen.workspaces.active" = "{151b67cb-94f6-4b94-8b35-ae5da6b757a6}";
        "browser.urlbar.showSearchSuggestionsFirst" = false;
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.history" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.recentsearches" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.topsites" = false;
        "browser.newtabpage.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.uiCustomization.state" = builtins.toJSON {
          currentVersion = 24;
          newElementCount = 5;
          dirtyAreaCache = [
            "nav-bar"
            "vertical-tabs"
            "zen-sidebar-foot-buttons"
            "PersonalToolbar"
            "toolbar-menubar"
            "TabsToolbar"
            "unified-extensions-area"
            "zen-sidebar-top-buttons"
          ];
          placements = {
            widget-overflow-fixed-list = [ ];
            unified-extensions-area = [
              "sponsorblocker_ajay_app-browser-action"
              "ublock0_raymondhill_net-browser-action"
              "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
              "enhancerforyoutube_maximerf_addons_mozilla_org-browser-action"
              "soundfixer_unrelenting_technology-browser-action"
              "addon_darkreader_org-browser-action"
            ];
            nav-bar = [
              "back-button"
              "forward-button"
              "stop-reload-button"
              "customizableui-special-spring1"
              "vertical-spacer"
              "urlbar-container"
              "customizableui-special-spring2"
              "unified-extensions-button"
              "reset-pbm-toolbar-button"
            ];
            toolbar-menubar = [ "menubar-items" ];
            TabsToolbar = [ "tabbrowser-tabs" ];
            vertical-tabs = [ ];
            PersonalToolbar = [ "import-button" "personal-bookmarks" ];
            zen-sidebar-top-buttons = [ "zen-toggle-compact-mode" ];
            zen-sidebar-foot-buttons = [
              "downloads-button"
              "zen-workspaces-button"
              "firefox-view-button"
              "screenshot-button"
            ];
          };
          seen = [
            "developer-button"
            "screenshot-button"
            "_446900e4-71c2-419f-a6a7-df9c091e268b_-browser-action"
            "enhancerforyoutube_maximerf_addons_mozilla_org-browser-action"
            "ublock0_raymondhill_net-browser-action"
            "soundfixer_unrelenting_technology-browser-action"
            "addon_darkreader_org-browser-action"
            "reset-pbm-toolbar-button"
          ];
        };
      };
      keyboardShortcutsVersion = 19;
      keyboardShortcuts = [
        {
          id = "Browser:Back";
          key = "z";
          modifiers = { alt = true; };
        }
        {
          id = "Browser:Forward";
          key = "x";
          modifiers = { alt = true; };
        }
        {
          id = "focusURLBar";
          key = "t";
          modifiers = { alt = true; };
        }
        {
          id = "Browser:OpenLocation";
          key = "t";
          modifiers = { alt = true; };
        }
        {
          id = "zen-workspace-backward";
          key = "q";
          modifiers = { alt = true; };
        }
        {
          id = "zen-workspace-forward";
          key = "e";
          modifiers = { alt = true; };
        }
      ];
      userChrome = ''
        /* Name: Download BG */
        #downloads-indicator-progress-outer::after {
          content: "";
          display: block;
          position: absolute;
          inset: 0;
          z-index: -40;
          background: var(--toolbar-field-background-color);
        }

        /* Name: Right Side Glance Buttons */
        .zen-glance-sidebar-container {
          left: 100% !important;
          right: unset !important;
        }
      '';
    };
  };
}
