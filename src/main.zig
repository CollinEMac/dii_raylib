// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const std = @import("std");

const Player = struct {
    position: rl.Vector2,
    speed: f32,
    size: f32,
    health: f32 = 100.0,
    facingDx: f32 = 1.0,
    facingDy: f32 = 0.0,
    attackCooldown: f32 = 0.0,
    attackRange: f32 = 45.0,
    damage: f32 = 25.0,

    pub fn init() Player {
        return Player{
            .position = .{ .x = 400, .y = 225 },
            .speed = 4.0,
            .size = 20,
        };
    }

    pub fn update(self: *Player) void {
        var moved = false;

        // Store previous facing direction
        var newFacingDx = self.facingDx;
        var newFacingDy = self.facingDy;

        if (rl.isKeyDown(.key_right)) {
            self.position.x += self.speed;
            newFacingDx = 1.0;
            newFacingDy = 0.0;
            moved = true;
        }
        if (rl.isKeyDown(.key_left)) {
            self.position.x -= self.speed;
            newFacingDx = -1.0;
            newFacingDy = 0.0;
            moved = true;
        }
        if (rl.isKeyDown(.key_down)) {
            self.position.y += self.speed;
            newFacingDx = 0.0;
            newFacingDy = 1.0;
            moved = true;
        }
        if (rl.isKeyDown(.key_up)) {
            self.position.y -= self.speed;
            newFacingDx = 0.0;
            newFacingDy = -1.0;
            moved = true;
        }

        // Update facing direction only if we moved
        if (moved) {
            self.facingDx = newFacingDx;
            self.facingDy = newFacingDy;
        }

        // Update attack cooldown
        if (self.attackCooldown > 0) {
            self.attackCooldown -= rl.getFrameTime();
        }
    }

    pub fn draw(self: Player) void {
        const color = if (self.health > 0) rl.Color.red else rl.Color.gray;

        // Draw player body
        rl.drawRectangleV(self.position, .{ .x = self.size, .y = self.size }, color);

        // Draw direction indicator
        const indicatorLength = self.size;
        rl.drawLineEx(
            .{
                .x = self.position.x + self.size / 2,
                .y = self.position.y + self.size / 2,
            },
            .{
                .x = self.position.x + self.size / 2 + self.facingDx * indicatorLength,
                .y = self.position.y + self.size / 2 + self.facingDy * indicatorLength,
            },
            3.0,
            rl.Color.yellow,
        );

        // Draw health bar (offset above player)
        const healthBarWidth = 40;
        const healthBarHeight = 5;
        const healthBarOffset = 15; // Increased offset
        const healthPercentage = self.health / 100.0;

        // Draw health bar background (red)
        rl.drawRectangle(
            @as(i32, @intFromFloat(self.position.x)),
            @as(i32, @intFromFloat(self.position.y - healthBarOffset)),
            healthBarWidth,
            healthBarHeight,
            rl.Color.red,
        );

        // Draw current health (green)
        rl.drawRectangle(
            @as(i32, @intFromFloat(self.position.x)),
            @as(i32, @intFromFloat(self.position.y - healthBarOffset)),
            @as(i32, @intFromFloat(healthBarWidth * healthPercentage)),
            healthBarHeight,
            rl.Color.green,
        );
    }

    pub fn attack(self: *Player) bool {
        if (self.attackCooldown <= 0) {
            self.attackCooldown = 0.5; // Attack every 0.5 seconds
            return true;
        }
        return false;
    }
};

