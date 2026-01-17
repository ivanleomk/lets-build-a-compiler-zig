# Let's Build a Compiler in Zig

A modern take on Jack Crenshaw's classic "Let's Build a Compiler" tutorial, adapted for the Zig programming language.

## About This Project

This repository contains a series of tutorials that guide you through building a compiler from scratch using Zig. The series is inspired by Jack Crenshaw's legendary tutorial, which was originally written in Pascal and targeted the Motorola 68000 processor. Our version uses Zig and generates x86-64 assembly code.

By following this tutorial, you will learn:

- The fundamentals of compiler construction
- How to build a recursive descent parser
- How to generate assembly code
- The Zig programming language

## Prerequisites

- Basic programming knowledge
- Zig 0.13.0 or later (see [installation instructions](https://ziglang.org/download/))
- A Unix-like environment (Linux, macOS, or WSL on Windows)

## Tutorial Structure

| Part | Title | Description |
|------|-------|-------------|
| 1 | [Introduction](01-introduction/README.md) | Setting up the environment and building the "cradle" |
| 2 | [Expression Parsing](02-expression-parsing/README.md) | Parsing arithmetic expressions with recursive descent |
| 3 | More Expressions | Coming soon |
| ... | ... | ... |

## Getting Started

1. Clone this repository:
   ```sh
   git clone https://github.com/ivanleomk/lets-build-a-compiler-zig.git
   cd lets-build-a-compiler-zig
   ```

2. Navigate to the first tutorial:
   ```sh
   cd 01-introduction
   ```

3. Build and run the example:
   ```sh
   zig build-exe main.zig --name hello
   echo "A1" | ./hello
   ```

## Acknowledgments

This tutorial is based on Jack Crenshaw's "Let's Build a Compiler" series, which can be found at [http://compilers.iecc.com/crenshaw/](http://compilers.iecc.com/crenshaw/).

## License

This project is released under the MIT License. See [LICENSE](LICENSE) for details.
