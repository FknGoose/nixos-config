#include <gtk/gtk.h>
#include <gtk-layer-shell.h>
#include <cairo.h>
#include <stdlib.h>
#include <signal.h>

static int g_x = 0, g_y = 0, g_w = 0, g_h = 0;
static double g_r = 1.0, g_g = 0.0, g_b = 0.0;

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

    if (argc >= 6) {
        const char *hex = argv[5];
        if (hex[0] == '#') hex++;
        unsigned int val = 0;
        sscanf(hex, "%x", &val);
        g_r = ((val >> 16) & 0xFF) / 255.0;
        g_g = ((val >> 8) & 0xFF) / 255.0;
        g_b = (val & 0xFF) / 255.0;
    }

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
