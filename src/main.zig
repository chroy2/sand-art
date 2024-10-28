const std = @import("std");
const rand = std.crypto.random;
const rl = @cImport({
    @cInclude("raylib.h");
});

const Vec2 = @Vector(2, i16);

// Unit Vecs
const ORIGIN = Vec2{ 0, 0 };
const UNITX = Vec2{ 1, 0 };
const UNITY = Vec2{ 0, 1 };

//colors
const pixel_size = 10;
const edge_buffer = 2;

//settings
const FPS = 50;
const BRUSH_SIZE = 3;

const pixel = struct {
    position: Vec2,
    color: rl.Color,
    canvas: *canvas,
    pixel_below: bool = false,
    pixel_left: bool = false,
    pixel_right: bool = false,
    stay: bool = false,

    fn draw_self(self: *pixel) void {
        rl.DrawPixelV(vec2_to_rl(self.position), self.color);
    }

    fn update_self(self: *pixel, canvas_mh: i16, canvas_mw: i16) void {
        self.pixel_below = false;
        self.pixel_right = false;
        self.pixel_left = false;

        for (self.canvas.pixel_array.items) |p| {
            //pixel is not self
            if (self != p) {
                //pixels are on the same x
                if (self.position[0] == p.position[0]) {
                    //if pixel_below
                    if (self.position[1] + 1 == p.position[1]) {
                        self.pixel_below = true;
                    }
                }
                // x - 1
                if (self.position[0] - 1 == p.position[0]) {
                    //if pixel below (pixel_left)
                    if (self.position[1] + 1 == p.position[1]) {
                        self.pixel_left = true;
                    }
                }
                //x + 1
                if (self.position[0] + 1 == p.position[0]) {
                    //if pixel below (pixel_right)
                    if (self.position[1] + 1 == p.position[1]) {
                        self.pixel_right = true;
                    }
                }
            }
        }

        //nothing below go down
        if (self.position[1] < canvas_mh and !self.pixel_below) {
            self.position[1] += 1;
        } // else go left or right
        else {
            var rand_left = rand.boolean();
            if (rand_left and !self.stay) {
                if (self.position[0] > edge_buffer and self.position[1] < canvas_mh and !self.pixel_left) {
                    self.position[1] += 1;
                    self.position[0] -= 1;
                } else {
                    rand_left = false;
                }
            }
            if (!rand_left and !self.stay) {
                if (self.position[0] < canvas_mw - 1 and self.position[1] < canvas_mh and !self.pixel_right) {
                    self.position[1] += 1;
                    self.position[0] += 1;
                } else if (self.position[0] > edge_buffer and self.position[1] < canvas_mh and !self.pixel_left) {
                    self.position[1] += 1;
                    self.position[0] -= 1;
                }
            }
        }
    }
};

const canvas = struct {
    border_color: rl.Color,
    edge_buffer: isize,
    pixel_size: isize,
    canvas_max_height: i16,
    canvas_max_width: i16,
    pixel_array: std.ArrayList(*pixel),

    fn draw_pixel_array(self: *canvas) void {
        for (self.pixel_array.items) |p| {
            p.draw_self();
            p.update_self(self.canvas_max_height, self.canvas_max_width);
        }
    }

    fn add_pixel_to_array(self: *canvas, p: *pixel) !void {
        try self.pixel_array.append(p);
    }

    fn mouse_in_bounds(self: *canvas) bool {
        const pos = rl_to_vec2_scaled(rl.GetMousePosition());
        if (pos[0] >= self.edge_buffer and pos[0] < self.canvas_max_width and pos[1] >= self.edge_buffer and pos[1] < self.canvas_max_height) {
            return true;
        }
        return false;
    }

    fn draw_border(self: *canvas) void {
        rl.DrawLineV(
            vec2_to_rl(Vec2{ edge_buffer, edge_buffer }),
            vec2_to_rl(Vec2{ self.canvas_max_width, edge_buffer }),
            self.border_color,
        );
        rl.DrawLineV(
            vec2_to_rl(Vec2{ edge_buffer, edge_buffer }),
            vec2_to_rl(Vec2{ edge_buffer, self.canvas_max_height + 1 }),
            self.border_color,
        );
        rl.DrawLineV(
            vec2_to_rl(Vec2{ edge_buffer, self.canvas_max_height + 1 }),
            vec2_to_rl(Vec2{ self.canvas_max_width, self.canvas_max_height + 1 }),
            self.border_color,
        );
        rl.DrawLineV(
            vec2_to_rl(Vec2{ self.canvas_max_width, edge_buffer }),
            vec2_to_rl(Vec2{ self.canvas_max_width, self.canvas_max_height + 1 }),
            self.border_color,
        );
    }
};

const button = struct {
    pos: Vec2,
    size: Vec2,
    color: rl.Color,

    fn mouse_in_bounds(self: *button) bool {
        const pos = rl_to_vec2_scaled(rl.GetMousePosition());
        if (pos[0] >= self.pos[0] and pos[0] < self.pos[0] + self.size[0] and pos[1] >= self.pos[1] and pos[1] < self.pos[1] + self.size[1]) {
            return true;
        }
        return false;
    }

    fn draw_self(self: *button) void {
        rl.DrawRectangleV(vec2_to_rl(self.pos), vec2_to_rl(self.size), self.color);
    }
};

