# Compile QR Generator
nasm -f elf32 -I GenerateQR/ GenerateQR/encode.asm -o GenerateQR/encode.o
nasm -f elf32 -I GenerateQR/ GenerateQR/errorBytes.asm -o GenerateQR/errorBytes.o
nasm -f elf32 -I GenerateQR/ GenerateQR/mask.asm -o GenerateQR/mask.o
nasm -f elf32 -I GenerateQR/ GenerateQR/writeBmp.asm -o GenerateQR/writeBmp.o
nasm -f elf32 -I GenerateQR/ GenerateQR/writeQr.asm -o GenerateQR/writeQr.o
nasm -f elf32 -I GenerateQR/ GenerateQR/qrGenerator.asm -o GenerateQR/qrGenerator.o

# Compile QR Reader
nasm -f elf32 -I ScanQR/ ScanQR/qrReadIO.asm -o ScanQR/qrReadIO.o
nasm -f elf32 -I ScanQR/ ScanQR/qrReadFunctionMap.asm -o ScanQR/qrReadFunctionMap.o
nasm -f elf32 -I ScanQR/ -I GenerateQR/ ScanQR/qrReadExtract.asm -o ScanQR/qrReadExtract.o
nasm -f elf32 -I ScanQR/ -I GenerateQR/ ScanQR/qrReadDecode.asm -o ScanQR/qrReadDecode.o
nasm -f elf32 -I ScanQR/ -I GenerateQR/ ScanQR/qrRead.asm -o ScanQR/qrRead.o


# Compile C file and link (32-bit)
gcc -m32 -o main \
    InterfazGrafica/main.c \
    GenerateQR/qrGenerator.o \
    GenerateQR/encode.o \
    GenerateQR/errorBytes.o \
    GenerateQR/mask.o \
    GenerateQR/writeBmp.o \
    GenerateQR/writeQr.o \
    ScanQR/qrRead.o \
    ScanQR/qrReadIO.o \
    ScanQR/qrReadFunctionMap.o \
    ScanQR/qrReadExtract.o \
    ScanQR/qrReadDecode.o \
    GenerateQR/io.o \
    $(pkg-config --cflags --libs gtk4 gdk-pixbuf-2.0)

# Clean individual .o files (keep main executable and io.o)
rm GenerateQR/encode.o GenerateQR/errorBytes.o GenerateQR/mask.o GenerateQR/writeBmp.o GenerateQR/writeQr.o GenerateQR/qrGenerator.o ScanQR/*.o