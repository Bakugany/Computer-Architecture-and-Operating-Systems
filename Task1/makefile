CC       = gcc
CFLAGS   = -Wall -Wextra -Wno-implicit-fallthrough -std=gnu17 -fPIC -O2
LDFLAGS  = -Wl,--wrap=malloc -Wl,--wrap=calloc -Wl,--wrap=realloc -Wl,--wrap=reallocarray -Wl,--wrap=free -Wl,--wrap=strdup -Wl,--wrap=strndup

.PHONY: all clean

all: libnand.so nand_example nand_example_static

nand.o: nand.c nand.h
memory_tests.o: memory_tests.c memory_tests.h
nand_example.o: nand_example.c memory_tests.h nand.h

libnand.so: LDFLAGS += -shared
libnand.so: nand.o memory_tests.o
	$(CC) -o $@ $^ $(LDFLAGS)

nand_example_static: nand_example.o nand.o memory_tests.o
	$(CC) -o $@ $^ $(LDFLAGS)

nand_example: nand_example.o libnand.so
	$(CC) -Wl,--rpath='.' -L. -o $@ $< -lnand

clean:
	rm -rf nand_example *.so *.o
	rm -rf nand_example_static *.o
