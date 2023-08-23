---

title: "Starting Pwn"
date: 2023-03-19T19:05:02+08:00
author: John Wu
ShowToc: true
summary: "An introduction to the pwn (binary exploit) category for CTFs"
tags: ['tech','CTFs', 'pwn']

---

Pwn as a CTF category has always interested me because of the low level understanding it requires to be good at it. Turns out I'm terrible at it, so here are my notes to try and organize what I've learned. The [pico primer](https://primer.picoctf.org/) really helped me with this. CryptoCat's [tutorial](https://www.youtube.com/watch?v=wa3sMSdLyHw&list=PLHUKi1UlEgOIc07Rfk2Jgb5fZbxDPec94) is also great for learning.

## Definitions:
### Abstraction
I find that many people trying to get into computers get confused with abstraction as I did before, so I'll try to explain it in simple terms. Abstraction means to dumb down. For example, in math, many questions ask you to "simplify an expression" when you simplify an expression, you are abstracting the original expression. Or, if I have a chunk of code in a program that takes in user input, it would be stupid to always repeat that code on and on. Which is why we have functions, so we can name it "take_input" and **abstract** away the code in the function. This is most evident in programming languages, as you'll read later, programming languages just abstract assembly; assembly just abstracts binary.
### Disassembling
Disassembling is basically the process of turning some binary into assembly language. Humans aren't able to read binary as well as they can assembly. To read binary, you would have to separate them into different chunks, try to decode what the binary's value is, and try to translate that into what the machine is doing. Assembly makes this process 10% easier by telling you exactly what the computer is doing. This is still really hard to read because it provides you with extremely LOW LOW levels of abstraction in memory. Things like Extended Instruction Pointer (EIP) that takes a long time to fully grasp the concept.

## Tooling:
What you'll notice with pwn is that there is a million different tools that achieve the same thing, I'll start with debugging:
### GNU Debugger (GDB)
[GDB](https://www.gnu.org/software/gdb/) is an amazing debugger for pwn, it can do everything it needs to well. GDB takes in a binary and provides a disassembler, gives you the location of different pointers, functions... The problem is that the syntax will take forever to learn.
### GEF
[GEF](https://hugsy.github.io/gef/) is essentially a wrapper for GDB. This means that it simplifies GDB's syntax so that we don't have to type long lines just to achieve one thing. I learned GEF when watching a video on pwnable.tw's [start](https://pwnable.tw/challenge/#1), which I haven't finished because I don't understand it at all.
### pwndbg
[pwndbg](https://github.com/pwndbg/pwndbg) is another wrapper for GDB (see a pattern here?). It is written in python and I think further simplifies GDB's syntax (compared to GEF). It is a little easier to learn and the current one I'm learning.
### Ghidra
[Ghidra](https://ghidra-sre.org/) is a tool developed by the NSA for disassembling and turning binaries into C. It is written in Java so I only run it in a VM, because any Java software is bloat for your system. The tool gives you a UI unlike the other 3 tools above, disassembles the code like with GDB, and tries to recreate the binary in C. This can give you a lot more insight into what the code is doing, which helps a lot in CTFs.
### pwn
[pwn](https://docs.pwntools.com/en/stable/) is a pretty sweet python library that helps a LOT in solving CTFs and automating your solutions. The problem is that I'm a terrible programmer and can only program in BASH. It includes stuff like `remote` which allows you to attack remote services with python, it's pretty cool.
