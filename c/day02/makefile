LIBS = -lm

###
CFLAGS  = -std=c99
CFLAGS += -g
CFLAGS += -Wall
CFLAGS += -Wextra
CFLAGS += -pedantic
CFLAGS += -Werror
CFLAGS += -Wmissing-declarations
CFLAGS += -DUNITY_SUPPORT_64 -DUNITY_OUTPUT_COLOR

ASANFLAGS  = -fsanitize=address
ASANFLAGS += -fno-common
ASANFLAGS += -fno-omit-frame-pointer

day02.c.out: ./*.c
	@echo Compiling $@
	@$(CC) $(ASANFLAGS) $(CFLAGS) ./*.c -o day02.c.out $(LIBS)

.PHONY: compile
compile: day02.c.out
	@echo "day02 compiled sucsessfully"

.PHONY: test
test: day02.c.out
	./day02.c.out test.txt

.PHONY: solve
solve: day02.c.out
	./day02.c.out input.txt

.PHONY: clean
clean:
	rm -rf *.o *.out *.out.dSYM

.DEFAULT_GOAL: compile
