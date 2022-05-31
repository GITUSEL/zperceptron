// POSIX weak random

pub usingnamespace PosixWeakRandom;
const PosixWeakRandom = struct {
    const RAND_MAX: u32 = 0x7fffffff;
    var next: u64 = 1;

    fn do_rand(ctx: *u64) u64 {
        var hi: u64 = undefined;
        var lo: u64 = undefined;
        var x: i64 = undefined;
        // Can't be initialized with 0, so use another value.
        if (ctx.* == 0) ctx.* = 123459876;
        hi = ctx.* / 127773;
        lo = ctx.* % 127773;
        x = @intCast(i64, 16807 * lo) - @intCast(i64, 2836 * hi);
        if (x < 0) x += 0x7fffffff;
        ctx.* = @intCast(u64, x);
        return ctx.* % @intCast(u64, RAND_MAX + 1);
    }

    pub fn srand(seed: u64) void {
        next = seed;
    }

    pub fn rand() i32 {
        return @intCast(i32, do_rand(&next));
    }
};
