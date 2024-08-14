---

title: "Stack Memory"
date: 2023-03-20T08:22:38+08:00
author: John Wu
tags: ['tech','CTFs','pwn']
toc: true
description: "What is in the stack"
draft: false

---

The stack in memory is where all local variables reside. Consider this function:
```C
int main () {
    int foo = 7;
    for (i=0;i<foo;i++){
        foo--;
    }
}
```
- The local variables here are `foo` and `i`
    - `foo`
        - given 4 bytes of memory because it is an integer
        - is wiped after `main` is finished running
    - `i`
        - given 4 bytes of memory
        - is wiped after the `for` loop finishes
    - Both of these variables are part of the "stack"
- `for` is  not a local variable because it was loaded in the "data" section of memory since it's from libC.

Memory in a stack can be visualized like this:
| Location | Memory |
|----------|--------|
| 0        | S      |
| 1        | T      |
| 2        | A      |
| 3        | C      |
| 4        | K      |
# Stack Behavior
A program can have this in the memory "stack" while it's running. Once the function is in called, the local variables are loaded into the stack and deallocated when the function returns. The stack is ordered, meaning that a chunk of the stack is dedicated to one variable and written in the order that the variable is in (see table above). The dedicated space in memory for the stack is never fragmented because of the nature of ordering the memory.
# Adding/Subtracting From The Stack
The stack goes from top to bottom, so when an item is "pulled" out, it's taken from the top of the stack. From a value is "pushed"into the stack, the value is placed at the bottom.

# Registers
There are 3 main registers in the stack, PC, AR, and SP. Registers are tiny pieces of memory in the CPU that store information about the current process (instructions, addresses...). Ever thought what aarch or x86 infrastructure even mean? aarch is a 32 bit infrastructure, meaning the CPU only contains 32 bits. x86/amd64 however they name it are 64 bit infrastructure. This means that the CPU contains 64 bits of memory. Why does the CPU need memory? CPU memory (registers) are even faster than RAM and very limited. They are only used for registers.
## PC
The Program Counter points to where the next instruction in the program is saved. This is more commonly called an Instruction Pointer (IP).
## AR
The Address Register contains information about where the array of data needed is.
## SP
The Stack Pointer (SP) points to where the last item pushed onto the stack is. When an item is pushed onto a stack, the SP decrements. When an item is pulled from the stack, the SP increments.

![Stack Visualization](/images/CTF-notes/mem-stack.jpg)

# General Registers
The above explanation is only a high level of registers, there is a lot more happening in the memory on a CPU. Note that registers for **64 bit** architecture computers are different from 32 bit registers. Registers will start with an "R" in 64 bit (RAX) unlike 32 bit registers that start with "E" (EAX).
## Accumulator Registers: RAX, EAX
Accumulator Registers hold temporary information to process every instruction in a program and store the results in the accumulator. From the name, you can probably tell that this is a step by step process, meaning that if I do 1 + 2 + 7, the accumulator would first have the value 1 (starting int), then 3 (1 + 2), and finally 10 (3 + 7).

[Further reading](https://www.geeksforgeeks.org/introduction-of-single-accumulator-based-cpu-organization)
## Base Registers: REX, EBX
Base registers are registers for storing where a stack is in memory. Changing (adding/subtracting) the offset of this can allow you to access variables.
## Counter Registers
## Data Registers

# Sources and Further Reading
[Cool presentation](http://www.ee.nmt.edu/~erives/308L_05/The_stack.pdf)

[tutorialspoint.com](https://www.tutorialspoint.com/what-is-memory-stack-in-computer-architecture)

[pico primer](https://primer.picoctf.org/#_general_registers)
