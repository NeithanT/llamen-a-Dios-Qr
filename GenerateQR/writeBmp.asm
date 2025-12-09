;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; writeBmp.asm - BMP File Header Module
; =============================================================================
; This module handles writing the BMP file header and info header
; =============================================================================

%include "io.mac"

section .data
    ; QR Parameters
    QUIET_ZONE      equ 4               ; 4 modules quiet zone
    IMG_SIZE        equ 33              ; (25 + 8) * 1 = 33 pixels
    
    ; BMP row must be multiple of 4 bytes
    ; 33 * 3 = 99 bytes per row (99 mod 4 = 3, need 1 padding byte)
    ROW_SIZE        equ 100             ; 99 + 1 padding
    PIXEL_DATA_SIZE equ 3300            ; 100 * 33

    ; BMP File Header (14 bytes)
    Signature       db "BM"
    FileSize        dd 3354             ; 54 + 3300
    Reserved        dd 0
    DataOffset      dd 54

    ; BMP Info Header (40 bytes)  
    InfoSize        dd 40
    Width           dd 33
    Height          dd 33
    Planes          dw 1
    BitCount        dw 24
    Compression     dd 0
    ImageSize       dd 3300
    XpixelsPerM     dd 2835
    YpixelsPerM     dd 2835
    ColorsUsed      dd 0
    ColorsImportant dd 0

section .text

; =============================================================================
; write_bmp_headers
; Input: EBX = file descriptor
; =============================================================================
global write_bmp_headers
write_bmp_headers:
    pusha
    
    mov EAX, 4                                                                  ; sys_write
    mov ECX, Signature                                                          ; ECX now points to Signature
    mov EDX, 14                                                                 ; 14 bytes to write
    int 0x80                                                                    ; write file header
    
    mov EAX, 4                                                                  ; sys_write
    mov ECX, InfoSize                                                           ; ECX now points to InfoSize
    mov EDX, 40                                                                 ; 40 bytes to write
    int 0x80                                                                    ; write info header
    
    popa
    ret

; =============================================================================
; open_bmp_file
; Input: ESI = pointer to filename string
; Output: EAX = file descriptor
; =============================================================================
global open_bmp_file
open_bmp_file:
    push EBX
    push ECX
    push EDX
    
    mov EBX, ESI                                                                ; EBX now points to filename
    mov ECX, 65                                                                 ; O_CREAT | O_WRONLY
    mov EDX, 0x1A4                                                              ; permissions 0644
    mov EAX, 5                                                                  ; sys_open
    int 0x80                                                                    ; open file
    
    pop EDX
    pop ECX
    pop EBX
    ret

; =============================================================================
; close_bmp_file
; Input: EBX = file descriptor
; =============================================================================
global close_bmp_file
close_bmp_file:
    push EAX
    
    mov EAX, 6                                                                  ; sys_close
    int 0x80                                                                    ; close file
    
    pop EAX
    ret
