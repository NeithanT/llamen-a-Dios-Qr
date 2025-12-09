;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; QR Code Reader - Data Extraction Module
; Handles extraction of data bits from the QR matrix following the zigzag
; pattern, skipping function patterns, and applying mask removal.
; =============================================================================

%include "qrReadConstants.inc"

section .text

; External symbols
extern qr_matrix
extern is_function
extern encoded_data
extern data_idx
extern bit_idx

; Exported functions
global extract_data_bits
global read_module

; extract_data_bits - extracts the actual DATA BITS, not that weird finder blah blah things
; goes on the matrix in zigzag pattern

extract_data_bits:
    pusha
    
    ; Initialize extraction state
    mov dword [data_idx], 0 ; index of the actual data
    mov dword [bit_idx], 7  ; this is the bit inside of a byte offset
    mov byte [encoded_data], 0  ; Clear first byte in encoded data
                                ; encoded data is a 44byte array
    
    mov EAX, 24                 ; x coordinate (start from rightmost column)
    xor ECX, ECX                ; direction (0=up, 1=down)
    
.col_pair:
    ; Check if we have processed all columns
    cmp EAX, 0 ; it goes right to left, so when is 0 is done
    jl .extract_done ; finish
    
    ; Skip vertical timing column (column 6); this is the -=-=-= column
    cmp EAX, 6
    jne .process_pair ; else we have to process

    dec EAX ; otherwise go to the next
    cmp EAX, 0 ; check if end
    jl .extract_done ; go to end
    
.process_pair:
    ; Check direction for the zigzag: up (0) or down (1)
    test ECX, 1 ; see if it's down
    jnz .go_down ; go down then
    
    ; Going UP: start from bottom (y=24) to top (y=0)
    mov EBX, 24                 ; y start (bottom)

; this is the loop for when it is time to go up
.up_loop:

    cmp EBX, 0 ; check if we have ended
    jl .next_pair ; if we ended y, go to next pair
    
    ; Read right column of pair
    push EAX ; save used registers
    push EBX
    push ECX
    call read_module ; read the right pixel
    pop ECX ; restore the registers, not rlly neccesary but for alligment reasons im scared for my god damn life ...
    pop EBX
    pop EAX
    
    ; Read left column of pair
    push EAX ; save registers
    push EBX
    push ECX
    dec EAX ; get the left column
    call read_module ; read the byte in the left pixel
    pop ECX
    pop EBX
    pop EAX
    ; restore registers

    dec EBX ; go next iteration
    jmp .up_loop
    
.go_down:
    ; Going DOWN: start from top (y=0) to bottom (y=24)
    mov EBX, 0                  ; y start (top)
.down_loop:
    cmp EBX, QR_SIZE
    jge .next_pair
    
    ; Read right column of pair
    push EAX
    push EBX
    push ECX
    call read_module
    pop ECX
    pop EBX
    pop EAX
    
    ; Read left column of pair
    push EAX
    push EBX
    push ECX
    dec EAX
    call read_module
    pop ECX
    pop EBX
    pop EAX
    
    inc EBX
    jmp .down_loop
    
.next_pair:
    ; Alternate direction and move to next column pair
    inc ECX
    sub EAX, 2
    jmp .col_pair
    
.extract_done:
    popa
    ret

;---------------------------------------------------------------------------
; read_module - Reads a single byte from QR matrix
; Input: EAX = x coordinate
;        EBX = y coordinate
; checks for function patterns and skips then, applies mask removal (Mask 0 in our case),
; and appends bit to encoded_data buffer!
;---------------------------------------------------------------------------

read_module:

    pusha ; save all registers
    
    ; Bounds check
    cmp EAX, 0 ; in case of errors
    jl .rm_done ; the read is done
    
    ; Skip vertical timing column (column 6)
    cmp EAX, 6 ; skip the timing 
    je .rm_done ; the read is done
    
    ; Calculate matrix offset: y * QR_SIZE + x
    mov EDI, EBX ; move the y cordinate
    imul EDI, QR_SIZE ; multiplcate by 25
    add EDI, EAX ; add EAX the x 
    
    ; Skip if this is a function pattern
    cmp byte [is_function + EDI], 0 ; check the function matrix to see it is occupied
    jne .rm_done ; if it is occupied, done
    
    ; Read bit from matrix
    movzx EDX, byte [qr_matrix + EDI] ;  move with zero whatever the value in the qr matrix is
    
    ; Apply Mask 0: the mask modulo ! 
    ; we can to Unmask if (x+y) % 2 == 0
    mov ESI, EAX ; mov x to ESI
    add ESI, EBX ; add y for x + y
    and ESI, 1 ; check if is divisible by 2 using an and mask
    jnz .no_invert ; if it is, do not invert 
    xor EDX, 1 ; inverts even to odd or odd to even ! apply the mask
    
.no_invert:
    ; Append bit to encoded_data
    ; Shift bit to appropriate position
    mov ECX, [bit_idx]
    shl EDX, CL ; shift left 7...6...5 times!, so 0000 0001 becomes 1000 0000 for the first iteration
                ; this basically goes and counts bits and then places them in DL technically
    
    ; OR with current byte
    mov ESI, [data_idx] ; move the data idx to save the data
    or byte [encoded_data + ESI], DL ; sum the current state
    
    ; Move to next bit position
    dec dword [bit_idx] ; go to the next bit, now it only shifts 6 ... 5 ... 4 ... etc
    cmp dword [bit_idx], 0 ; check if its done when bits equal 0
    jge .rm_done ; it is done
    
    ; Wrapped to next byte
    mov dword [bit_idx], 7 ; get back to index 7 of bit
    inc dword [data_idx] ; increase data index to go to the next byte 
    mov ESI, [data_idx] ; move the index to ESI to be accesible
    mov byte [encoded_data + ESI], 0 ; Clear next byte
    
.rm_done:
    popa    ; restore
    ret