const menu = struct {
    start_pos: Vec2,
    width: i16,
    height: i16,
    buffer: i16,
    border_color: rl.Color,
    buttons: std.ArrayList(*button),

    fn draw_border(self: *menu) void {
        rl.DrawLineV(
            vec2_to_rl(self.start_pos),
            vec2_to_rl(Vec2{ self.start_pos[0] + self.width, self.start_pos[1] }),
            self.border_color,
        );
        rl.DrawLineV(
            vec2_to_rl(self.start_pos),
            vec2_to_rl(Vec2{ self.start_pos[0], self.start_pos[1] + self.height }),
            self.border_color,
        );
        rl.DrawLineV(
            vec2_to_rl(Vec2{ self.start_pos[0], self.start_pos[1] + self.height }),
            vec2_to_rl(Vec2{ self.start_pos[0] + self.width, self.start_pos[1] + self.height }),
            self.border_color,
        );
        rl.DrawLineV(
            vec2_to_rl(Vec2{ self.start_pos[0] + self.width, self.start_pos[1] }),
            vec2_to_rl(Vec2{ self.start_pos[0] + self.width, self.start_pos[1] + self.height }),
            self.border_color,
        );
    }
};

pub fn main() !void {
    const screenWidth = 480;
    const screenHeight = screenWidth * 3 / 2;
    const canvas_max_height = (screenHeight / pixel_size) - edge_buffer - 1;
    const canvas_max_width = (screenWidth / pixel_size) - edge_buffer;
    //const menu_width = 200;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    // var m = menu{
    //   .border_color = rl.Color{ .r = 236, .g = 118, .b = 37, .a = 255 },
    //   .start_pos = Vec2{ canvas_max_width, edge_buffer },
    // .width = (menu_width / pixel_size),
    //  .height = (screenHeight / pixel_size) - edge_buffer * 2,
    //  .buffer = edge_buffer,
    //.buttons = std.ArrayList(*button).init(alloc),
    //};

    //var button_test = button{
    //  .pos = Vec2{ canvas_max_width, edge_buffer },
    // .size = Vec2{ 3, 3 },
    // .color = rl.RED,
    //};

    var c = canvas{
        .border_color = rl.Color{ .r = 236, .g = 118, .b = 37, .a = 255 },
        .edge_buffer = edge_buffer,
        .pixel_size = pixel_size,
        .canvas_max_height = canvas_max_height,
        .canvas_max_width = canvas_max_width,
        .pixel_array = std.ArrayList(*pixel).init(alloc),
    };
    defer c.pixel_array.deinit();

    std.debug.print("\n{d}\n\n", .{c.canvas_max_height});

    rl.InitWindow(screenWidth, screenHeight, "Sand Art");

    defer rl.CloseWindow(); // Close window and OpenGL context

    var camera: rl.Camera2D = undefined;
    camera.zoom = pixel_size;
    camera.offset = vec2_to_rl(ORIGIN);
    camera.target = vec2_to_rl(ORIGIN);

    rl.SetTargetFPS(FPS); // Set our game to run at certain fps, controls how fast sand
    // falls

    var color_hue: f32 = 0;
    while (!rl.WindowShouldClose()) // Detect window close button or ESC key
    {
        color_hue = @mod(color_hue + 1, 300);
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);

        rl.BeginMode2D(camera);

        //left down draw pixel
        if (c.mouse_in_bounds()) {
            if (rl.IsMouseButtonDown(0)) {
                const new_pixel = try alloc.create(pixel);
                new_pixel.* = pixel{
                    .position = rl_to_vec2_scaled(rl.GetMousePosition()),
                    .color = random_sand_color(color_hue),
                    .stay = ((rand.int(u8) % 10) < 2),
                    .canvas = &c,
                };
                try c.add_pixel_to_array(new_pixel);
            }
        }

        //if (button_test.mouse_in_bounds()) {
        //  if (rl.IsMouseButtonPressed(0)) {
        //    std.debug.print("pressed in bounds", .{});
        //}
        //}

        //drawing of the canvas
        c.draw_border();
        c.draw_pixel_array();
        //m.draw_border();
        //button_test.draw_self();

        //draws axis for visual helper
        // rl.DrawLineV(vec2_to_rl(Vec2{ edge_buffer, edge_buffer }), vec2_to_rl(Vec2{ edge_buffer + 1, edge_buffer }), rl.RED);
        // rl.DrawLineV(vec2_to_rl(Vec2{ edge_buffer, edge_buffer }), vec2_to_rl(Vec2{ edge_buffer, edge_buffer + 1 }), rl.BLUE);
        // rl.DrawLineV(vec2_to_rl(Vec2{ edge_buffer, edge_buffer }), vec2_to_rl(Vec2{ edge_buffer + 1, edge_buffer + 1 }), rl.YELLOW);

        rl.EndMode2D();

        rl.EndDrawing();
    }
}

//used to convert zig vec to rl vec
pub fn vec2_to_rl(vec: Vec2) rl.Vector2 {
    return rl.Vector2{ .x = @floatFromInt(vec[0]), .y = @floatFromInt(vec[1]) };
}

pub fn rl_to_vec2_scaled(vec: rl.Vector2) Vec2 {
    const x: i16 = @intFromFloat(vec.x / pixel_size);
    const y: i16 = @intFromFloat(vec.y / pixel_size);
    return Vec2{ x, y };
}

pub fn random_sand_color(hue: f32) rl.Color {
    return rl.ColorFromHSV(hue, 1, 1);
}
