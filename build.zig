const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const static =
        b.addLibrary(.{
            .name = "static",
            .linkage = .static,
            .root_module = b.createModule(.{
                .root_source_file = null,
                .target = target,
                .optimize = optimize,
            }),
        });
    static.addCSourceFile(.{ .file = b.path("src/static.c") });

    const dyn =
        b.addLibrary(.{
            .name = "dynamic",
            .linkage = .dynamic,
            .root_module = b.createModule(.{
                .root_source_file = null,
                .target = target,
                .optimize = optimize,
            }),
        });
    dyn.addCSourceFile(.{ .file = b.path("src/dynamic.c") });
    dyn.linkLibrary(static);

    const static2 =
        b.addLibrary(.{
            .name = "static-2",
            .linkage = .static,
            .root_module = b.createModule(.{
                .root_source_file = null,
                .target = target,
                .optimize = optimize,
            }),
        });
    static2.addCSourceFile(.{ .file = b.path("src/static-2.c") });

    const exe = b.addExecutable(.{
        .name = "main",
        .root_module = b.createModule(.{
            .root_source_file = null,
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.linkLibC();
    exe.addCSourceFile(.{ .file = b.path("src/main.c") });
    exe.linkLibrary(dyn);
    exe.linkLibrary(static2);
    b.installArtifact(exe);
}
