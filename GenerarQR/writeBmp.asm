%include "io.mac"

.DATA
    File            db "test.bmp", 0
    File_descriptor dd 0
    cool            db "Compiles", 0
    

; Header 	14 bytes 	Windows Structure: BITMAPFILEHEADER
; 0x00 	Signature 	2 bytes 	'BM'
    Signature       db "BM"
; 0x02 	FileSize 	4 bytes 	File size in bytes
    FileSize        dd 1954
; 0x06 	Reserved 	4 bytes 	unused (=0)
    Reserved        dd 0
; 0x0a 	DataOffset 	4 bytes 	File offset to Raster Data
    DataOffset      dd 54


; InfoHeader 	40 bytes 	Windows Structure: BITMAPINFOHEADER
; 0x0e 	Size 	4 bytes 	Size of InfoHeader =40
    Size            dd 40
; 0x12 	Width 	4 bytes 	Bitmap Width
    Width           dd 25
; 0x16 	Height 	4 bytes 	Bitmap Height
    Height          dd 25
; 0x1a 	Planes 	2 bytes 	Number of Planes (=1)
    Planes          dw 1
; 0x1c 	BitCount 	2 bytes 	Bits per Pixel
    BitCount        dw 24
; 1 = monochrome palette. NumColors = 1  
; 4 = 4bit palletized. NumColors = 16  
; 8 = 8bit palletized. NumColors = 256 
; 16 = 16bit RGB. NumColors = 65536 (?) 
; 24 = 24bit RGB. NumColors = 16M
; 0x1e 	Compression 	4 bytes 	Type of Compression
    Compression     dd 0
; 0 = BI_RGB   no compression  
; 1 = BI_RLE8 8bit RLE encoding  
; 2 = BI_RLE4 4bit RLE encoding
; 0x22 	ImageSize 	4 bytes 	(compressed) Size of Image 
    ImageSize       dd 1900
; It is valid to set this = 0 if Compression = 0
; 0x26 	XpixelsPerM 	4 bytes 	horizontal resolution: Pixels/meter
    XpixelsPerM     dd 0
; 0x2a 	YpixelsPerM 	4 bytes 	vertical resolution: Pixels/meter
    YpixelsPerM     dd 0
; 0x2e 	ColorsUsed 	4 bytes 	Number of actually used colors
    ColorsUsed      dd 0
; 0x32 	ColorsImportant 	4 bytes 	Number of important colors
    ColorsImportant dd 0
; 0 = all
; 0x36 	ColorTable 	4 * NumColors bytes 	present only if Info.BitsPerPixel <= 8
; colors should be ordered by importance

    White           db 0xFF
    
.UDATA

    buffer  resb 1900 ; 76 * 25 ; 76 bytes per row, 25 rows
    bufTwo  resb 1875

.CODE


.STARTUP

open_file:

    mov EAX, 5
    mov EBX, File
    mov ECX, 65  ; O_WRONLY | O_CREAT
    mov EDX, 0x1A4  ; file permissions (0644)
    int 0x80

    mov [File_descriptor], EAX


create_header:

    ; Write BITMAPFILEHEADER (14 bytes)
    mov EAX, 4 ; write mode
    mov EBX, [File_descriptor]
    mov ECX, Signature
    mov EDX, 2
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, FileSize
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, Reserved
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, DataOffset
    mov EDX, 4
    int 0x80

    ; Write BITMAPINFOHEADER (40 bytes)
    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, Size
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, Width
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, Height
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, Planes
    mov EDX, 2
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, BitCount
    mov EDX, 2
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, Compression
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, ImageSize
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, XpixelsPerM
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, YpixelsPerM
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, ColorsUsed
    mov EDX, 4
    int 0x80

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, ColorsImportant
    mov EDX, 4
    int 0x80

write_pixels:

    mov ESI, 1900

write_loop:

    mov EAX, 4
    mov EBX, [File_descriptor]
    mov ECX, White
    mov EDX, 1
    int 0x80

    dec ESI
    cmp ESI, 0
    jge write_loop

done:


    .EXIT