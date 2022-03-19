const std = @import("std");

const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("glib/gstdio.h");
});

// g_signal_connect isn't being converted from C to Zig correctly, so using the following
// reimplementations: https://github.com/Swoogan/ziggtk/blob/master/src/gtk.zig
// zig bug report: https://github.com/ziglang/zig/issues/5596
pub fn _g_signal_connect(
    instance: c.gpointer,
    detailed_signal: [*c]const c.gchar,
    c_handler: c.GCallback,
    data: c.gpointer,
) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(*c.GConnectFlags, &zero);
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}

pub fn _g_signal_connect_swapped(
    instance: c.gpointer,
    detailed_signal: [*c]const c.gchar,
    c_handler: c.GCallback,
    data: c.gpointer,
) c.gulong {
    return c.g_signal_connect_data(
        instance,
        detailed_signal,
        c_handler,
        data,
        null,
        c.G_CONNECT_SWAPPED,
    );
}

pub fn print_hello(widget: *c.GtkWidget, data: c.gpointer) void {
    _ = widget;
    _ = data;

    c.g_print("Hello World\n");
}

pub fn quit_cb(window: *c.GtkWindow) void {
    c.gtk_window_close(window);
}

pub fn activate(app: *c.GtkApplication, user_data: c.gpointer) void {
    _ = user_data;

    const builder: ?*c.GtkBuilder = c.gtk_builder_new();
    _ = c.gtk_builder_add_from_file(builder, "src/builder.ui", null);
    defer c.g_object_unref(builder);

    const window: *c.GObject = c.gtk_builder_get_object(builder, "window");
    c.gtk_window_set_application(@ptrCast(*c.GtkWindow, window), app);

    var button: *c.GObject = c.gtk_builder_get_object(builder, "button1");
    // using reimplementation
    _ = _g_signal_connect(button, "clicked", @ptrCast(c.GCallback, print_hello), null);

    button = c.gtk_builder_get_object(builder, "button2");
    // using reimplementation
    _ = _g_signal_connect(button, "clicked", @ptrCast(c.GCallback, print_hello), null);

    button = c.gtk_builder_get_object(builder, "quit");
    // using reimplementation
    _ = _g_signal_connect_swapped(button, "clicked", @ptrCast(c.GCallback, quit_cb), window);


    c.gtk_widget_show(@ptrCast(*c.GtkWidget, window));
}

pub fn main() !void {
    const app = c.gtk_application_new("org.gtk.example", c.G_APPLICATION_FLAGS_NONE);
    defer c.g_object_unref(app);

    // using reimplementation
    _ = _g_signal_connect(app, "activate", @ptrCast(c.GCallback, activate), null);

    const status: c_int = c.g_application_run(@ptrCast(*c.GApplication, app), 0, null);
    if (status != 0)
        return error.Error;
}
