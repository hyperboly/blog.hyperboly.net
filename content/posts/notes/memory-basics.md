---

title: "Memory Basics"
date: 2023-03-19T20:08:56+08:00
author: John Wu
tags: ['CTFs','tech']
summary: "How memory is structured and what it really is"
ShowToc: true

---

Memory is essential to understand for pwning in CTFs. Here, I will try to explain the structure of memory and behaviors for beginners in pwn.

## Definition of Memory
First, a basic definition of memory. Have you ever seen that long card in your computer with black squares on it? That's memory. Most people (who watch Linus Tech Tips) know this as Random Access Memory (RAM), but at the core it is just temporary storage on your computer. RAM is immediately wiped after rebooting your computer, but is much faster than writing onto your SSD or hard drive. Functions that require temporary and fast speeds would use RAM; this includes caching websites, displaying text in a GUI, and loading chunks in games.
![RAM Stick](/RAM-stick.jpg)

## Memory Structure
I will abstract a lot of the memory structure here, so read on knowing there will be inaccuracies. Think of memory as a building, each floor is a storage space, and a building only has so many floors. Each floor and groups of floors can have a different purpose, the basement is for parking, floor 1 is for the lobby, floor 2 is for a restaurant, and the rest are residential. Now think of the floors as space in memory. There are 3 main spaces in memory, the data, stack, and heap.
#### Diagram of Memory
| Memory Space | Description                     |
|--------------|---------------------------------|
| Data         | Is where "static" variables are |
| Stack        | Is where "local" variables are  |
| Heap         | Is where "buffers" exist        |
#### The Data Memory Space
The data space will not be used in many beginner pwn questions, I don't think I've ever encountered it. It also means that they don't get deleted once a function is finished, these variables persist until the program dies. This means that nothing in the data space should change while the program is running. This would include things from libraries, a variable named MAX_HEIGHT, and others like that.
#### The Stack Memory Space
This is the part of memory that many beginner pwn questions will want you to attack. If you've ever went on stackoverflow.com, the stack in memory is where that name came from. "Stack overflow" attacks are a common way that CTFs question beginners. The stack is where variable in a function exists. This would include the `main` function. Stacks contains variables that the programmer defines the memory to. For example, `int foo = 7;` is the programmer dedicating 4 bytes of memory to `foo`. He is dedicating 4 bytes because by default in C, an integer is 4 bytes in length. Inside the 4 bytes, it would only store "7" though.

Probably more important than variables in the stack is the pointer and addresses in the stack. The stack pointer is not like pointers in C/C++. The stack pointer indicates where the program is while the program is running. This becomes very helpful while debugging. The Extended Instruction Pointer exists at the end of the stack execution, where it will look for the next instruction. This becomes useful when we do something called a "stack overflow," where you overflow the whole stack and enter in the malicious instruction onto the original instruction pointer space. Later articles will further explain the stack.

The stack does NOT include the buffers, which is in the "heap."
#### The Heap Memory Space
The heap is, as mentioned, where the buffers live. But what are buffers? Buffers are spaces in code that the programmer dictates. How is this different from declaring a variable in the stack? Stack variables can't be resized, but buffers can. If I create a array in C, like this: `int ary[100]`, I am dynamically assigning 404 bytes to `ary` (0-100 integers, each int is 4 bytes). Confused? Me too! Stack variables have the life cycle of being declared, stored, and initialized during **runtime**. When the function ends, so do the variables in the stack.

The heap is more "floaty," as in it exists in no particular order. Multiple buffers can live in memory without an order like stack variables do. The memory allocated is also decided by the programmer, not the compiler. Before I mentioned `int` takes 4 bytes of space, this is not a decision by the programmer but by the compiler. Compared to `int ary[100];`, the programmer specifies that he wants 404 bytes for this.
