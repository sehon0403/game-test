const std = @import("std");

pub const Entity = u64;

pub const World = struct {
    allocator: std.mem.Allocator,
    entities: std.ArrayListUnmanaged(Entity) = .{},

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }
};
