const std = @import("std");

const ComponentStorage = @import("component.zig").ComponentStorage;

pub const Game = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayList(Entity),
    components: std.ArrayList(ComponentStorage),

    pub fn newEntity(self: *Game, components: anytype) !void {
        _ = self;
        _ = components;
    }
};

pub const Entity = struct {
    idx: usize,
};

var game_instance: ?Game = null;

pub fn game() Game {
    if (game_instance == null) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        game_instance = Game{
            .allocator = gpa.allocator(),
            .entities = std.ArrayList(Entity).init(gpa.allocator()),
        };
    }

    return game_instance.?;
}
