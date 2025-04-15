const std = @import("std");

const ecs = @import("../ecs.zig");
const pools = @import("archetype/component_pool.zig");

pub const ErasedComponentPool = pools.ErasedComponentPool;
pub const ComponentPool = pools.ComponentPool;

pub const Archetype = struct {
    hash: Hash,
    entities: std.ArrayListUnmanaged(ecs.Entity) = .{},
    components: std.StringArrayHashMapUnmanaged(ErasedComponentPool) = .{},

    pub const Hash = u16;
    pub const empty_hash: Hash = 0;
    const Self = @This();

    pub fn allocateEntity(self: *Self, allocator: std.mem.Allocator, entity: ecs.Entity) !usize {
        const row_idx = self.entities.items.len;
        try self.entities.append(allocator, entity);
        return row_idx;
    }

    pub fn undoEntityAllocation(self: *Self) void {
        _ = self.entities.pop();
    }

    pub fn remove(self: *Self, row: usize) !void {
        _ = self.entities.swapRemove(row);
        for (self.components.values()) |component_pool| {
            component_pool.remove(row);
        }
    }

    pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
        for (self.components.values()) |component_pool| {
            component_pool.deinit(allocator);
        }

        self.components.deinit(allocator);
        self.entities.deinit(allocator);
    }

    fn createComponentPool(comptime T: type, allocator: std.mem.Allocator, len: *usize) !ErasedComponentPool {
        const ptr = try allocator.create(ComponentPool(T));
        ptr.* = ComponentPool(T){ .len = len };
        return ptr.erased();
    }
};
