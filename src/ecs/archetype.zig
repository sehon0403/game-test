const std = @import("std");

const pools = @import("archetype/component_pool.zig");

pub const ErasedComponentPool = pools.ErasedComponentPool;
pub const ComponentPool = pools.ComponentPool;

pub const Archetype = struct {
    hash: Hash,
    components: std.StringArrayHashMapUnmanaged(ErasedComponentPool) = .{},

    pub const Hash = u16;
    pub const empty_hash: Hash = 0;
    const Self = @This();

    pub fn empty() Self {
        return Self{
            .hash = empty_hash,
        };
    }

    fn createComponentPool(comptime T: type, allocator: std.mem.Allocator, len: *usize) !ErasedComponentPool {
        const ptr = try allocator.create(ComponentPool(T));
        ptr.* = ComponentPool(T){ .len = len };
        return ptr.erased();
    }
};
