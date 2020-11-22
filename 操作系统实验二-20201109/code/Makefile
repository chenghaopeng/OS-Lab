CXX = g++
CXXFLAGS = -Wall -Werror -Wextra -m32
# CXXFLAGS = -m32 -g
NASM = nasm
NASMFLAGS = -f elf32

EXEC = main

all: $(EXEC)

$(EXEC): my_print.o main.o
	$(CXX) -o $@ $(CXXFLAGS) $^

my_print.o: my_print.asm
	$(NASM) -o $@ $(NASMFLAGS) $<

main.o: main.cpp
	$(CXX) -c -o $@ $(CXXFLAGS) $<

clean:
	rm my_print.o
	rm main.o
	rm main