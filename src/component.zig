const std = @import("std");
const game = @import("game.zig");

const Entity = game.Entity;

pub const ComponentStorage = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const VTable = struct {
        add: *const fn (*anyopaque, comptime type, Entity, anytype) std.mem.Allocator.Error!void,
    };

    pub fn add(self: ComponentStorage, comptime T: type, entity: Entity, object: T) !void {
        try self.vtable.add(self.ptr, T, entity, object);
    }

    pub fn impl(pointer: anytype) ComponentStorage {
        const T = @TypeOf(pointer);
        const info = @typeInfo(T);

        const gen = struct {
            fn add(ptr: *anyopaque, comptime C: type, entity: Entity, object: C) !void {
                const self: T = @ptrCast(@alignCast(ptr));
                return info.pointer.child.add(self, C, entity, object);
            }
        };

        return ComponentStorage{
            .ptr = pointer,
            .vtable = &VTable{
                .add = gen.add,
            },
        };
    }
};
