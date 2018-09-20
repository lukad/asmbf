all: bf

bf: bf.o
	ld -m elf_i386 $< -o $@

bf.o: bf.asm
	nasm -f elf $<

docker:
	docker build -t asmbf .
	docker create --name asmbf asmbf
	docker cp asmbf:/build/bf .
	docker rm asmbf
