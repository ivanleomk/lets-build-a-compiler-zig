# Let's Build a Compiler in Zig: Part 1 - Introduction and the Cradle

Welcome to the first installment of our series on building a compiler with the Zig programming language! This series is a modern interpretation of Jack Crenshaw's classic "Let's Build a Compiler" tutorial [1]. We will follow his practical, hands-on philosophy to demystify the art of compiler construction. By the end of this journey, you will have built a functional compiler for a simple programming language from scratch, gaining a deep understanding of how compilers work and a solid proficiency in Zig.

## Why Build a Compiler?

For many software developers, a compiler is a black box. We write code, invoke the compiler, and it magically produces an executable file. But have you ever wondered what happens under the hood? Building a compiler is a classic and enlightening computer science project that will give you a profound appreciation for the tools you use every day. It's a challenging but immensely rewarding endeavor that will sharpen your programming skills and deepen your understanding of language design, parsing, code generation, and optimization.

## Why Zig?

Zig is a modern, general-purpose programming language that is particularly well-suited for systems programming tasks like building a compiler. Here are a few reasons why Zig is an excellent choice for this project:

*   **Simplicity and Readability:** Zig has a clean and concise syntax that is easy to learn. This allows us to focus on the core concepts of compiler construction without getting bogged down in complex language features.
*   **Performance:** As a compiled language, Zig offers performance on par with C, which is crucial for a performance-sensitive application like a compiler.
*   **Safety and Robustness:** Zig incorporates modern safety features, such as compile-time memory management and explicit error handling, which help us write robust and reliable code.
*   **Excellent Toolchain:** Zig comes with a powerful build system and a standard library that provides all the tools we need for this project.

## Getting Started: Setting Up Your Environment

Before we can start writing code, we need to set up our Zig development environment. The process is straightforward.

### Installing Zig

The official Zig website provides pre-built binaries for all major operating systems. You can download the latest version from the [Zig download page](https://ziglang.org/download/).

For Linux and macOS, you can extract the archive and add the `zig` executable to your system's `PATH`. For this tutorial, we will use the following commands to install Zig 0.13.0 on a Linux system:

```sh
wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
tar -xf zig-linux-x86_64-0.13.0.tar.xz
sudo mv zig-linux-x86_64-0.13.0 /opt/zig
sudo ln -sf /opt/zig/zig /usr/local/bin/zig
```

After installation, you can verify that Zig is correctly installed by running:

```sh
zig version
```

This should print the installed Zig version, for example, `0.13.0`.

## The "Cradle": Our Compiler's Foundation

Following Crenshaw's approach, we will start by creating a "cradle" of essential helper functions. This cradle will provide a foundation for all the subsequent parts of our compiler, handling common tasks like input/output, error reporting, and code generation. This modular approach allows us to get a basic structure in place quickly and then build upon it incrementally.

Let's create a new file named `cradle.zig` and start adding our helper functions.

### Basic Setup and I/O

First, we need to import the standard library and define a global variable to hold the current character we are looking at from the source code. This is often called the "lookahead" character.

```zig
const std = @import("std");

pub var look: u8 = 0;

pub fn getChar() anyerror!void {
    const stdin = std.io.getStdIn().reader();
    look = stdin.readByte() catch |err| {
        if (err == error.EndOfStream) {
            return;
        }
        return err;
    };
}
```

The `getChar` function reads a single byte from standard input and stores it in our global `look` variable. We use `anyerror!void` to indicate that this function can fail, and we handle the `EndOfStream` error specifically.

### Error Handling

Robust error handling is crucial for any compiler. We will create a set of simple functions to report errors and halt execution.

```zig
pub fn reportError(message: []const u8) void {
    std.debug.print("\nError: {s}.\n", .{message});
}

pub fn abort(message: []const u8) noreturn {
    reportError(message);
    std.process.exit(1);
}

pub fn expected(s: []const u8) noreturn {
    const message = std.fmt.allocPrint(std.heap.page_allocator, "{s} Expected", .{s}) catch unreachable;
    abort(message);
}
```

These functions provide a simple way to report errors and terminate the program. The `noreturn` type in `abort` and `expected` tells the Zig compiler that these functions will never return.

### Parsing Helpers

Next, we'll add some functions to help with parsing the input stream.

```zig
pub fn match(x: u8) anyerror!void {
    if (look == x) {
        try getChar();
    } else {
        const expected_char = [1]u8{x};
        expected(&expected_char);
    }
}

pub fn isAlpha(c: u8) bool {
    return std.ascii.isAlphabetic(c);
}

pub fn isDigit(c: u8) bool {
    return std.ascii.isDigit(c);
}

pub fn getName() anyerror!u8 {
    if (!isAlpha(look)) {
        expected("Name");
    }
    const name = std.ascii.toUpper(look);
    try getChar();
    return name;
}

pub fn getNum() anyerror!u8 {
    if (!isDigit(look)) {
        expected("Integer");
    }
    const num = look;
    try getChar();
    return num;
}
```

The `match` function is a cornerstone of our parser. It checks if the current `look` character matches the expected character `x`. If it does, it consumes the character and moves to the next one. If not, it reports an error.

The other functions are simple helpers to recognize different character types and to get identifiers and numbers from the input stream.

### Code Generation

Finally, we'll add a few functions to handle code generation. For now, we will be generating x86 assembly code and printing it to the console.

```zig
pub fn emit(s: []const u8) void {
    std.debug.print("\t{s}", .{s});
}

pub fn emitLn(s: []const u8) void {
    emit(s);
    std.debug.print("\n", .{});
}
```

These functions provide a simple way to emit assembly instructions to standard output.

### Initialization

To tie everything together, we'll create an `init` function that initializes our compiler by reading the first character of input.

```zig
pub fn init() anyerror!void {
    try getChar();
}
```

## Putting It All Together

Now that we have our `cradle.zig` file, let's create a `main.zig` file to test it out.

```zig
const cradle = @import("cradle.zig");
const std = @import("std");

pub fn main() anyerror!void {
    try cradle.init();
    const name = try cradle.getName();
    const num = try cradle.getNum();

    const hello = std.fmt.allocPrint(std.heap.page_allocator, "Hello, {c}{c}", .{name, num}) catch unreachable;
    cradle.emitLn(hello);
}
```

This simple program initializes the cradle, reads a name and a number from the input, and then emits a greeting. To compile and run this program, use the following commands:

```sh
zig build-exe main.zig --name hello
echo "A1" | ./hello
```

You should see the following output:

```
	Hello, A1
```

This confirms that our cradle is working correctly!

## Conclusion and What's Next

In this first article, we have laid the foundation for our compiler. We have set up our development environment, discussed the philosophy behind our approach, and built a cradle of essential helper functions. We have also created a simple test program to verify that everything is working as expected.

In the next article, we will dive into the core of our compiler: the expression parser. We will learn about context-free grammars and recursive descent parsing, and we will implement a parser for simple arithmetic expressions.

---

## References

[1] Crenshaw, Jack W. "Let's Build a Compiler." Accessed January 17, 2026. http://compilers.iecc.com/crenshaw/.
