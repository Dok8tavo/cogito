// MIT License
//
// Copyright (c) 2024 Dok8tavo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root = b.path("src/root.zig");

    const object = b.addObject(.{
        .name = "cogito",
        .root_source_file = root,
        .target = target,
        .optimize = optimize,
    });

    const documentation = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "doc",
        .source_dir = root,
    });

    const testing = b.addTest(.{
        .root_source_file = root,
        .target = target,
        .optimize = optimize,
    });

    const run_testing = b.addRunArtifact(testing);

    const zls_step = b.step("zls", "Custom step for zls to run");
    const doc_step = b.step("doc", "Generate documentation");
    const test_step = b.step("test", "Run unit tests");

    zls_step.dependOn(&object.step);
    doc_step.dependOn(&documentation.step);
    test_step.dependOn(&run_testing.step);

    b.getInstallStep().dependOn(&object.step);
}
