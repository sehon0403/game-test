const std = @import("std");

const ecs = @import("ecs.zig");

test {
    const allocator = std.testing.allocator;

    var world = try ecs.World.init(allocator);
    defer world.deinit();

    const entity = try world.newEntity();
    _ = entity;
}
