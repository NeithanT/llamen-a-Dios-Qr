;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; encode.asm - QR Code Data Encoding Module
; =============================================================================
; This module handles encoding input data into QR code format:
; - Mode indicator (byte mode)
; - Character count
; - Data bytes
; - Terminator and padding
; =============================================================================

%include "io.mac"

section .data
    ; QR encoding constants
    MODE_BYTE       equ 0b0100          ; Byte mode indicator
    DATA_CODEWORDS  equ 28              ; Version 2-M data capacity
    
    ; Padding bytes
    PAD1            equ 0xEC
    PAD2            equ 0x11
    
    ; Bit stream accumulator
    bit_accum       dd 0
    bit_count       dd 0
    byte_pos        dd 0
    
    ; Global pointer to output buffer
    encoded_data_ptr dd 0

section .text

; =============================================================================
; encode_data_stream
; Input: 
;   ESI = pointer to input data
;   EDI = length of input data
;   [ESP+36] (after pusha) = pointer to encoded_data buffer (28 bytes)
; Output:
;   encoded_data buffer filled with encoded data
; =============================================================================
global encode_data_stream
encode_data_stream:
    push EBP                                                                    ; Put EBP into the stack
    mov EBP, ESP                                                                ; EBP has now ESP value
    pusha                                                                       ; Put all register in the stack
    
    ; Get encoded_data pointer and save to global variable
    mov EBX, [EBP + 8]                                                          ; Get encoded_data pointer from stack
    mov [encoded_data_ptr], EBX                                                 ; Save to global variable
    
    ; Clear encoded_data buffer
    push EDI                                                                    ; push EDI into the stack
    mov ECX, DATA_CODEWORDS                                                     ; Make the counter 28
    xor EAX, EAX
    mov EDI, EBX                                                                ; EDI now points at the same location as EBX
    rep stosb                                                                   ; repites stosb
    pop EDI                                                                     ; whatever was in the stack is now in EDI
    
    ; Save input length
    push EDI                                                                    ; Save input length
    
    ; Initialize bit stream
    mov dword [bit_accum], 0                                                     
    mov dword [bit_count], 0
    mov dword [byte_pos], 0
    
    ; Push mode indicator (4 bits)
    mov EAX, MODE_BYTE                                                          ; now EAX stores the mode byte
    mov ECX, 4                                                                  
    call push_bits                                                              ; calls push_bits method
    
    ; Push character count (8 bits)
    mov EAX, [ESP]                                                              ; Get length from stack
    mov ECX, 8
    call push_bits
    
    ; Push data bytes
    mov EDI, [ESP]                                                              ; Get length
    
.encode_loop:
    test EDI, EDI                                                               ; test if EDI is zero
    jz .add_terminator                                                          ; if the comparison result is zero, jump to add_terminator
    
    movzx EAX, byte [ESI]                                                       ; move the byte pointed by ESI to EAX
    mov ECX, 8
    call push_bits
    
    inc ESI
    dec EDI
    jmp .encode_loop                                                            ; no matter what, jump to .encode_loop
    
.add_terminator:
    ; Add terminator (4 bits of 0)
    mov EAX, 0
    mov ECX, 4
    call push_bits
    
    ; Flush remaining bits
    call flush_bits
    
    ; Pad to DATA_CODEWORDS bytes
    mov EBX, [encoded_data_ptr]                                                 ; Use global variable
    mov EDI, [byte_pos]                                                         ; move it to EDI
    mov AL, PAD1                                                                
    
.pad_loop:
    cmp EDI, DATA_CODEWORDS                                                     ; compare EDI with 28
    jge .encode_done                                                            ; if EDI is greater or equal, jumps to .encode_done
    
    mov byte [EBX + EDI], AL                                                    ; move the value of AL to the byte pointed
    inc EDI
    
    cmp AL, PAD1                                                                ; comparisons
    jne .use_pad1
    mov AL, PAD2
    jmp .pad_loop
.use_pad1:
    mov AL, PAD1
    jmp .pad_loop
    
