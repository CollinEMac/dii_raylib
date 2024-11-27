// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const std = @import("std");

const Player = struct {
    position: rl.Vector2,
    speed: f32,
    size: f32,
    
    pub fn init() Player {
        return Player{
            .position = .{ .x = 400, .y = 225 },
            .speed = 4.0,
            .size = 20,
        };
    }

    pub fn update(self: *Player) void {
        if (rl.isKeyDown(.key_right)) self.position.x += self.speed;
        if (rl.isKeyDown(.key_left)) self.position.x -= self.speed;
        if (rl.isKeyDown(.key_down)) self.position.y += self.speed;
        if (rl.isKeyDown(.key_up)) self.position.y -= self.speed;
    }

    pub fn draw(self: Player) void {
        rl.drawRectangleV(self.position, .{ .x = self.size, .y = self.size }, rl.Color.red);
    }
};

const Wall = struct {
    rect: rl.Rectangle,
    
    pub fn draw(self: Wall) void {
        rl.drawRectangleRec(self.rect, rl.Color.gray);
    }
};

fn createDungeon(rng: std.rand.Random) [50]Wall {
    var walls: [50]Wall = undefined;
    var index: usize = 0;

    // Main central room with random size
    const main_room_width = rng.float(f32) * 100.0 + 250.0; // 250-350
    const main_room_height = rng.float(f32) * 100.0 + 250.0; // 250-350
    const main_room_x = -main_room_width / 2.0;
    const main_room_y = -main_room_height / 2.0;

    walls[index] = .{ .rect = .{ .x = main_room_x, .y = main_room_y, .width = main_room_width, .height = 20.0 } }; index += 1; // Top
    walls[index] = .{ .rect = .{ .x = main_room_x, .y = main_room_y + main_room_height - 20.0, .width = main_room_width, .height = 20.0 } }; index += 1; // Bottom
    walls[index] = .{ .rect = .{ .x = main_room_x, .y = main_room_y, .width = 20.0, .height = main_room_height } }; index += 1; // Left
    walls[index] = .{ .rect = .{ .x = main_room_x + main_room_width - 20.0, .y = main_room_y, .width = 20.0, .height = main_room_height } }; index += 1; // Right

    // Random number of side rooms (2-4)
    const num_side_rooms = rng.intRangeAtMost(usize, 2, 4);
    var i: usize = 0;
    while (i < num_side_rooms and index < 45) : (i += 1) {
        const room_width = rng.float(f32) * 150.0 + 100.0; // 100-250
        const room_height = rng.float(f32) * 150.0 + 100.0; // 100-250
        const corridor_width = 80.0;
        
        // Choose a random side (0=right, 1=top, 2=left, 3=bottom)
        const side = rng.intRangeAtMost(u8, 0, 3);
        
        switch (side) {
            0 => { // Right side
                const room_x = main_room_x + main_room_width + corridor_width;
                const room_y = main_room_y + rng.float(f32) * (main_room_height - room_height);
                
                // Corridor
                walls[index] = .{ .rect = .{ .x = main_room_x + main_room_width, .y = room_y, .width = corridor_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = main_room_x + main_room_width, .y = room_y + 100.0, .width = corridor_width, .height = 20.0 } }; index += 1;
                
                // Room
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y, .width = room_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y + room_height - 20.0, .width = room_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x + room_width - 20.0, .y = room_y, .width = 20.0, .height = room_height } }; index += 1;
            },
            1 => { // Top side
                const room_x = main_room_x + rng.float(f32) * (main_room_width - room_width);
                const room_y = main_room_y - room_height - corridor_width;
                
                // Corridor
                walls[index] = .{ .rect = .{ .x = room_x, .y = main_room_y - corridor_width, .width = 20.0, .height = corridor_width } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x + 100.0, .y = main_room_y - corridor_width, .width = 20.0, .height = corridor_width } }; index += 1;
                
                // Room
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y, .width = room_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y, .width = 20.0, .height = room_height } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x + room_width - 20.0, .y = room_y, .width = 20.0, .height = room_height } }; index += 1;
            },
            2 => { // Left side
                const room_x = main_room_x - room_width - corridor_width;
                const room_y = main_room_y + rng.float(f32) * (main_room_height - room_height);
                
                // Corridor
                walls[index] = .{ .rect = .{ .x = room_x + room_width, .y = room_y, .width = corridor_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x + room_width, .y = room_y + 100.0, .width = corridor_width, .height = 20.0 } }; index += 1;
                
                // Room
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y, .width = room_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y + room_height - 20.0, .width = room_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y, .width = 20.0, .height = room_height } }; index += 1;
            },
            3 => { // Bottom side
                const room_x = main_room_x + rng.float(f32) * (main_room_width - room_width);
                const room_y = main_room_y + main_room_height + corridor_width;
                
                // Corridor
                walls[index] = .{ .rect = .{ .x = room_x, .y = main_room_y + main_room_height, .width = 20.0, .height = corridor_width } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x + 100.0, .y = main_room_y + main_room_height, .width = 20.0, .height = corridor_width } }; index += 1;
                
                // Room
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y + room_height - 20.0, .width = room_width, .height = 20.0 } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x, .y = room_y, .width = 20.0, .height = room_height } }; index += 1;
                walls[index] = .{ .rect = .{ .x = room_x + room_width - 20.0, .y = room_y, .width = 20.0, .height = room_height } }; index += 1;
            },
            else => unreachable,
        }
    }

    // Add some random internal walls in the main room
    const num_internal_walls = rng.intRangeAtMost(usize, 2, 5);
    var j: usize = 0;
    while (j < num_internal_walls and index < 48) : (j += 1) {
        const wall_length = rng.float(f32) * 100.0 + 50.0;
        const is_horizontal = rng.boolean();
        
        if (is_horizontal) {
            const x = main_room_x + rng.float(f32) * (main_room_width - wall_length);
            const y = main_room_y + rng.float(f32) * main_room_height;
            walls[index] = .{ .rect = .{ .x = x, .y = y, .width = wall_length, .height = 20.0 } };
        } else {
            const x = main_room_x + rng.float(f32) * main_room_width;
            const y = main_room_y + rng.float(f32) * (main_room_height - wall_length);
            walls[index] = .{ .rect = .{ .x = x, .y = y, .width = 20.0, .height = wall_length } };
        }
        index += 1;
    }

    // Fill remaining slots with empty walls
    while (index < walls.len) : (index += 1) {
        walls[index] = .{ .rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 } };
    }

    return walls;
}

