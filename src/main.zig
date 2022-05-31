// main file

const std = @import("std");
const fmt = std.fmt;
const bufferedWriter = std.io.bufferedWriter;
const stdout_print = std.io.getStdOut().writer().print;
const stderr_print = std.io.getStdErr().writer().print;
const assert = std.debug.assert;
const todo = std.debug.todo;
const mem = std.mem;
const zeroes = mem.zeroes;
const File = std.fs.File;
const Dir = std.fs.Dir;
const cwd = std.fs.cwd();
const math = std.math;
const floor = math.floor;
const posix_rand = @import("posix_rand.zig");

const config = @import("config.zig");

// Layer type
const Layer = [config.HEIGHT][config.WIDTH]f32;

inline fn print_out(comptime format: []const u8, args: anytype) void {
    stdout_print(format, args) catch {};
}

inline fn print_err(comptime format: []const u8, args: anytype) void {
    stderr_print(format, args) catch {};
}

inline fn clampi(arg_x: i32, arg_low: i32, arg_high: i32) i32 {
    var result: i32 = arg_x;
    if (arg_x < arg_low) result = arg_low;
    if (arg_x > arg_high) result = arg_high;
    return result;
}

fn layerFillRectangle(arg_layer: *Layer, arg_x: i32, arg_y: i32, arg_w: i32, arg_h: i32, arg_value: f32) void {
    assert(arg_w > 0);
    assert(arg_h > 0);
    const x0: i32 = clampi(arg_x, 0, config.WIDTH - 1);
    const y0: i32 = clampi(arg_y, 0, config.HEIGHT - 1);
    const x1: i32 = clampi(x0 + arg_w - 1, 0, config.WIDTH - 1);
    const y1: i32 = clampi(y0 + arg_h - 1, 0, config.HEIGHT - 1);

    var y: i32 = y0;
    while (y <= y1) : (y += 1) {
        var x: i32 = x0;
        while (x <= x1) : (x += 1) {
            arg_layer[@intCast(usize, y)][@intCast(usize, x)] = arg_value;
        }
    }
}

fn layerFillCircle(arg_layer: *Layer, arg_cx: i32, arg_cy: i32, arg_r: i32, arg_value: f32) void {
    assert(arg_r > 0);
    const x0: i32 = clampi(arg_cx - arg_r, 0, config.WIDTH - 1);
    const y0: i32 = clampi(arg_cy - arg_r, 0, config.HEIGHT - 1);
    const x1: i32 = clampi(arg_cx + arg_r, 0, config.WIDTH - 1);
    const y1: i32 = clampi(arg_cy + arg_r, 0, config.HEIGHT - 1);

    var y: i32 = y0;
    while (y <= y1) : (y += 1) {
        var x: i32 = x0;
        while (x <= x1) : (x += 1) {
            const dx: i32 = x - arg_cx;
            const dy: i32 = y - arg_cy;
            if (dx * dx + dy * dy <= arg_r * arg_r) {
                arg_layer[@intCast(usize, y)][@intCast(usize, x)] = arg_value;
            }
        }
    }
}

fn saveLayerAsPpm(arg_layer: Layer, arg_file_path: []const u8) void {
    const file: File = cwd.createFile(arg_file_path, .{}) catch |err| {
        print_err("ERROR: could not create file {s} : {}\n", .{ arg_file_path, err });
        return;
    };
    defer file.close();

    const writer = file.writer();
    writer.print("P6\n{d} {d} 255\n", .{ config.WIDTH * config.PPM_SCALER, config.HEIGHT * config.PPM_SCALER }) catch |err| {
        print_err("ERROR: could not write to file {s} : {}\n", .{ arg_file_path, err });
        return;
    };

    var buffered_writer = bufferedWriter(writer);
    var file_writer = buffered_writer.writer();

    var y: i32 = 0;
    while (y < config.HEIGHT * config.PPM_SCALER) : (y += 1) {
        var x: i32 = 0;
        while (x < config.WIDTH * config.PPM_SCALER) : (x += 1) {
            const s: f32 = (arg_layer[@intCast(usize, @divFloor(y, config.PPM_SCALER))][@intCast(usize, @divFloor(x, config.PPM_SCALER))] + config.PPM_RANGE) / (2.0 * config.PPM_RANGE);
            {
                @setRuntimeSafety(false); // unsafe cast below
                const pixels: [3]u8 = [_]u8{ @intCast(u8, @floatToInt(i32, floor(@intToFloat(f32, config.PPM_COLOR_INTENSITY) * (1.0 - s)))), @intCast(u8, @floatToInt(i32, floor(@intToFloat(f32, config.PPM_COLOR_INTENSITY) * (1.0 - s)))), @intCast(u8, @floatToInt(i32, floor(@intToFloat(f32, config.PPM_COLOR_INTENSITY) * s))) };

                file_writer.writeAll(pixels[0..]) catch |err| {
                    print_err("ERROR: could not write pixel data to buffer: {}\n", .{ err });
                    return;
                };
            }
        }
    }
    buffered_writer.flush() catch |err| {
       print_err("ERROR: could not write buffered pixel data to file {s} : {}\n", .{ arg_file_path, err });
       return;
   };
}

