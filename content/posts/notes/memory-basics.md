---

title: "Memory Basics"
date: 2023-03-19T20:08:56+08:00
author: John Wu
tags: ['CTFs','tech']

---

Memory is essential to understand for pwning in CTFs. Here, I will try to explain the structure of memory and behaviors for beginners in pwn.

## Definition of Memory
First, a basic definition of memory. Have you ever seen that long card in your computer with black squares on it? That's memory. Most people (who watch Linus Tech Tips) know this as Random Access Memory (RAM), but at the core it is just temporary storage on your computer.
![RAM Stick](/RAM-stick.jpg)

## Memory Structure
I will abstract a lot of the memory structure here, so read on knowing there will be inaccuracies. Think of memory as a building, each floor is a storage space, and a building only has so many floors. Each floor and groups of floors can have a different purpose, the basement is for parking, floor 1 is for the lobby, floor 2 is for a restaurant, and the rest are residential. Now think of the floors as space in memory. There are 3 main spaces in memory, the data, stack, and heap.
### Diagram of Memory
| Memory Space | Description                     |
|--------------|---------------------------------|
| Data         | Is where "static" variables are |
| Stack        | Is where "local" variables are  |
| Heap         | Is where "buffers" exist        |
#### The Data Memory Space
The data space will not be used in many beginner pwn questions, I don't think I've ever encountered it. It also means that they don't get deleted once a function is finished, these variables persist until the program dies. This means that nothing in the data space should change while the program is running. This would include things from libraries, a variable named MAX_HEIGHT, and others like that.
#### The Stack Memory Space
This is the part of memory that many beginner pwn questions will want you to attack. If you've ever went on stackoverflow.com, the stack in memory is where that name came from. "Stack overflow" attacks are a common way that CTFs question beginners. The stack is where variable in a function exists. This would include the `main` function. Stacks contains variables that the programmer defines the memory to. For example, `int foo = 7;` is the programmer dedicating 4 bytes of memory to `foo`. He is dedicating 4 bytes because by default in C, an integer is 4 bytes in length. Inside the 4 bytes, it would only store "7" though. The stack does NOT include the buffers, which is in the "heap."
