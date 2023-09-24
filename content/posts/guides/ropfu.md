---

title: "Ropfu"
date: 2023-09-22T00:39:08+08:00
author: John Wu
summary: "Intro to ROP and my writeup for picoCTF 2022's ropfu"
tags: ["CTFs", "pwn", "tech", "guides"]
ShowToc: true
draft: true

---

This challenge is a simple return oriented challenge, which means I spent 2 days trying to solve the challenge and looking through the solutions for more than 2 hours.
Anyways, return oriented programming in x86.
Let's get started.

## Given

Problem:
What's ROP? Can you exploit the following program to get the flag? Download source. nc saturn.picoctf.net 54707

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

#define BUFSIZE 16

void vuln() {
  char buf[16];
  printf("How strong is your ROP-fu? Snatch the shell from my hand, grasshopper!\n");
  return gets(buf);

}

int main(int argc, char **argv){

  setvbuf(stdout, NULL, _IONBF, 0);
  

  // Set the gid to the effective gid
  // this prevents /bin/sh from dropping the privileges
  gid_t gid = getegid();
  setresgid(gid, gid, gid);
  vuln();
  
}
```

You are also given a `vuln` file with ASLR off.
```bash
~/CTF/picoCTF/ropfu > checksec vuln
[*] '/home/hyperboly/CTF/picoCTF/ropfu/vuln'
    Arch:     i386-32-little
    RELRO:    Partial RELRO
    Stack:    Canary found
    NX:       NX disabled
    PIE:      No PIE (0x8048000)
    RWX:      Has RWX segments
```

Hint: This is a classic ROP to get a shell

## What's ROP???
Return Oriented Programming (ROP), is just what the title says it is.
It's programming with return statements.

As a prerequisite, you should be familiar with how C/C++ return statements behave.
For example, for a function to break out of the function and go back to main, it needs some return value (with the exception of `void`).
I'm not great with C at all, but it's not hard to figure out.

Why do we need ROP though?
Up until now, I've only done challenges with a win() function, which obviously isn't realistic.
Which program nowadays would just have a function that gives the user the shell?
This is why ROP exists, to use existing code from the program against itself.
In this challenge, we want the shell.

Well let's find out how x86 deals with returns on the stack.
In x86, the stack frame right around the $esp would look like this:

| Position| What's in the Stack                    |
|---------|----------------------------------------|
| ebp-0x58 | $esp                                  |
| ebp-0x5c | possible args for func to return to   |
| ebp-0x60 | addr of return                        |
| ebp-0x64 | arbitrary data                        |

What's most important is noticing that the arguments are placed **on the stack**.
This is different in x86-64, which conventionally stores arguments in general purpose registers.
So if the function already returned, how does the value even get placed placed onto the new stack frame?

The last instruction before the process `ret`s to the new stack frame would be a `pop` instruction.
What this does is pop the last 4 bytes off the stack BUT at the same time store the value into whatever register the pop instruction specified.
For example `pop eax` would take the last 4 bytes of the stack and store it into $eax.

To show the process of the execution, here's a step by step execution thing kind of:

1. Program to ret instruction
2. Stack value is an address that points to another function (return address)
3. Program gets to `pop eax` instruction
4. The top 4 bytes of the stack is deleted and copied onto $eax
5. Program goes into the new function's stack frame
6. Program returns to original stackframe and starts off where it left

So how do we program with ROP then?
All we need to do is set return address (and arguments if applicable) to ROP gadgets

### Gadgets? Is this sci-fi now?
Gadgets are essentially code snippets from the victim program that we can use against the program.
The gadgets you might want for the way I did this problem ends with the `ret` instruction, but you can also use a [nop chain, or a nop slide](https://en.wikipedia.org/wiki/NOP_slide) for this challenge.
In the case of a nop chain, you want to find something that has the `jmp` instruction.

## Assembling the ROP chain
Now that we understand gadgets, we can piece all these concepts together to create a ROP chain.
ROP chains are essentially carefully picked out gadgets strung together into the stack to do what we want it to do.
Since we want to call for the shell, we want a syscall to the shell.
Now, if there is a execve syscall gadget from the program, we can call that and pop the rest of the stack into `execve` as arguments!
To find syscall numbers, here's a [table](https://filippo.io/linux-syscall-table/).

## Analysis
Alright, now we have all the prerequisite knowledge to do this challenge.


## Solution