fn saveLayerAsBin(arg_layer: Layer, arg_file_path: []const u8) void {
    const file: File = cwd.createFile(arg_file_path, .{}) catch |err| {
        print_err("ERROR: could not create file {s} : {}\n", .{ arg_file_path, err });
        return;
    };
    defer file.close();
    const writer = file.writer();

    writer.writeAll(mem.asBytes(&arg_layer)) catch |err| {
        print_err("ERROR: could not write layer data to file {s} : {}\n", .{ arg_file_path, err });
        return;
    };
}

fn loadLayerAsBin(arg_layer: *Layer, arg_file_path: []const u8) void {
    _ = arg_layer;
    _ = arg_file_path;
    todo("TODO: layer_load_from_bin is not implemented yet!");
}

fn feedForward(arg_inputs: Layer, arg_weights: Layer) f32 {
    var output: f32 = 0.0;

    var y: usize = 0;
    while (y < config.HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < config.WIDTH) : (x += 1) {
            output += arg_inputs[y][x] * arg_weights[y][x];
        }
    }

    return output;
}

fn addInputsToWeights(arg_inputs: Layer, arg_weights: *Layer) void {
    var y: usize = 0;
    while (y < config.HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < config.WIDTH) : (x += 1) {
            arg_weights[y][x] += arg_inputs[y][x];
        }
    }
}

fn subInputsFromWeights(arg_inputs: Layer, arg_weights: *Layer) void {
    var y: usize = 0;
    while (y < config.HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < config.WIDTH) : (x += 1) {
            arg_weights[y][x] -= arg_inputs[y][x];
        }
    }
}

fn randRange(arg_low: i32, arg_high: i32) i32 {
    assert(arg_low < arg_high);
    return @mod(posix_rand.rand(), (arg_high - arg_low)) + arg_low;
}

fn randomRectLayer(arg_layer: *Layer) void {
    layerFillRectangle(arg_layer, 0, 0, config.WIDTH, config.HEIGHT, 0.0);
    const x: i32 = randRange(0, config.WIDTH);
    const y: i32 = randRange(0, config.HEIGHT);

    var w: i32 = config.WIDTH - x;
    if (w < 2) w = 2;
    w = randRange(1, w);

    var h: i32 = config.HEIGHT - y;
    if (h < 2) h = 2;
    h = randRange(1, h);

    layerFillRectangle(arg_layer, x, y, w, h, 1.0);
}

fn randomCircleLayer(arg_layer: *Layer) void {
    layerFillRectangle(arg_layer, 0, 0, config.WIDTH, config.HEIGHT, 0.0);
    const cx: i32 = randRange(0, config.WIDTH);
    const cy: i32 = randRange(0, config.HEIGHT);
    var r: i32 = config.INT_MAX;
    if (r > cx) r = cx;
    if (r > cy) r = cy;
    if (r > config.WIDTH - cx) r = config.WIDTH - cx;
    if (r > config.HEIGHT - cy) r = config.HEIGHT - cy;
    if (r < 2) r = 2;
    r = randRange(1, r);
    layerFillCircle(arg_layer, cx, cy, r, 1.0);
}

