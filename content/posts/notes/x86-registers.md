---

title: "X86 Registers"
date: 2023-08-23T19:16:23+08:00
author: John Wu
summary: "Registers in x86 and x86_64"
tags: ['CTFs','tech','pwn']
ShowToc: true

---

To use tools like GDB, hydra, pwntools, or any other pwn related stuff, you must understand memory and registers.
This enables you to understand the assembly language which this article will tackle x86 and x86_64 architectures.
To get a high level understanding of memory and it's segments, read [memory basics](/posts/notes/memory-basics).

## Definition
What are registers.
Registers are tiny memory in your CPU.
You've heard of RAM, or random access memory, but you probably haven't heard of registers.
Registers are the fastest accessible memory spaces that your programs can access, but because they're so small they are reserved for special usecases.
Your RAM could be used for cache, browser stuff, and your display server.
These processes don't need to be the fastest thing in the world, but it does need to be faster than disk because no one's waiting 10 minutes for a browser to load (... snap packages).
So registers are reserved for specific things such as defining addresses on the stack, or saving a return address to return back to `main` because another function is occupying the stack frame.

## Architectures
Architectures in this context is how big a register can be.
For example, x86 architecture means your registers are 32 bits (4 bytes) in size.
Or, x86_64 (x64 in AMD) are 64 bits (8 bytes) in size.

### x64 Registers
x64 registers as mentioned before are 64 bits, or 8 bytes.
In x86_64, registers are prefixed with an "r."
This means, what would be "eip," "esp," or "ebp" in x86 would be "rip," "rsp," and "rbp" in x64.
The ending 2 characters does not change between x64 and x86, but the prefixes change, this is also the case for smaller registers (ax, ah...).

### x86 Registers
x86 registers as mentioned before are 32 bits, or 4 bytes.

This image is a comparison of 32-bit registers and smaller registers.
It also lists some registers (explained later).
![x86 registers compared to smaller ones](/images/CTF-notes/x86-registers.png)

## Reserved Registers
Even with registers, there are some that are reserved for special register usecases, here are some.
```
eip:    Base Pointer, points to the bottom of the current stack frame
esp:    Stack Pointer, points to the top of the current stack frame
ebp:    Instruction Pointer, points to the instruction to be executed

General registers ↓
eax:    Register for temp storage, can be used to store return addresses
ebx:    Register for either same as eax or preserved for base pointer
ecx:    4th argument
edx:    3rd argument
esi:    2nd argument
edi:    1st argument
e8:     5th argument
e9:     6th argument
e10:
e11:
e12:
e13:
e14:
e15:
```

General registers don't always follow the purpose listed above, but this is the general purpose they normally serve.

Registers in CTFs can be used for return oriented programming, EIP manipulation, and other stuff I don't know about.
