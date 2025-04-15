const std = @import("std");

const arch = @import("ecs/archetype.zig");

const Archetype = arch.Archetype;

pub const Entity = u64;

pub const World = struct {
    allocator: std.mem.Allocator,
    counter: Entity = 0,
    entities: Handles = .{},
    archetypes: Tables = .{},

    const Self = @This();
    const Tables = std.AutoHashMapUnmanaged(Archetype.Hash, Archetype);
    const Handles = std.AutoHashMapUnmanaged(Entity, Handle);

    const Handle = struct {
        hash: Archetype.Hash,
        idx: usize,
    };

    pub fn init(allocator: std.mem.Allocator) !Self {
        var self = Self{
            .allocator = allocator,
        };

        try self.archetypes.putNoClobber(
            allocator,
            Archetype.empty_hash,
            Archetype{ .hash = Archetype.empty_hash },
        );

        return self;
    }

    pub fn deinit(self: *Self) void {
        var iter = self.archetypes.valueIterator();
        while (iter.next()) |archetype| {
            archetype.deinit(self.allocator);
        }

        self.archetypes.deinit(self.allocator);
        self.entities.deinit(self.allocator);
    }

    pub fn newEntity(self: *Self) !Entity {
        const entity = self.counter;
        self.counter += 1;

        const empty_arch = self.archetypes.getEntry(Archetype.empty_hash).?.value_ptr;
        const idx = try empty_arch.allocateEntity(self.allocator, entity);
        const handle = Handle{
            .hash = Archetype.empty_hash,
            .idx = idx,
        };

        self.entities.putNoClobber(self.allocator, entity, handle) catch |err| {
            empty_arch.undoEntityAllocation();
            return err;
        };

        return entity;
    }

    pub fn archetypeById(self: *Self, entity: Entity) ?*Archetype {
        const handle = self.entities.getPtr(entity) orelse return null;
        return self.archetypes.getPtr(handle.hash);
    }

    pub fn setComponent(self: *Self, entity: Entity, component: anytype) !void {
        const T = @TypeOf(component);
        const type_name = @typeName(T);

        const archetype = self.archetypeById(entity).?;
        const old_hash = archetype.hash;
        const have_already = archetype.components.contains(type_name);
        const mask = if (have_already) 0 else std.hash_map.hashString(type_name);

        const archetype_entry = try self.archetypes.getOrPut(self.allocator, old_hash ^ mask);
        if (!archetype_entry.found_existing) {
            archetype_entry.value_ptr.* = Archetype{ .hash = 0 };
        }

        unreachable; // TODO: finish `setComponent`
    }
};
