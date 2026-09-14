{ config, lib, pkgs, osConfig ? null, ... }:

let
  hostName = if osConfig != null then osConfig.networking.hostName else "nixos-x390";
  accentRed = "#${config.lib.stylix.colors.base08}";

  record-border = pkgs.runCommandCC "record-border"
    {
      nativeBuildInputs = [ pkgs.pkg-config ];
      buildInputs = [ pkgs.gtk3 pkgs.gtk-layer-shell pkgs.cairo ];
    } ''
        mkdir -p $out/bin
        $CC -O3 -Wall \
          $(pkg-config --cflags --libs gtk+-3.0 gtk-layer-shell-0 cairo) \
          -x c - -o $out/bin/record-border << 'EOF'
    #include <gtk/gtk.h>
    #include <gtk-layer-shell.h>
    #include <cairo.h>
    #include <stdlib.h>
    #include <signal.h>

    static int g_x = 0, g_y = 0, g_w = 0, g_h = 0;
    static double g_r = 0.0, g_g = 0.0, g_b = 0.0;

    static void on_sig(int sig) {
        (void)sig;
        gtk_main_quit();
    }

    static gboolean on_draw(GtkWidget *widget, cairo_t *cr, gpointer user_data) {
        (void)widget;
        (void)user_data;

        cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
        cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 0.0);
        cairo_paint(cr);

        cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
        cairo_set_source_rgb(cr, g_r, g_g, g_b);
        cairo_set_line_width(cr, 2.0);
        cairo_rectangle(cr, g_x - 2.0, g_y - 2.0, g_w + 4.0, g_h + 4.0);
        cairo_stroke(cr);

        return TRUE;
    }

    static void on_map(GtkWidget *widget, gpointer user_data) {
        (void)user_data;
        GdkWindow *gdk_win = gtk_widget_get_window(widget);
        if (gdk_win) {
            cairo_region_t *empty = cairo_region_create();
            gdk_window_input_shape_combine_region(gdk_win, empty, 0, 0);
            cairo_region_destroy(empty);
        }
    }

    int main(int argc, char *argv[]) {
        gtk_init(&argc, &argv);

        if (argc < 5) return 1;
        g_x = atoi(argv[1]);
        g_y = atoi(argv[2]);
        g_w = atoi(argv[3]);
        g_h = atoi(argv[4]);

        const char *hex = "${config.lib.stylix.colors.base08}";
        unsigned int val = 0;
        sscanf(hex, "%x", &val);
        g_r = ((val >> 16) & 0xFF) / 255.0;
        g_g = ((val >> 8) & 0xFF) / 255.0;
        g_b = (val & 0xFF) / 255.0;

        GtkWidget *win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_layer_init_for_window(GTK_WINDOW(win));
        gtk_layer_set_layer(GTK_WINDOW(win), GTK_LAYER_SHELL_LAYER_OVERLAY);
        gtk_layer_set_exclusive_zone(GTK_WINDOW(win), -1);
        gtk_layer_set_anchor(GTK_WINDOW(win), GTK_LAYER_SHELL_EDGE_TOP, TRUE);
        gtk_layer_set_anchor(GTK_WINDOW(win), GTK_LAYER_SHELL_EDGE_BOTTOM, TRUE);
        gtk_layer_set_anchor(GTK_WINDOW(win), GTK_LAYER_SHELL_EDGE_LEFT, TRUE);
        gtk_layer_set_anchor(GTK_WINDOW(win), GTK_LAYER_SHELL_EDGE_RIGHT, TRUE);
        gtk_layer_set_keyboard_mode(GTK_WINDOW(win), GTK_LAYER_SHELL_KEYBOARD_MODE_NONE);

        gtk_widget_set_app_paintable(win, TRUE);

        GdkScreen *screen = gtk_widget_get_screen(win);
        GdkVisual *visual = gdk_screen_get_rgba_visual(screen);
        if (visual) {
            gtk_widget_set_visual(win, visual);
        }

        g_signal_connect(win, "draw", G_CALLBACK(on_draw), NULL);
        g_signal_connect(win, "map", G_CALLBACK(on_map), NULL);

        signal(SIGTERM, on_sig);
        signal(SIGINT, on_sig);

        gtk_widget_show_all(win);
        gtk_main();
        return 0;
    }
    EOF
  '';

  screen-record-toggle = pkgs.writeShellScriptBin "screen-record-toggle" ''
    export PATH="${pkgs.slurp}/bin:${pkgs.procps}/bin:${pkgs.libnotify}/bin:${pkgs.coreutils}/bin:$PATH"

    stop_recording() {
      pkill -f -SIGINT gpu-screen-recorder 2>/dev/null || true
      pkill -x record-border 2>/dev/null || true
    }

    if pgrep -f gpu-screen-recorder >/dev/null; then
      stop_recording
      notify-send -a record-notify -t 3000 "GPU Screen Recorder" "Recording saved" 2>/dev/null || true
      exit 0
    fi

    GEOM_RAW=$(slurp -f "%x %y %w %h" -d -c "${accentRed}" -b "#00000022")
    if [ -z "$GEOM_RAW" ]; then
      exit 0
    fi

    read -r X Y W H <<< "$GEOM_RAW"
    GEOM="''${W}x''${H}+''${X}+''${Y}"
    OUT_DIR="$HOME/Videos/Screencasts"
    mkdir -p "$OUT_DIR"
    OUT_FILE="$OUT_DIR/video-$(date +%Y-%m-%d_%H-%M-%S).mp4"

    ${record-border}/bin/record-border "$X" "$Y" "$W" "$H" &

    notify-send -a record-notify -t 2500 "GPU Screen Recorder" "Recording of ''${GEOM} started" 2>/dev/null || true

    ${pkgs.gpu-screen-recorder}/bin/gpu-screen-recorder \
      -w "$GEOM" \
      -f 60 \
      -a default_output \
      -o "$OUT_FILE"

    stop_recording
  '';
  niri-layout-notify = pkgs.writeShellScriptBin "niri-layout-notify" ''
    export PATH="${pkgs.niri}/bin:${pkgs.jq}/bin:${pkgs.libnotify}/bin:$PATH"
    
    niri msg --json event-stream | while read -r line; do
      case "$line" in
        *'"KeyboardLayoutSwitched"'*)
          idx=$(echo "$line" | jq -r '.KeyboardLayoutSwitched.idx // empty')
          if [ "$idx" = "0" ]; then
            notify-send -a layout-osd -h string:x-canonical-private-synchronous:layout-osd "EN"
          elif [ "$idx" = "1" ]; then
            notify-send -a layout-osd -h string:x-canonical-private-synchronous:layout-osd "RU"
          fi
          ;;
      esac
    done
  '';

  screenshot-area = pkgs.writeShellScriptBin "screenshot-area" ''
    export PATH="${pkgs.wayfreeze}/bin:${pkgs.grim}/bin:${pkgs.slurp}/bin:${pkgs.swappy}/bin:${pkgs.wl-clipboard}/bin:$PATH"
    
    wayfreeze &
    FREEZE_PID=$!
    trap 'kill $FREEZE_PID 2>/dev/null || true' EXIT INT TERM
    sleep 0.05

    TARGET="$1"
    GEOM=$(slurp)
    
    if [ -z "$GEOM" ]; then
      exit 0
    fi

    TMP_SHOT=$(mktemp --suffix=.png)
    grim -g "$GEOM" "$TMP_SHOT"
    kill $FREEZE_PID 2>/dev/null || true

    case "$TARGET" in
      "swappy")
        swappy -f "$TMP_SHOT" -o - | wl-copy
        ;;
      "clipboard")
        wl-copy < "$TMP_SHOT"
        ;;
      "edit-only")
        swappy -f "$TMP_SHOT"
        ;;
    esac

    rm -f "$TMP_SHOT"
  '';

  nix-deploy = pkgs.writeShellScriptBin "nix-deploy" ''
    set -e

    if [ ! -f "flake.nix" ]; then
        echo "error: there is no flake.nix" >&2
        exit 1
    fi

    nixpkgs-fmt .

    git add -A

    CURRENT_DATE=$(date "+%Y-%m-%d %H:%M")

    if [ "$1" = "--amend" ]; then
        git commit --amend --no-edit || echo "No changes to amend"

    elif [ "$2" = "--amend" ]; then
        git commit --amend -m "$1" || echo "No changes to amend"

    else
        COMMIT_MSG=''${1:-"deploy: $CURRENT_DATE"}
        git commit -m "$COMMIT_MSG" || echo "No changes to commit"
    fi

    sudo rsync -trq --chown=root:root \
    --include={"configuration.nix","hardware-configuration.nix","flake.nix","flake.lock"} \
    --exclude="*" \
    ./ /etc/nixos/

    sudo nixos-rebuild switch --flake .#${hostName}
  '';

  rdp-connect = pkgs.writeShellScriptBin "rdp-connect" ''
    set -e

    export PATH="${pkgs.wireproxy}/bin:${pkgs.coreutils}/bin:${pkgs.netcat-openbsd}/bin:${pkgs.freerdp}/bin:$PATH"

    WG_CONF="${config.age.secrets.rdp-proxy.path}"
    RDP_PASS_FILE="${config.age.secrets.rdp-pass.path}"
    LOCAL_SHARE="${config.home.homeDirectory}/Windows"
    RDP_SERVER_IP="192.168.49.2"
    RDP_SERVER_PORT="3389"
    PROXY_PORT="33890"

    mkdir -p "$LOCAL_SHARE"

    cleanup() {
      echo "Stopping tunnel..."
      if [ -n "$WIREPROXY_PID" ]; then
        kill "$WIREPROXY_PID" 2>/dev/null || true
      fi
      if [ -n "$ARGS_FILE" ] && [ -f "$ARGS_FILE" ]; then
        rm -f "$ARGS_FILE"
      fi
    }
    trap cleanup EXIT INT TERM

    echo "Checking direct connectivity to $RDP_SERVER_IP..."
    if nc -z -w 1 "$RDP_SERVER_IP" "$RDP_SERVER_PORT" >/dev/null 2>&1; then
      echo "Direct connection is available. Bypassing WireGuard proxy..."
      RDP_CONNECT_TARGET="$RDP_SERVER_IP:$RDP_SERVER_PORT"
    else
      echo "Direct connection unavailable. Starting userspace WireGuard proxy..."
      wireproxy -c "$WG_CONF" >/dev/null 2>&1 &
      WIREPROXY_PID=$!
      echo "Waiting for tunnel to establish on port $PROXY_PORT..."
      timeout=50

      while ! nc -z 127.0.0.1 "$PROXY_PORT" >/dev/null 2>&1; do
        sleep 0.1
        timeout=$((timeout - 1))
        if [ "$timeout" -le 0 ]; then
          echo "Error: Tunnel failed to start" >&2
          exit 1
        fi
      done
      echo "Tunnel is ready."
      RDP_CONNECT_TARGET="127.0.0.1:$PROXY_PORT"
    fi

    ARGS_FILE=$(mktemp -p /dev/shm rdp-args.XXXXXX)
    chmod 600 "$ARGS_FILE"

    cat << EOF > "$ARGS_FILE"
/v:$RDP_CONNECT_TARGET
/u:v_perminov
/p:$(cat "$RDP_PASS_FILE")
/drive:Windows,$LOCAL_SHARE
+dynamic-resolution
-grab-keyboard
+clipboard
/cert:ignore
EOF

    echo "Starting xfreerdp with args from file..."
    xfreerdp /args-from:file:"$ARGS_FILE"
  '';

in
{
  home.packages = [
    niri-layout-notify
    rdp-connect
    nix-deploy
    screenshot-area
    screen-record-toggle
  ];
}