.encode_done:
    add ESP, 4                                                                  ; Clean up local variables (only input length)
    popa                                                                        ; pop out all the registers
    pop EBP                                                                     ; pops EBP
    ret                                                                         ; returns to the point called

; =============================================================================
; push_bits
; Input:
;   EAX = value to push
;   ECX = number of bits to push
; Uses global variable: encoded_data_ptr (set by encode_data_stream)
; Modifies: bit_accum, bit_count, byte_pos
; =============================================================================
push_bits:
    push EBX                                                                    
    push EDX
    push ESI
    push EDI
    
.push_loop:
    test ECX, ECX                                                               ; test if ECX is zero
    jz .push_done                                                               ; if zero jumps to .push_done
    
    ; Shift accumulator left
    shl dword [bit_accum], 1                                                    ; shift one dword in bit_accum to the left changing the value
    
    ; Extract bit from value
    mov EBX, ECX
    dec EBX
    mov EDX, EAX
    push ECX                                                                    ; put ECX in the stack
    mov CL, BL
    shr EDX, CL                                                                 ; shift EDX value CL times to the right
    pop ECX                                                                     ; pops it out
    and EDX, 1
    
    ; Add bit to accumulator
    or [bit_accum], EDX                                                         ; bitwise OR between bit_accum and EDX, result stored in bit_accum
    inc dword [bit_count]                                                            
    
    ; Check if we have a complete byte
    cmp dword [bit_count], 8                                                    ; compare bit_count with 8  
    jl .next_bit                                                                ; if less jumps to .next_bit
    
    ; Write byte to encoded_data
    mov ESI, [byte_pos]                                                         ; move byte_pos to ESI                                                       
    cmp ESI, DATA_CODEWORDS                                                     ; compare byte_pos with 28                                            
    jge .next_bit
    
    push EAX
    mov EDI, [encoded_data_ptr]                                                 ; Use global variable instead of stack
    add EDI, ESI                                                                ; now points to the correct byte in encoded_data
    mov EAX, [bit_accum]                                                        
    mov [EDI], AL                                                               ; store the least significant byte of bit_accum into encoded_data
    pop EAX
    
    inc dword [byte_pos]           
    mov dword [bit_accum], 0                                                    ; clear bit_accum                  
    mov dword [bit_count], 0                                                    ; clear bit_count
    
.next_bit:
    dec ECX
    jmp .push_loop
    
.push_done:                                                                     ; pull everything out of the stack
    pop EDI
    pop ESI
    pop EDX
    pop EBX
    ret

; =============================================================================
; flush_bits
; Flush remaining bits in accumulator to encoded_data
; Uses global variable: encoded_data_ptr
; =============================================================================
flush_bits:                                                                     ; push everything to the stack
    push EAX
    push EBX
    push ECX
    push EDI
    
    mov ECX, [bit_count]                                                        ; move bit_count to ECX                 
    test ECX, ECX                                                               ; test if bit_count is zero         
    jz .flush_done
    
    ; Pad remaining bits with 0
    mov EAX, [bit_accum]                                                        ; move bit_accum to EAX                        
    mov EBX, 8                                                                  
    sub EBX, ECX
    
.pad_bits:
    test EBX, EBX                                                               ; test if EBX is zero   
    jz .write_final                                                             ; if zero jumps to .write_final                              
    shl EAX, 1                                                                  ; shift EAX to the left by 1                                 
    dec EBX
    jmp .pad_bits
    
.write_final:
    mov EBX, [byte_pos]                                                         ; move byte_pos to EBX
    cmp EBX, DATA_CODEWORDS                                                     ; compare byte_pos with 28
    jge .flush_done                                                             ; if greater or equal jumps to .flush_done                            
    
    mov EDI, [encoded_data_ptr]                                                 ; Use global variable
    add EDI, EBX                                                                ; now points to the correct byte in encoded_data                                
    mov [EDI], AL                                                               ; store the least significant byte of bit_accum into encoded_data
    inc dword [byte_pos]
    mov dword [bit_accum], 0
    mov dword [bit_count], 0
    
.flush_done:                                                                    ; pull everything out of the stack                         
    pop EDI
    pop ECX
    pop EBX
    pop EAX
    ret
