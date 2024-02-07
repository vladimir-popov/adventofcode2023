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

solution.c.out: ./*.c
	@echo Compiling $@
	@$(CC) $(ASANFLAGS) $(CFLAGS) ./*.c -o solution.c.out $(LIBS)

.PHONY: compile
compile: solution.c.out
	@echo "solution compiled sucsessfully"

.PHONY: test
test: solution.c.out
	./solution.c.out test.txt

.PHONY: solve
solve: solution.c.out
	./solution.c.out input.txt

.PHONY: clean
clean:
	rm -rf *.o *.out *.out.dSYM

.DEFAULT_GOAL: compile
