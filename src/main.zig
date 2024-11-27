// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");

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

pub fn main() anyerror!void {
    // Initialization
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "2D Top-Down RPG");
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
    
    // Create some walls for collision
    const walls = [_]Wall{
        .{ .rect = .{ .x = 100, .y = 100, .width = 40, .height = 300 } },
        .{ .rect = .{ .x = 500, .y = 50, .width = 40, .height = 300 } },
        .{ .rect = .{ .x = 300, .y = 300, .width = 200, .height = 40 } },
        // Add more walls to make the world bigger
        .{ .rect = .{ .x = -200, .y = -200, .width = 40, .height = 400 } },
        .{ .rect = .{ .x = 800, .y = -100, .width = 40, .height = 300 } },
        .{ .rect = .{ .x = -300, .y = 400, .width = 400, .height = 40 } },
        .{ .rect = .{ .x = 600, .y = -300, .width = 40, .height = 200 } },
    };

    // Add a grid size for the floor pattern
    const gridSize: f32 = 50;
    
    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        player.update();
        
        // Basic collision detection
        for (walls) |wall| {
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

        rl.clearBackground(rl.Color.ray_white);
        
        // Begin camera mode
        rl.beginMode2D(camera);
        
        // Draw floor grid
        const startX = @as(i32, @intFromFloat(player.position.x - 1000));
        const endX = @as(i32, @intFromFloat(player.position.x + 1000));
        const startY = @as(i32, @intFromFloat(player.position.y - 1000));
        const endY = @as(i32, @intFromFloat(player.position.y + 1000));
        
        var x: f32 = @as(f32, @floatFromInt(startX - @rem(startX, @as(i32, @intFromFloat(gridSize)))));
        while (x < @as(f32, @floatFromInt(endX))) : (x += gridSize) {
            rl.drawLineV(
                .{ .x = x, .y = @as(f32, @floatFromInt(startY)) },
                .{ .x = x, .y = @as(f32, @floatFromInt(endY)) },
                rl.Color{ .r = 200, .g = 200, .b = 200, .a = 100 },
            );
        }
        
        var y: f32 = @as(f32, @floatFromInt(startY - @rem(startY, @as(i32, @intFromFloat(gridSize)))));
        while (y < @as(f32, @floatFromInt(endY))) : (y += gridSize) {
            rl.drawLineV(
                .{ .x = @as(f32, @floatFromInt(startX)), .y = y },
                .{ .x = @as(f32, @floatFromInt(endX)), .y = y },
                rl.Color{ .r = 200, .g = 200, .b = 200, .a = 100 },
            );
        }
        
        // Draw walls
        for (walls) |wall| {
            wall.draw();
        }
        
        // Draw player
        player.draw();
        
        rl.endMode2D();
        
        // Draw UI (not affected by camera)
        rl.drawText("Use arrow keys to move", 10, 10, 20, rl.Color.dark_gray);
    }
}
