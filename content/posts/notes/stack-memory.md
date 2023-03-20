---

title: "Stack Memory"
date: 2023-03-20T08:22:38+08:00
author: John Wu
tags: ['tech','CTFs']
ShowToc: true
summary: "What is in the stack"
draft: true

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
## Stack Behavior
A program can have this in the memory "stack" while it's running. Once the function is in called, the local variables are loaded into the stack and deallocated when the function returns. The stack is ordered, meaning that a chunk of the stack is dedicated to one variable and written in the order that the variable is in (see table above). The dedicated space in memory for the stack is never fragmented because of the nature of ordering the memory.
## Adding/Subtracting From The Stack
The stack goes from top to bottom, so when an item is "popped" out, it's taken from the top of the stack. From a value is "pushed"into the stack, the value is placed at the bottom.

## Registers
There are 3 main registers in the stack, PC, AR, and SP. Registers are tiny pieces of memory in the CPU that store information about the current process (instructions, adresses...).
### PC
The Program Counter is where the next instruction in the program is saved. This is more commonly called an Instruction Pointer (IP). 
### AR
### SP