const Enemy = struct {
    position: rl.Vector2,
    speed: f32 = 2.0,
    size: f32 = 20.0,
    health: f32 = 50.0,
    active: bool,
    aggroRange: f32 = 200.0,
    attackRange: f32 = 45.0, // Increased from 30 to 45 to be larger than minDistance (40)
    damage: f32 = 10.0,
    attackCooldown: f32 = 0.0,

    pub fn init(x: f32, y: f32) Enemy {
        return .{
            .position = .{ .x = x, .y = y },
            .active = !(x == 0 and y == 0), // Only activate enemies at valid spawn points
        };
    }

    pub fn update(self: *Enemy, player: *Player) void {
        if (!self.active or self.health <= 0) return;

        // Update attack cooldown
        if (self.attackCooldown > 0) {
            self.attackCooldown -= rl.getFrameTime();
        }

        // Calculate distance from center of enemy to center of player
        const enemyCenterX = self.position.x + self.size / 2;
        const enemyCenterY = self.position.y + self.size / 2;
        const playerCenterX = player.position.x + player.size / 2;
        const playerCenterY = player.position.y + player.size / 2;

        const dx = playerCenterX - enemyCenterX;
        const dy = playerCenterY - enemyCenterY;
        const distanceToPlayer = std.math.sqrt(dx * dx + dy * dy);

        // Only move if player is within aggro range and alive
        if (distanceToPlayer <= self.aggroRange and player.health > 0) {
            // Normalize direction
            const moveX = if (distanceToPlayer > 0) dx / distanceToPlayer else 0;
            const moveY = if (distanceToPlayer > 0) dy / distanceToPlayer else 0;

            // Only move if we're outside attack range
            if (distanceToPlayer > self.attackRange) {
                self.position.x += moveX * self.speed;
                self.position.y += moveY * self.speed;
            }

            // Attack player if in range and cooldown is ready
            if (distanceToPlayer <= self.attackRange and self.attackCooldown <= 0) {
                // Apply damage to player
                const oldHealth = player.health;
                player.health = @max(0, player.health - self.damage);
                std.debug.print("Enemy attacking! Distance: {d}, Player health: {d} -> {d}\n", .{ distanceToPlayer, oldHealth, player.health });

                // Reset attack cooldown
                self.attackCooldown = 1.0;
            }
        }
    }

    pub fn draw(self: Enemy) void {
        if (!self.active or self.health <= 0) return;

        // Draw enemy body
        rl.drawRectangleV(self.position, .{ .x = self.size, .y = self.size }, rl.Color.purple);

        // Draw health bar (offset above enemy)
        const healthBarWidth = 40;
        const healthBarHeight = 5;
        const healthBarOffset = 15;
        const healthPercentage = self.health / 50.0;

        // Draw health bar background (red)
        rl.drawRectangle(
            @as(i32, @intFromFloat(self.position.x)),
            @as(i32, @intFromFloat(self.position.y - healthBarOffset)),
            healthBarWidth,
            healthBarHeight,
            rl.Color.red,
        );

        // Draw current health (green)
        rl.drawRectangle(
            @as(i32, @intFromFloat(self.position.x)),
            @as(i32, @intFromFloat(self.position.y - healthBarOffset)),
            @as(i32, @intFromFloat(healthBarWidth * healthPercentage)),
            healthBarHeight,
            rl.Color.green,
        );
    }

    pub fn takeDamage(self: *Enemy, damage: f32) void {
        if (self.active and self.health > 0) {
            const newHealth = @max(0, self.health - damage);
            std.debug.print("Enemy taking damage! Health: {d} -> {d}\n", .{ self.health, newHealth });
            self.health = newHealth;
            if (self.health <= 0) {
                self.active = false;
            }
        }
    }
};

const Room = struct {
    rect: rl.Rectangle,
    exits: [4]bool = [_]bool{false} ** 4, // top, right, bottom, left
    hasEnemies: bool = false,
};

const Wall = struct {
    rect: rl.Rectangle,

    pub fn draw(self: Wall) void {
        rl.drawRectangleRec(self.rect, rl.Color.gray);
    }
};

