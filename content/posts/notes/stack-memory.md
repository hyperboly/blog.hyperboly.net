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

A program can have this in the memory "stack" while it's running.