pub fn main() anyerror!void {
    // Initialization
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "Dungeon Explorer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var player = Player.init();
    
    // Initialize camera
    var camera = rl.Camera2D{
        .offset = .{ .x = @as(f32, @floatFromInt(screenWidth)) / 2.0, .y = @as(f32, @floatFromInt(screenHeight)) / 2.0 },
        .target = player.position,
        .rotation = 0.0,
        .zoom = 1.0,
    };

    // Initialize random number generator
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rng = prng.random();
    
    // Create dungeon layout
    const walls = createDungeon(rng);

    // Add a grid size for the floor pattern
    const gridSize: f32 = 50;
    
    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        player.update();
        
        // Basic collision detection
        for (walls) |wall| {
            if (wall.rect.width == 0 and wall.rect.height == 0) continue; // Skip empty walls
            
            const playerRect = rl.Rectangle{
                .x = player.position.x,
                .y = player.position.y,
                .width = player.size,
                .height = player.size,
            };
            
            if (rl.checkCollisionRecs(playerRect, wall.rect)) {
                // Push player back if collision occurs
                if (rl.isKeyDown(.key_right)) player.position.x -= player.speed;
                if (rl.isKeyDown(.key_left)) player.position.x += player.speed;
                if (rl.isKeyDown(.key_down)) player.position.y -= player.speed;
                if (rl.isKeyDown(.key_up)) player.position.y += player.speed;
            }
        }

        // Update camera to follow player
        camera.target = player.position;

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black); // Changed to black for dungeon feel
        
        // Begin camera mode
        rl.beginMode2D(camera);
        
        // Draw floor grid (darker for dungeon atmosphere)
        const startX = @as(i32, @intFromFloat(player.position.x - 1000));
        const endX = @as(i32, @intFromFloat(player.position.x + 1000));
        const startY = @as(i32, @intFromFloat(player.position.y - 1000));
        const endY = @as(i32, @intFromFloat(player.position.y + 1000));
        
        var x: f32 = @as(f32, @floatFromInt(startX - @rem(startX, @as(i32, @intFromFloat(gridSize)))));
        while (x < @as(f32, @floatFromInt(endX))) : (x += gridSize) {
            rl.drawLineV(
                .{ .x = x, .y = @as(f32, @floatFromInt(startY)) },
                .{ .x = x, .y = @as(f32, @floatFromInt(endY)) },
                rl.Color{ .r = 30, .g = 30, .b = 30, .a = 255 },
            );
        }
        
        var y: f32 = @as(f32, @floatFromInt(startY - @rem(startY, @as(i32, @intFromFloat(gridSize)))));
        while (y < @as(f32, @floatFromInt(endY))) : (y += gridSize) {
            rl.drawLineV(
                .{ .x = @as(f32, @floatFromInt(startX)), .y = y },
                .{ .x = @as(f32, @floatFromInt(endX)), .y = y },
                rl.Color{ .r = 30, .g = 30, .b = 30, .a = 255 },
            );
        }
        
        // Draw walls
        for (walls) |wall| {
            if (wall.rect.width == 0 and wall.rect.height == 0) continue; // Skip empty walls
            wall.draw();
        }
        
        // Draw player
        player.draw();
        
        rl.endMode2D();
        
        // Draw UI (not affected by camera)
        rl.drawText("Use arrow keys to explore the dungeon", 10, 10, 20, rl.Color.gray);
    }
}
