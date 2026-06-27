all: main main2

main2: main2.o pong_led.o pong.o
	gcc -no-pie main2.o pong.o pong_led.o -o main2

pong_led.o: pong_led.c
	gcc -c -DPLED_PLAYER_SIZE=2 pong_led.c -o pong_led.o

pong.o: pong.asm
	as pong.asm --defsym LEFT_OFFSET=2 --defsym RIGHT_OFFSET=3 --defsym ROW_OFFSET=2 --defsym PLAYER_SIZE=2 -o pong.o

main2.o: main2.c pong_led.c
	gcc -c main2.c -o main2.o

main: main.o
	ld main.o -o main


main.o: main.asm term.asm strings.asm
	as main.asm -o main.o

clean: 
	rm -f *.o
	rm main
	rm main2

