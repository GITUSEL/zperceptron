// config

const std = @import("std");

pub usingnamespace Config;
const Config = struct {
    pub const INT_MAX: i32 = std.math.maxInt(i32);

    pub const WIDTH: i32 = 20;
    pub const HEIGHT: i32 = 20;

    pub const PPM_SCALER: i32 = 25;
    pub const PPM_COLOR_INTENSITY: i32 = 255;
    pub const PPM_RANGE: f32 = 10.0;

    pub const BIAS: f32 = 20.0;
    pub const SAMPLE_SIZE: i32 = 75;
    pub const TRAIN_PASSES: i32 = 2000;

    pub const DATA_FOLDER: []const u8 = "data";

    pub const TRAIN_SEED: i32 = 69;
    pub const CHECK_SEED: i32 = 420;
};
