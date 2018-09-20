all: bf

bf: bf.o
	ld -m elf_i386 $< -o $@

bf.o: bf.asm
	nasm -f elf -Fstabs -l bf.lst $<
