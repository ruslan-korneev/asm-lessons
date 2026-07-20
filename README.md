Welcome to the FFmpeg School of Assembly Language. You have taken the first step on the most interesting, challenging, and rewarding journey in programming. These lessons will give you a grounding in the way assembly language is written in FFmpeg and open your eyes to what's actually going on in your computer.

> **This fork** adds a Russian translation of the lessons (`index.ru.md` in each lesson folder) and **interactive step-by-step visualizations** (Russian and English) of the key concepts — registers, SIMD loops, addressing, FLAGS, LEA, pointer offset trickery, unpacking and `pshufb`:
>
> **→ [asm.ruslan.beer](https://asm.ruslan.beer/)**

**Interactive Visualizations**

| Lesson | Topics |
| :---- | :---- |
| [Lesson 1](https://asm.ruslan.beer/lesson_01/viz-1-brighten.en.html) | the `brighten` SIMD loop · scalar stepper · `add_values` line by line |
| [Lesson 2](https://asm.ruslan.beer/lesson_02/viz-1-loops.en.html) | loops, labels and FLAGS · `[base + scale*index + disp]` addressing · `lea` |
| [Lesson 3](https://asm.ruslan.beer/lesson_03/viz-1-offset-trick.en.html) | pointer offset trickery · range expansion (`punpck`) · `pshufb` shuffles |

**Required Knowledge**

* Knowledge of C, in particular pointers. If you don't know C, work through [The C Programming Language](https://en.wikipedia.org/wiki/The_C_Programming_Language) book  
* High School Mathematics (scalar vs vector, addition, multiplication etc)

**Lessons**

In this Git repository there are lessons and assignments (not uploaded yet) that correspond with each lessons. By the end of the lessons you'll be able to contribute to FFmpeg.

A discord server is available to answer questions:
https://discord.com/invite/Ks5MhUhqfB

**Translations**

* [English](./README.md)
* [Français](./README.fr.md)
* [Spanish](./README.es.md)
* [Turkish](./README.tr.md)
* [中文](./README.zh.md)