fn createDungeon(rng: std.rand.Random) struct { walls: [50]Wall, spawnPoint: rl.Vector2, enemySpawns: [10]rl.Vector2 } {
    var walls: [50]Wall = undefined;
    var index: usize = 0;
    var enemySpawnIndex: usize = 0;
    var enemySpawns: [10]rl.Vector2 = undefined;
    
    // Create starting room (where player spawns)
    const startRoom = Room{
        .rect = .{
            .x = 0,
            .y = 0,
            .width = 200,
            .height = 200,
        },
    };
    
    // Create the starting room walls
    var hasExit = [_]bool{false} ** 4;
    
    // Ensure at least one exit by forcing a random direction
    const forcedExit = rng.intRangeAtMost(usize, 0, 3);
    hasExit[forcedExit] = true;
    
    // Randomly add more exits
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        if (i != forcedExit) {
            hasExit[i] = rng.float(f32) < 0.5;
        }
    }

    // Top wall
    if (!hasExit[0]) { // If no top exit, create full wall
        walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = startRoom.rect.y, .width = startRoom.rect.width, .height = 20.0 } };
        index += 1;
    }
    // Right wall
    if (!hasExit[1]) { // If no right exit, create full wall
        walls[index] = .{ .rect = .{ .x = startRoom.rect.x + startRoom.rect.width - 20.0, .y = startRoom.rect.y, .width = 20.0, .height = startRoom.rect.height } };
        index += 1;
    }
    // Bottom wall
    if (!hasExit[2]) { // If no bottom exit, create full wall
        walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = startRoom.rect.y + startRoom.rect.height - 20.0, .width = startRoom.rect.width, .height = 20.0 } };
        index += 1;
    }
    // Left wall
    if (!hasExit[3]) { // If no left exit, create full wall
        walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = startRoom.rect.y, .width = 20.0, .height = startRoom.rect.height } };
        index += 1;
    }

    // Create exits and connected rooms based on hasExit array
    i = 0;
    while (i < 4) : (i += 1) {
        if (!hasExit[i]) continue;
        
        switch (i) {
            0 => { // Top
                // Remove part of the wall for the exit
                const exitX = startRoom.rect.x + rng.float(f32) * (startRoom.rect.width - 80.0) + 20.0;
                walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = startRoom.rect.y, .width = exitX - startRoom.rect.x, .height = 20.0 } };
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX + 80.0, .y = startRoom.rect.y, .width = startRoom.rect.x + startRoom.rect.width - (exitX + 80.0), .height = 20.0 } };
                index += 1;
                
                // Create corridor walls
                const corridorY = startRoom.rect.y - 100.0;
                walls[index] = .{ .rect = .{ .x = exitX, .y = corridorY, .width = 20.0, .height = 100.0 } }; // Left corridor wall
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX + 80.0 - 20.0, .y = corridorY, .width = 20.0, .height = 100.0 } }; // Right corridor wall
                index += 1;
                
                // Create new room
                const newRoomY = startRoom.rect.y - 180.0 - 100.0;
                // Room walls
                walls[index] = .{ .rect = .{ .x = exitX - 20.0, .y = newRoomY, .width = 80.0 + 40.0, .height = 20.0 } }; // Top
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX - 20.0, .y = newRoomY, .width = 20.0, .height = 180.0 } }; // Left
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX + 80.0, .y = newRoomY, .width = 20.0, .height = 180.0 } }; // Right
                index += 1;
                
                // Add enemy spawn point in the new room
                if (enemySpawnIndex < enemySpawns.len) {
                    enemySpawns[enemySpawnIndex] = .{
                        .x = exitX + 80.0 / 2,
                        .y = newRoomY + 180.0 / 2,
                    };
                    enemySpawnIndex += 1;
                }
            },
            1 => { // Right
                const exitY = startRoom.rect.y + rng.float(f32) * (startRoom.rect.height - 80.0) + 20.0;
                walls[index] = .{ .rect = .{ .x = startRoom.rect.x + startRoom.rect.width - 20.0, .y = startRoom.rect.y, .width = 20.0, .height = exitY - startRoom.rect.y } };
                index += 1;
                walls[index] = .{ .rect = .{ .x = startRoom.rect.x + startRoom.rect.width - 20.0, .y = exitY + 80.0, .width = 20.0, .height = startRoom.rect.y + startRoom.rect.height - (exitY + 80.0) } };
                index += 1;
                
                // Create corridor walls
                const corridorX = startRoom.rect.x + startRoom.rect.width;
                walls[index] = .{ .rect = .{ .x = corridorX, .y = exitY, .width = 100.0, .height = 20.0 } }; // Top corridor wall
                index += 1;
                walls[index] = .{ .rect = .{ .x = corridorX, .y = exitY + 80.0 - 20.0, .width = 100.0, .height = 20.0 } }; // Bottom corridor wall
                index += 1;
                
                // Create new room
                const newRoomX = startRoom.rect.x + startRoom.rect.width + 100.0;
                walls[index] = .{ .rect = .{ .x = newRoomX, .y = exitY - 20.0, .width = 180.0, .height = 20.0 } }; // Top
                index += 1;
                walls[index] = .{ .rect = .{ .x = newRoomX, .y = exitY + 80.0, .width = 180.0, .height = 20.0 } }; // Bottom
                index += 1;
                walls[index] = .{ .rect = .{ .x = newRoomX + 180.0 - 20.0, .y = exitY - 20.0, .width = 20.0, .height = 80.0 + 40.0 } }; // Right
                index += 1;
                
                if (enemySpawnIndex < enemySpawns.len) {
                    enemySpawns[enemySpawnIndex] = .{
                        .x = newRoomX + 180.0 / 2,
                        .y = exitY + 80.0 / 2,
                    };
                    enemySpawnIndex += 1;
                }
            },
            2 => { // Bottom
                const exitX = startRoom.rect.x + rng.float(f32) * (startRoom.rect.width - 80.0) + 20.0;
                walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = startRoom.rect.y + startRoom.rect.height - 20.0, .width = exitX - startRoom.rect.x, .height = 20.0 } };
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX + 80.0, .y = startRoom.rect.y + startRoom.rect.height - 20.0, .width = startRoom.rect.x + startRoom.rect.width - (exitX + 80.0), .height = 20.0 } };
                index += 1;
                
                // Create corridor walls
                const corridorY = startRoom.rect.y + startRoom.rect.height;
                walls[index] = .{ .rect = .{ .x = exitX, .y = corridorY, .width = 20.0, .height = 100.0 } }; // Left corridor wall
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX + 80.0 - 20.0, .y = corridorY, .width = 20.0, .height = 100.0 } }; // Right corridor wall
                index += 1;
                
                // Create new room
                const newRoomY = startRoom.rect.y + startRoom.rect.height + 100.0;
                walls[index] = .{ .rect = .{ .x = exitX - 20.0, .y = newRoomY + 180.0 - 20.0, .width = 80.0 + 40.0, .height = 20.0 } }; // Bottom
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX - 20.0, .y = newRoomY, .width = 20.0, .height = 180.0 } }; // Left
                index += 1;
                walls[index] = .{ .rect = .{ .x = exitX + 80.0, .y = newRoomY, .width = 20.0, .height = 180.0 } }; // Right
                index += 1;
                
                if (enemySpawnIndex < enemySpawns.len) {
                    enemySpawns[enemySpawnIndex] = .{
                        .x = exitX + 80.0 / 2,
                        .y = newRoomY + 180.0 / 2,
                    };
                    enemySpawnIndex += 1;
                }
            },
            3 => { // Left
                const exitY = startRoom.rect.y + rng.float(f32) * (startRoom.rect.height - 80.0) + 20.0;
                walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = startRoom.rect.y, .width = 20.0, .height = exitY - startRoom.rect.y } };
                index += 1;
                walls[index] = .{ .rect = .{ .x = startRoom.rect.x, .y = exitY + 80.0, .width = 20.0, .height = startRoom.rect.y + startRoom.rect.height - (exitY + 80.0) } };
                index += 1;
                
                // Create corridor walls
                const corridorX = startRoom.rect.x - 100.0;
                walls[index] = .{ .rect = .{ .x = corridorX, .y = exitY, .width = 100.0, .height = 20.0 } }; // Top corridor wall
                index += 1;
                walls[index] = .{ .rect = .{ .x = corridorX, .y = exitY + 80.0 - 20.0, .width = 100.0, .height = 20.0 } }; // Bottom corridor wall
                index += 1;
                
                // Create new room
                const newRoomX = startRoom.rect.x - 180.0 - 100.0;
                walls[index] = .{ .rect = .{ .x = newRoomX, .y = exitY - 20.0, .width = 180.0, .height = 20.0 } }; // Top
                index += 1;
                walls[index] = .{ .rect = .{ .x = newRoomX, .y = exitY + 80.0, .width = 180.0, .height = 20.0 } }; // Bottom
                index += 1;
                walls[index] = .{ .rect = .{ .x = newRoomX, .y = exitY - 20.0, .width = 20.0, .height = 80.0 + 40.0 } }; // Left
                index += 1;
                
                if (enemySpawnIndex < enemySpawns.len) {
                    enemySpawns[enemySpawnIndex] = .{
                        .x = newRoomX + 180.0 / 2,
                        .y = exitY + 80.0 / 2,
                    };
                    enemySpawnIndex += 1;
                }
            },
            else => unreachable,
        }
    }

    // Fill remaining enemy spawn points with (0,0) if not all were used
    while (enemySpawnIndex < enemySpawns.len) : (enemySpawnIndex += 1) {
        enemySpawns[enemySpawnIndex] = .{ .x = 0, .y = 0 };
    }

    // Fill remaining walls with empty rectangles
    while (index < walls.len) : (index += 1) {
        walls[index] = .{ .rect = .{ .x = 0, .y = 0, .width = 0, .height = 0 } };
    }

    return .{
        .walls = walls,
        .spawnPoint = .{ .x = startRoom.rect.x + startRoom.rect.width / 2, .y = startRoom.rect.y + startRoom.rect.height / 2 },
        .enemySpawns = enemySpawns,
    };
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
    const dungeon = createDungeon(rng);
    const walls = dungeon.walls;
    const spawnPoint = dungeon.spawnPoint;
    const enemySpawns = dungeon.enemySpawns;

    // Create enemies
    var enemies: [10]Enemy = undefined;
    for (0..10) |i| {
        enemies[i] = Enemy.init(
            enemySpawns[i].x,
            enemySpawns[i].y,
        );
    }

    // Add a grid size for the floor pattern
    const gridSize: f32 = 50;

    // Set player spawn point
    player.position = spawnPoint;

    // Main game loop
    while (!rl.windowShouldClose()) {
        // Update
        player.update();

        // Basic collision detection with walls
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

        // Collision detection between player and enemies
        for (&enemies) |*enemy| {
            if (!enemy.active or enemy.health <= 0) continue;

            const dx = enemy.position.x - player.position.x;
            const dy = enemy.position.y - player.position.y;
            const distance = std.math.sqrt(dx * dx + dy * dy);

            // If too close, push both apart
            const minDistance = player.size + enemy.size;
            if (distance < minDistance) {
                const pushDistance = (minDistance - distance) / 2;
                const pushX = if (distance > 0) dx / distance * pushDistance else 0;
                const pushY = if (distance > 0) dy / distance * pushDistance else 0;

                // Push enemy away
                enemy.position.x += pushX;
                enemy.position.y += pushY;

                // Push player away
                player.position.x -= pushX;
                player.position.y -= pushY;
            }
        }

        // Update camera to follow player
        camera.target = player.position;

        // Update enemies
        for (&enemies) |*enemy| {
            enemy.update(&player);
        }

        // Handle combat
        if (rl.isKeyPressed(.key_space)) {
            if (player.attack()) {
                // Check each enemy for hits within an arc in front of the player
                for (&enemies) |*enemy| {
                    if (!enemy.active or enemy.health <= 0) continue;

                    const enemyDx = enemy.position.x - player.position.x;
                    const enemyDy = enemy.position.y - player.position.y;
                    const distanceToEnemy = std.math.sqrt(enemyDx * enemyDx + enemyDy * enemyDy);

                    if (distanceToEnemy <= player.attackRange) {
                        // Normalize the direction to the enemy
                        const normEnemyDx = enemyDx / distanceToEnemy;
                        const normEnemyDy = enemyDy / distanceToEnemy;

                        // Calculate dot product to check if enemy is in front of attack direction
                        const dotProduct = player.facingDx * normEnemyDx + player.facingDy * normEnemyDy;

                        // If dot product > 0.5, enemy is within roughly 90 degree arc of attack direction
                        if (dotProduct > 0.5) {
                            enemy.takeDamage(player.damage);
                        }
                    }
                }
            }
        }

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

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
            if (wall.rect.width == 0 and wall.rect.height == 0) continue;
            wall.draw();
        }

        // Draw enemies
        for (enemies) |enemy| {
            enemy.draw();
        }

        // Draw player
        player.draw();

        rl.endMode2D();

        // Draw game over message if player is dead
        if (player.health <= 0) {
            const text = "GAME OVER";
            const fontSize = 60;
            const textWidth = rl.measureText(text, fontSize);
            const currentScreenWidth = rl.getScreenWidth();
            const currentScreenHeight = rl.getScreenHeight();

            rl.drawText(
                text,
                @divTrunc(currentScreenWidth - textWidth, 2),
                @divTrunc(currentScreenHeight - fontSize, 2),
                fontSize,
                rl.Color.red,
            );

            const subText = "Press R to restart";
            const subFontSize = 20;
            const subTextWidth = rl.measureText(subText, subFontSize);
            rl.drawText(
                subText,
                @divTrunc(currentScreenWidth - subTextWidth, 2),
                @divTrunc(currentScreenHeight - fontSize, 2) + fontSize + 10,
                subFontSize,
                rl.Color.white,
            );
        }

        // Draw UI
        rl.drawText("WASD to move, SPACE to attack", 10, 10, 20, rl.Color.gray);
        rl.drawText(
            "Health: ",
            10,
            35,
            20,
            rl.Color.white,
        );
        rl.drawRectangle(90, 35, @as(i32, @intFromFloat(player.health)), 20, rl.Color.green);
    }
}
