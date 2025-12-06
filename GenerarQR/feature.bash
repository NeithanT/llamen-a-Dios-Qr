nasm -f elf32 $1.asm -o $1.o
ld -s -m elf_i386 $1.o io.o -o $1
./$1
rm $1