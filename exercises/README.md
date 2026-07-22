# Hand-written x86 Assembly Exercises

Practice tasks for the [FFmpeg assembly lessons](../README.md). You write real
SIMD functions in `tasks.asm` using the same `x86inc.asm` abstraction layer
FFmpeg uses; a C harness verifies every byte against a reference
implementation and benchmarks your code.

Works natively on x86_64 Linux/macOS. On Apple Silicon the binary is built
for x86_64 and runs transparently through **Rosetta 2** — verified, the
lesson's `add_values` hits ~20 GB/s there.

## Prerequisites

- `nasm` (`brew install nasm` / `apt install nasm`)
- `clang` or `gcc`
- macOS on Apple Silicon: Rosetta 2 (`softwareupdate --install-rosetta`)

## Workflow

```bash
make run
```

Expected output while tasks are unsolved:

```
  add_values     OK      51.1 µs/MB (20.54 GB/s)
  invert         FAIL: byte 0: asm=112, ref=143
  brighten_sat   FAIL: byte 0: asm=112, ref=152
  rgba_to_bgra   FAIL: byte 0: asm=112, ref=186
```

Edit the `TODO` sections in `tasks.asm`, run `make run` again, repeat until
everything says `OK`. The harness (`main.c`) compares your output against a
scalar C reference on a 1 MB buffer, then benchmarks 200 runs.

Task 0 (`add_values`) is already solved — it is the pointer-offset-trick
function from lesson 3 and doubles as a toolchain check. Use it as the
template for your loops.

## Tasks

### 1. `invert` — image negative *(warm-up: loop + constant)*

`src[i] = 255 - src[i]` for every byte. Real-world use: mask inversion,
photo negatives.

Key idea: `255 - x == x XOR 255`. Declare a 16-byte constant of `0xFF` in
`SECTION_RODATA` (`times 16 db 0xFF`), load it once before the loop, apply
`pxor` inside. The loop skeleton is task 0 with a single buffer.

### 2. `brighten_sat` — brightness with saturation *(find the right instruction)*

`src[i] = min(src[i] + 40, 255)`. Plain `paddb` from lesson 1 wraps around:
250 + 40 = 34, bright areas turn dark. Your job is to find the **saturating
unsigned byte add** in the [instruction reference](https://www.felixcloutier.com/x86/)
(hint: the `padd?b` family; recall what "saturated" meant for `packuswb` in
lesson 3). Declare the constant `times 16 db 40` in RODATA and build the loop
around that instruction. Finding the right instruction for the job is,
per the lesson itself, half the craft of x86 SIMD.

### 3. `rgba_to_bgra` — swap color channels *(pshufb from lesson 3.3)*

OpenCV stores BGR, nearly everything else stores RGB — this conversion runs
in every computer-vision pipeline. 16 bytes = exactly 4 RGBA pixels, so one
`pshufb` with the right mask swaps R↔B in all four pixels at once.

Two intentional traps:

1. The `bgra_shuffle` mask at the top of `tasks.asm` is currently the
   identity permutation — compute the real indices yourself (each output
   byte = index of the input byte to take).
2. `pshufb` is **SSSE3**, but the skeleton says `INIT_XMM sse2`. Fix the
   INIT line and watch the exported symbol name change — then fix the
   declaration in `main.c` to match (`_sse2` → `_ssse3`). That suffix is
   exactly how FFmpeg names per-CPU variants (`ff_foo_sse2`, `ff_foo_avx2`)
   for its runtime dispatcher.

## Rules of thumb

- Speed target: same order of magnitude as task 0 (~20 GB/s). Much slower →
  something is wrong (scalar loop, per-byte processing, accidental store
  inside a dependency chain).
- Instruction reference: <https://www.felixcloutier.com/x86/> ·
  visual SIMD diagrams: <https://www.officedaytime.com/simd512e/>
- Interactive walkthroughs of every concept used here:
  <https://asm.ruslan.beer/>

## Level-ups (after all three pass)

- Rewrite `invert` with `INIT_YMM avx2` — one line change, 32-byte windows.
  What else has to change in `main.c`?
- Add a runtime dispatcher in C: build both `_sse2` and `_avx2` variants and
  pick via `__builtin_cpu_supports("avx2")` — the FFmpeg function-pointer
  pattern from lesson 3.
- Handle widths that are not a multiple of `mmsize` (scalar tail loop).

## Files

| file | purpose |
|---|---|
| `tasks.asm` | your code — task skeletons with TODOs |
| `main.c` | verification + benchmark harness |
| `x86inc.asm` | FFmpeg's abstraction layer (fetched from FFmpeg master) |
| `Makefile` | nasm → macho64 x86_64 build, see flags for the x86inc config defines |
