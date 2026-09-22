/* Linux shell in C: a GTK window hosting the game in WebKitGTK. Build: see apps/linux/build.sh */
#include <gtk/gtk.h>
#include <webkit2/webkit2.h>

static void activate(GtkApplication *app, gpointer data) {
    GtkWidget *win = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(win), "Vancouver Vice");
    gtk_window_set_default_size(GTK_WINDOW(win), 1280, 800);
    WebKitWebView *web = WEBKIT_WEB_VIEW(webkit_web_view_new());
    WebKitSettings *s = webkit_web_view_get_settings(web);
    webkit_settings_set_enable_webgl(s, TRUE);
    webkit_settings_set_hardware_acceleration_policy(s, WEBKIT_HARDWARE_ACCELERATION_POLICY_ALWAYS);
    webkit_settings_set_user_agent_with_application_details(s, "VancouverViceApp", "1.24");
    gtk_container_add(GTK_CONTAINER(win), GTK_WIDGET(web));
    webkit_web_view_load_uri(web, "https://vancouvervice.heyitsmejosh.com/play.html");
    gtk_window_fullscreen(GTK_WINDOW(win));
    gtk_widget_show_all(win);
}

int main(int argc, char **argv) {
    GtkApplication *app = gtk_application_new("com.jaybulb.vancouvervice", G_APPLICATION_DEFAULT_FLAGS);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
