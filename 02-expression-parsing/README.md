# Let's Build a Compiler in Zig: Part 2 - Expression Parsing

Welcome back to our series on building a compiler in Zig! In the [first part](https://github.com/ivanleomk/lets-build-a-compiler-zig/tree/main/01-introduction), we laid the groundwork by setting up our environment and creating a "cradle" of helper functions. Now, we're ready to tackle the heart of our compiler: the parser. This is where we'll start to make sense of the source code and turn it into something the machine can understand.

Our goal in this chapter is to parse simple, single-digit arithmetic expressions involving addition, subtraction, multiplication, and division.

## A Language Defined by a Grammar

Before we can write a parser, we need a precise definition of the language we want to parse. For this, we use a formal notation called a **context-free grammar**. The most common way to write these grammars is **Backus-Naur Form (BNF)**. A BNF grammar consists of a set of rules (or *productions*) that define the syntax of a language.

Here is the classic grammar for arithmetic expressions, which correctly handles operator precedence (multiplication and division are evaluated before addition and subtraction):

```bnf
<expression> ::= <term> [ ( + | - ) <term> ]*
<term>       ::= <factor> [ ( * | / ) <factor> ]*
<factor>     ::= <number> | ( <expression> )
```

Let's break down what this means:

- An `<expression>` is a `<term>`, optionally followed by any number of `+` or `-` operators, each followed by another `<term>`.
- A `<term>` is a `<factor>`, optionally followed by any number of `*` or `/` operators, each followed by another `<factor>`.
- A `<factor>` is the simplest component, which can be either a single-digit `<number>` or another complete `<expression>` enclosed in parentheses.

This hierarchical structure is the key to handling operator precedence. Because `<expression>` is defined in terms of `<term>`, and `<term>` is defined in terms of `<factor>`, the parser will naturally evaluate multiplication and division (in `<term>`) before addition and subtraction (in `<expression>`).

## Recursive Descent Parsing

The grammar above is perfectly suited for a parsing technique called **recursive descent**. The idea is simple and elegant: we write one function for each non-terminal symbol in our grammar (i.e., for `<expression>`, `<term>`, and `<factor>`). Each function is responsible for recognizing the part of the language defined by its corresponding grammar rule.

- The `expression()` function will handle addition and subtraction.
- The `term()` function will handle multiplication and division.
- The `factor()` function will handle numbers and parenthesized expressions.

These functions will call each other in a way that mirrors the structure of the grammar, forming a set of mutually recursive functions that descend through the grammar rules to parse the input stream.

## Implementing the Parser in Zig

Let's start coding. First, create a new directory `02-expression-parsing` and copy the `cradle.zig` file from the previous chapter into it.

We need to add one new helper function to our cradle to recognize additive operators. Open `cradle.zig` and add the following function:

```zig
// In cradle.zig
pub fn isAddop(c: u8) bool {
    return c == '+' or c == '-';
}
```

Now, let's create our `main.zig` file and implement the parser functions.

### The `factor` Function

We'll start from the bottom of the grammar with `<factor>`. This function handles numbers and parenthesized expressions.

```zig
// In main.zig
const cradle = @import("cradle.zig");
const std = @import("std");

// Forward-declare expression() so factor() can call it.
fn expression() anyerror!void;

fn factor() anyerror!void {
    if (cradle.look == '(') {
        try cradle.match('(');
        try expression();
        try cradle.match(')');
    } else {
        const num = try cradle.getNum();
        const instruction = std.fmt.allocPrint(std.heap.page_allocator, "mov ${c}, %eax", .{num}) catch unreachable;
        cradle.emitLn(instruction);
    }
}
```

If the lookahead character is an opening parenthesis, we match it, recursively call `expression()` to parse the sub-expression inside, and then match the closing parenthesis. Otherwise, we assume we have a number, which we parse with `getNum()` and then generate the assembly code to load that number into the `%eax` register.

### The `term` Function

Next up is `<term>`, which handles multiplication and division.

```zig
// In main.zig
fn term() anyerror!void {
    try factor();
    while (cradle.look == '*' or cradle.look == '/') {
        cradle.emitLn("push %eax");
        switch (cradle.look) {
            '*' => try multiply(),
            '/' => try divide(),
            else => unreachable, // Loop condition prevents this
        }
    }
}

fn multiply() anyerror!void {
    try cradle.match('*');
    try factor();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("imul %ebx, %eax");
}

fn divide() anyerror!void {
    try cradle.match('/');
    try factor();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("xchg %eax, %ebx"); // Divisor in eax, Dividend in ebx
    cradle.emitLn("cdq"); // Sign-extend eax into edx
    cradle.emitLn("idiv %ebx");
}
```

The `term` function first calls `factor()` to get the value of the first factor. Then, it enters a loop that continues as long as the lookahead character is a `*` or `/`. Inside the loop, we `push` the current result (in `%eax`) onto the stack, then call either `multiply()` or `divide()` to handle the operation. These functions, in turn, parse the next factor and generate the appropriate assembly code, using the value on top of the stack (`pop %ebx`) as the first operand.

### The `expression` Function

Finally, we implement `<expression>`, which handles addition and subtraction. Its structure is very similar to `term()`.

```zig
// In main.zig
fn expression() anyerror!void {
    try term();
    while (cradle.isAddop(cradle.look)) {
        cradle.emitLn("push %eax");
        switch (cradle.look) {
            '+' => try add(),
            '-' => try subtract(),
            else => unreachable,
        }
    }
}

fn add() anyerror!void {
    try cradle.match('+');
    try term();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("add %ebx, %eax");
}

fn subtract() anyerror!void {
    try cradle.match('-');
    try term();
    cradle.emitLn("pop %ebx");
    cradle.emitLn("sub %ebx, %eax");
    cradle.emitLn("neg %eax");
}
```

## Putting It All Together

To complete our program, we just need a `main` function to kick things off.

```zig
// In main.zig
pub fn main() anyerror!void {
    try cradle.init();
    try expression();
}
```

Now, let's test it! Compile and run the code with a sample expression:

```sh
cd 02-expression-parsing
zig build-exe main.zig --name parser
echo "2*3+4" | ./parser
```

You should see the following assembly code printed to your console:

```assembly
	mov $2, %eax
	push %eax
	mov $3, %eax
	pop %ebx
	imul %ebx, %eax
	push %eax
	mov $4, %eax
	pop %ebx
	add %ebx, %eax
```

This assembly code correctly calculates `(2 * 3) + 4`. The use of the stack (`push` and `pop`) ensures that the intermediate result of `2*3` is saved before the addition with `4` is performed.

## Conclusion

Congratulations! You have successfully built a working expression parser and code generator. You've learned about BNF grammars, recursive descent parsing, and how to translate arithmetic expressions into assembly code. The structure we've built here is the foundation for the rest of our compiler.

In the next part, we will expand on this foundation, adding support for more complex expressions and introducing variables.

---

## References

[1] Crenshaw, Jack W. "Let's Build a Compiler." Accessed January 17, 2026. http://compilers.iecc.com/crenshaw/.
