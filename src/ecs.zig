const std = @import("std");

const arch = @import("ecs/archetype.zig");

pub const Entity = u64;

// // A simple assumption for the structure of an ECS could be using:
// pub const BadWorld = std.MultiArrayList(struct { Entity, ... });
// // This technically works, but there is a major flaw:
// // Iteration over all of the entries is very slow (bad for games)

// How can we fix this?
// Split every different combination of components into separate "tables" / archetypes.
// We don't know these at comptime, however.
// So we use hashmaps.
pub const World = struct {
    allocator: std.mem.Allocator,
    counter: Entity = 0,
    entities: std.AutoArrayHashMapUnmanaged(Entity, void),
    archetypes: Tables = .{},

    const Self = @This();
    const Tables = std.AutoHashMapUnmanaged(arch.Archetype.Hash, arch.Archetype);

    pub fn init(allocator: std.mem.Allocator) !Self {
        var self = Self{
            .allocator = allocator,
        };

        try self.archetypes.putNoClobber(
            allocator,
            arch.Archetype.empty_hash,
            arch.Archetype.empty(),
        );
    }

    fn newEntity(self: *Self) !void {
        if (self.entities.entries.len == std.math.maxInt(Entity)) return error.TooManyEntities;
        while (self.entities.getEntry(self.counter) != null) self.counter += 1;
        try self.entities.putNoClobber(self.allocator, self.counter, {});
    }
};
