nasm -f elf32 writeBmp.asm -o writeBpm.o
ld -s -m elf_i386 writeBpm.o io.o -o main