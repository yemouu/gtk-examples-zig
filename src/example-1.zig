const std = @import("std");

const c = @cImport({
    @cInclude("gtk/gtk.h");
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

pub fn activate(app: *c.GtkApplication, user_data: c.gpointer) void {
    _ = user_data;

    const window: *c.GtkWidget = c.gtk_application_window_new(app);
    c.gtk_window_set_title(@ptrCast(*c.GtkWindow, window), "Window");
    c.gtk_window_set_default_size(@ptrCast(*c.GtkWindow, window), 200, 200);

    const box: *c.GtkWidget = c.gtk_box_new(c.GTK_ORIENTATION_VERTICAL, 0);
    c.gtk_widget_set_halign(box, c.GTK_ALIGN_CENTER);
    c.gtk_widget_set_valign(box, c.GTK_ALIGN_CENTER);

    c.gtk_window_set_child(@ptrCast(*c.GtkWindow, window), box);

    const button: *c.GtkWidget = c.gtk_button_new_with_label("Hello World");
    // using reimplementations
    _ = _g_signal_connect(button, "clicked", @ptrCast(c.GCallback, print_hello), null);
    _ = _g_signal_connect_swapped(
        button,
        "clicked",
        @ptrCast(c.GCallback, c.gtk_window_destroy),
        window,
    );

    c.gtk_box_append(@ptrCast(*c.GtkBox, box), button);

    c.gtk_widget_show(window);
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
