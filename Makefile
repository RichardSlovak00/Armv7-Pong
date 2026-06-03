clean: main.o
	rm main.o

main: main.o
	ld main.o -o main

main.o: main.asm term.asm strings.asm
	as main.asm -o main.o
