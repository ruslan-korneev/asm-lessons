# Сборка x86_64-бинарника; на Apple Silicon он прозрачно бежит через Rosetta 2.
NASM      = nasm
NASMFLAGS = -f macho64 -I. -DPREFIX -DPIC \
            -Dprivate_prefix=ex -DARCH_X86_64=1 -DHAVE_ALIGNED_STACK=1 -DHAVE_CPUNOP=0
CC        = clang
CFLAGS    = -arch x86_64 -O2 -Wall

test: main.c tasks.o
	$(CC) $(CFLAGS) main.c tasks.o -o test

tasks.o: tasks.asm x86inc.asm
	$(NASM) $(NASMFLAGS) tasks.asm -o tasks.o

run: test
	./test

clean:
	rm -f tasks.o test

.PHONY: run clean