fn trainPass(arg_inputs: *Layer, arg_weights: *Layer) i32 {
    var adjusted: i32 = 0;

    // static variables
    const Static = struct {
        var file_path: [256]u8 = undefined;
        var count: u32 = 0;
    };

    var i: i32 = 0;
    while (i < config.SAMPLE_SIZE) : (i += 1) {
        randomRectLayer(arg_inputs);
        if (feedForward(arg_inputs.*, arg_weights.*) > config.BIAS) {
            subInputsFromWeights(arg_inputs.*, arg_weights);
            const file_path = fmt.bufPrintZ(&Static.file_path, "{s}/weights-{:0>3}.ppm", .{ config.DATA_FOLDER, Static.count }) catch {
                print_err("[ERROR] saving {s}\n", .{Static.file_path});
                return -1;
            };
            Static.count += 1;
            print_out("[INFO] saving {s}\n", .{file_path});
            saveLayerAsPpm(arg_weights.*, file_path);
            adjusted += 1;
        }

        randomCircleLayer(arg_inputs);
        if (feedForward(arg_inputs.*, arg_weights.*) < config.BIAS) {
            addInputsToWeights(arg_inputs.*, arg_weights);
            const file_path = fmt.bufPrintZ(&Static.file_path, "{s}/weights-{:0>3}.ppm", .{ config.DATA_FOLDER, Static.count }) catch {
                print_err("[ERROR] saving {s}\n", .{Static.file_path});
                return -1;
            };
            Static.count += 1;
            print_out("[INFO] saving {s}\n", .{file_path});
            saveLayerAsPpm(arg_weights.*, file_path);
            adjusted += 1;
        }
    }
    return adjusted;
}

fn checkPass(arg_inputs: *Layer, arg_weights: Layer) i32 {
    var adjusted: i32 = 0;
    var i: i32 = 0;
    while (i < config.SAMPLE_SIZE) : (i += 1) {
        randomRectLayer(arg_inputs);
        if (feedForward(arg_inputs.*, arg_weights) > config.BIAS) {
            adjusted += 1;
        }

        randomCircleLayer(arg_inputs);
        if (feedForward(arg_inputs.*, arg_weights) < config.BIAS) {
            adjusted += 1;
        }
    }
    return adjusted;
}

var inputs: Layer = zeroes(Layer);
var weights: Layer = zeroes(Layer);

pub fn main() anyerror!void {
    print_out("[INFO] creating {s}\n", .{config.DATA_FOLDER});

    cwd.makePath(config.DATA_FOLDER) catch |err| {
        print_err("ERROR: could not create directory {s} : {}\n", .{ config.DATA_FOLDER, err });
        return;
    };

    var dataFolder: Dir = cwd.openDir(config.DATA_FOLDER, .{ .iterate = true }) catch |err| {
        print_err("ERROR: could not open directory {s} : {}\n", .{ config.DATA_FOLDER, err });
        return;
    };
    defer dataFolder.close();

    dataFolder.chmod(0o40755) catch |err| {
        print_err("ERROR: could not chmod directory {s} : {}\n", .{ config.DATA_FOLDER, err });
        return;
    };

    posix_rand.srand(config.CHECK_SEED);
    var adj: i32 = checkPass(&inputs, weights);
    print_out("[INFO] fail rate of untrained model is {d:.2}\n", .{@intToFloat(f32, adj) / (@intToFloat(f32, config.SAMPLE_SIZE) * 2.0)});

    var i: i32 = 0;
    while (i <= config.TRAIN_PASSES) : (i += 1) {
        posix_rand.srand(config.TRAIN_SEED);
        var trained_adj = trainPass(&inputs, &weights);
        print_out("[INFO] Pass {d}: adjusted {d} times\n", .{ i, trained_adj });
        if (trained_adj <= 0) break;
    }

    posix_rand.srand(config.CHECK_SEED);
    adj = checkPass(&inputs, weights);
    print_out("[INFO] fail rate of trained model is {d:.2}\n", .{@intToFloat(f32, adj) / (@intToFloat(f32, config.SAMPLE_SIZE) * 2.0)});
}
