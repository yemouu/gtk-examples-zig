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

pub fn _g_signal_connect_after(
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
        c.G_CONNECT_AFTER,
    );
}

var surface: ?*c.cairo_surface_t = null;

var start_x: f64 = 0;
var start_y: f64 = 0;

pub fn clear_surface() void {
    const cr: ?*c.cairo_t = c.cairo_create(surface);

    c.cairo_set_source_rgb(cr, 1, 1, 1);
    c.cairo_paint(cr);

    c.cairo_destroy(cr);
}

pub fn resize_cb(widget: *c.GtkWidget, width: c_int, height: c_int, data: c.gpointer) void {
    _ = width;
    _ = height;
    _ = data;

    if (surface != null) {
        c.cairo_surface_destroy(surface);
        surface = null;
    }

    if (c.gtk_native_get_surface(c.gtk_widget_get_native(widget)) != null) {
        surface = c.gdk_surface_create_similar_surface(
            c.gtk_native_get_surface(c.gtk_widget_get_native(widget)),
            c.CAIRO_CONTENT_COLOR,
            c.gtk_widget_get_width(widget),
            c.gtk_widget_get_height(widget),
        );

        clear_surface();
    }
}

pub fn draw_cb(
    drawing_area: *c.GtkDrawingArea,
    cr: *c.cairo_t,
    width: c_int,
    height: c_int,
    data: c.gpointer,
) void {
    _ = drawing_area;
    _ = width;
    _ = height;
    _ = data;

    c.cairo_set_source_surface(cr, surface, 0, 0);
    c.cairo_paint(cr);
}

pub fn draw_brush(widget: *c.GtkWidget, x: f64, y: f64) void {
    const cr: ?*c.cairo_t = c.cairo_create(surface);

    c.cairo_rectangle(cr, x - 3, y - 3, 6, 6);
    c.cairo_fill(cr);

    c.cairo_destroy(cr);

    c.gtk_widget_queue_draw(widget);
}

pub fn drag_begin(gesture: *c.GtkGestureDrag, x: f64, y: f64, area: *c.GtkWidget) void {
    _ = gesture;

    start_x = x;
    start_y = y;

    draw_brush(area, x, y);
}

pub fn drag_update(gesture: *c.GtkGestureDrag, x: f64, y: f64, area: *c.GtkWidget) void {
    _ = gesture;

    draw_brush(area, start_x + x, start_y + y);
}

pub fn drag_end(gesture: *c.GtkGestureDrag, x: f64, y: f64, area: *c.GtkWidget) void {
    _ = gesture;

    draw_brush(area, start_x + x, start_y + y);
}

pub fn pressed(gesture: *c.GtkGestureDrag, n_press: i16, x: f64, y: f64, area: *c.GtkWidget) void {
    _ = gesture;
    _ = n_press;
    _ = x;
    _ = y;

    clear_surface();
    c.gtk_widget_queue_draw(area);
}

pub fn close_window() void {
    if (surface != null)
        c.cairo_surface_destroy(surface);
}

pub fn activate(app: *c.GtkApplication, user_data: ?c.gpointer) void {
    _ = user_data;

    const window: *c.GtkWidget = c.gtk_application_window_new(app);
    c.gtk_window_set_title(@ptrCast(*c.GtkWindow, window), "Drawing Area");

    _ = _g_signal_connect(window, "destroy", @ptrCast(c.GCallback, close_window), null);

    const frame: *c.GtkWidget = c.gtk_frame_new(null);
    c.gtk_window_set_child(@ptrCast(*c.GtkWindow, window), frame);

    const drawing_area: *c.GtkWidget = c.gtk_drawing_area_new();
    c.gtk_widget_set_size_request(drawing_area, 100, 100);

    c.gtk_frame_set_child(@ptrCast(*c.GtkFrame, frame), drawing_area);

    c.gtk_drawing_area_set_draw_func(
        @ptrCast(*c.GtkDrawingArea, drawing_area),
        @ptrCast(c.GtkDrawingAreaDrawFunc, draw_cb),
        null,
        null,
    );

    // using reimplementation
    _ = _g_signal_connect_after(drawing_area, "resize", @ptrCast(c.GCallback, resize_cb), null);

    const drag: ?*c.GtkGesture = c.gtk_gesture_drag_new();
    c.gtk_gesture_single_set_button(@ptrCast(*c.GtkGestureSingle, drag), c.GDK_BUTTON_PRIMARY);
    c.gtk_widget_add_controller(drawing_area, @ptrCast(*c.GtkEventController, drag));
    // using reimplementation
    _ = _g_signal_connect(drag, "drag-begin", @ptrCast(c.GCallback, drag_begin), drawing_area);
    _ = _g_signal_connect(drag, "drag-update", @ptrCast(c.GCallback, drag_update), drawing_area);
    _ = _g_signal_connect(drag, "drag-end", @ptrCast(c.GCallback, drag_end), drawing_area);

    const press: ?*c.GtkGesture = c.gtk_gesture_click_new();
    c.gtk_gesture_single_set_button(@ptrCast(*c.GtkGestureSingle, press), c.GDK_BUTTON_SECONDARY);
    c.gtk_widget_add_controller(drawing_area, @ptrCast(*c.GtkEventController, press));

    // using reimplementation
    _ = _g_signal_connect(press, "pressed", @ptrCast(c.GCallback, pressed), drawing_area);

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
