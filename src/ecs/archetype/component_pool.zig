const std = @import("std");

pub const ErasedComponentPool = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const Self = @This();

    const VTable = struct {
        deinit: *const fn (*anyopaque, std.mem.Allocator) void,
    };

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.ptr, allocator);
    }

    pub fn unsafeCast(self: Self, comptime T: type) *ComponentPool(T) {
        return @ptrCast(@alignCast(self.ptr));
    }
};

pub fn ComponentPool(comptime T: type) type {
    return struct {
        data: std.ArrayListUnmanaged(T) = .{},
        len: *usize,

        const Self = @This();

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.data.deinit(allocator);
        }

        pub fn erased(self: *Self) ErasedComponentPool {
            return ErasedComponentPool{
                .ptr = self,
                .vtable = &ErasedComponentPool.VTable{
                    .deinit = self.deinit,
                },
            };
        }
    };
}
