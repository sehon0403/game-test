const std = @import("std");

pub const ErasedComponentPool = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    const Self = @This();

    const VTable = struct {
        deinit: *const fn (*anyopaque, std.mem.Allocator) void,
        cloneType: *const fn (Self, std.mem.Allocator, usize, *Self) error{OutOfMemory}!void,
        copy: *const fn (*anyopaque, std.mem.Allocator, usize, usize, *anyopaque) error{OutOfMemory}!void,
        remove: *const fn (*anyopaque, usize) void,
    };

    pub fn deinit(self: Self, allocator: std.mem.Allocator) void {
        self.vtable.deinit(self.ptr, allocator);
    }

    pub fn cloneType(self: Self, allocator: std.mem.Allocator, total_rows: usize, ret: *Self) !void {
        return self.vtable.cloneType(self, allocator, total_rows, ret);
    }

    pub fn copy(dst: Self, allocator: std.mem.Allocator, dst_row: usize, src_row: usize, src: Self) !void {
        dst.vtable.copy(dst.ptr, allocator, dst_row, src_row, src.ptr);
    }

    pub fn remove(self: Self, row: usize) void {
        self.vtable.remove(self.ptr, row);
    }

    pub fn unsafeCast(self: Self, comptime T: type) *ComponentPool(T) {
        return @ptrCast(@alignCast(self.ptr));
    }
};

pub fn ComponentPool(comptime T: type) type {
    return struct {
        data: std.ArrayListUnmanaged(T) = .{},
        len: usize,

        const Self = @This();

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.data.deinit(allocator);
        }

        fn cloneType(
            erased_pool: ErasedComponentPool,
            allocator: std.mem.Allocator,
            len: usize,
            ret: *ErasedComponentPool,
        ) !void {
            const ptr = try allocator.create(Self);
            ptr.* = Self{ .len = len };
            var tmp = erased_pool;
            tmp.ptr = ptr;
            ret.* = tmp;
        }

        pub fn erased(self: *Self) ErasedComponentPool {
            return ErasedComponentPool{
                .ptr = self,
                .vtable = &ErasedComponentPool.VTable{
                    .deinit = Self.deinit,
                    .cloneType = Self.cloneType,
                    .copy = Self.copy,
                    .remove = Self.remove,
                },
            };
        }

        pub fn remove(self: *Self, row_idx: usize) void {
            if (row_idx < self.data.items.len)
                _ = self.entities.swapRemove(row_idx);
        }

        pub inline fn copy(
            dst: *Self,
            allocator: std.mem.Allocator,
            dst_row: usize,
            src_row: usize,
            src: *Self,
        ) !void {
            try dst.set(allocator, dst_row, src.getUnchecked(src_row));
        }

        pub inline fn getUnchecked(self: *Self, row_idx: usize) T {
            return self.data.items[row_idx];
        }

        pub fn get(self: *Self, row_idx: usize) ?T {
            if (row_idx >= self.data.items.len) return null;
            return self.data.items[row_idx];
        }
    };
}
