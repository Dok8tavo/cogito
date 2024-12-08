# Cogito

Cogito is a zig module that offers basic compile-time datastructures -like `List`, `Dict` or
`Set`-
designed to help metaprogramming.

## Usage

1. Fetch the package by running `zig fetch git+https://github.com/Dok8tavo/cogito --save=cogito`
in the folder containing `build.zig.zon`.

2. Get cogito in your `build.zig` script:

```zig
pub fn build(b: *std.Build) !void {
    ...
    const cogito = b.dependency(
        // this must be the name you used in the `--save=` option
        "cogito", .{
        .target = ...,
        .optimize = ...,
    }).module(
        // this one must be "cogito", it's the name of the module from inside
        // the package
        "cogito"
    );
    ...
}
```

3. Add the import for your module/executable/library/test:

```zig
pub fn build(b: *std.Build) !void {
    ...
    const cogito = ...;

    my_executable_library_or_test.root_module.addImport(
        // this can be whatever you want, it'll affect your `@import` calls
        "cogito",
        cogito,
    );

    my_module.addImport(
        // same
        "cogito",
        cogito,
    );
    ...
}
```

4. Import the module in your source code:

```zig
const cogito = @import(
    // this is the name you used in the `addImport` function in your 
    // `build.zig` script.
    "cogito"
);
```
