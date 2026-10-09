const std = @import("std");
const builtin = @import("builtin");

pub fn main(init: std.process.Init) !void {
    std.testing.io_instance = .init_single_threaded;

    var status: u8 = 0;
    const clock: std.Io.Clock = .awake;
    for (builtin.test_functions) |t| {
        const start = clock.now(init.io);
        std.testing.allocator_instance = .init(std.heap.page_allocator, .{});
        const result = t.func();
        const leaked = std.testing.allocator_instance.deinit() != 0;
        const end = clock.now(init.io);
        const elapsed = start.durationTo(end);
        const name = t.name[5..];
        if (leaked) status += 1;
        if (result) |_| {
            std.log.scoped(.PASS).info("{s} ({f})", .{ name, elapsed });
        } else |err| switch (err) {
            error.SkipZigTest => {
                std.log.scoped(.SKIP).info("{s}", .{
                    name,
                });
            },
            else => {
                status += 1;
                std.log.scoped(.FAIL).info("{s} - {t}", .{ name, err });
            },
        }
    }
    std.process.exit(status);
}
