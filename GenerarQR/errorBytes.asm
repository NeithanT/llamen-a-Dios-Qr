;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; errorBytes.asm - Reed-Solomon Error Correction Module
; =============================================================================
; This module handles Reed-Solomon error correction code generation
; for QR codes using Galois Field GF(2^8) arithmetic
; =============================================================================

%include "io.mac"

section .data
    ; Error correction constants
    DATA_CODEWORDS  equ 28              ; Version 2-M data capacity
    EC_CODEWORDS    equ 16              ; Version 2-M EC codewords
    
    ; ==========================================================================
    ; Reed-Solomon Generator Polynomial for 16 EC codewords
    ; ==========================================================================
    gen_poly        db 1, 59, 13, 104, 189, 68, 209, 30, 8, 163, 65, 41, 229, 98, 50, 36, 59
    
    ; ==========================================================================
    ; Galois Field GF(2^8) tables with primitive polynomial 0x11D
    ; ==========================================================================
    gf_exp  db   1,   2,   4,   8,  16,  32,  64, 128,  29,  58, 116, 232, 205, 135,  19,  38
            db  76, 152,  45,  90, 180, 117, 234, 201, 143,   3,   6,  12,  24,  48,  96, 192
            db 157,  39,  78, 156,  37,  74, 148,  53, 106, 212, 181, 119, 238, 193, 159,  35
            db  70, 140,   5,  10,  20,  40,  80, 160,  93, 186, 105, 210, 185, 111, 222, 161
            db  95, 190,  97, 194, 153,  47,  94, 188, 101, 202, 137,  15,  30,  60, 120, 240
            db 253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, 163,  91, 182, 113, 226
            db 217, 175,  67, 134,  17,  34,  68, 136,  13,  26,  52, 104, 208, 189, 103, 206
            db 129,  31,  62, 124, 248, 237, 199, 147,  59, 118, 236, 197, 151,  51, 102, 204
            db 133,  23,  46,  92, 184, 109, 218, 169,  79, 158,  33,  66, 132,  21,  42,  84
            db 168,  77, 154,  41,  82, 164,  85, 170,  73, 146,  57, 114, 228, 213, 183, 115
            db 230, 209, 191,  99, 198, 145,  63, 126, 252, 229, 215, 179, 123, 246, 241, 255
            db 227, 219, 171,  75, 150,  49,  98, 196, 149,  55, 110, 220, 165,  87, 174,  65
            db 130,  25,  50, 100, 200, 141,   7,  14,  28,  56, 112, 224, 221, 167,  83, 166
            db  81, 162,  89, 178, 121, 242, 249, 239, 195, 155,  43,  86, 172,  69, 138,   9
            db  18,  36,  72, 144,  61, 122, 244, 245, 247, 243, 251, 235, 203, 139,  11,  22
            db  44,  88, 176, 125, 250, 233, 207, 131,  27,  54, 108, 216, 173,  71, 142,   1
    
    gf_log  db   0,   0,   1,  25,   2,  50,  26, 198,   3, 223,  51, 238,  27, 104, 199,  75
            db   4, 100, 224,  14,  52, 141, 239, 129,  28, 193, 105, 248, 200,   8,  76, 113
            db   5, 138, 101,  47, 225,  36,  15,  33,  53, 147, 142, 218, 240,  18, 130,  69
            db  29, 181, 194, 125, 106,  39, 249, 185, 201, 154,   9, 120,  77, 228, 114, 166
            db   6, 191, 139,  98, 102, 221,  48, 253, 226, 152,  37, 179,  16, 145,  34, 136
            db  54, 208, 148, 206, 143, 150, 219, 189, 241, 210,  19,  92, 131,  56,  70,  64
            db  30,  66, 182, 163, 195,  72, 126, 110, 107,  58,  40,  84, 250, 133, 186,  61
            db 202,  94, 155, 159,  10,  21, 121,  43,  78, 212, 229, 172, 115, 243, 167,  87
            db   7, 112, 192, 247, 140, 128,  99,  13, 103,  74, 222, 237,  49, 197, 254,  24
            db 227, 165, 153, 119,  38, 184, 180, 124,  17,  68, 146, 217,  35,  32, 137,  46
            db  55,  63, 209,  91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190,  97
            db 242,  86, 211, 171,  20,  42,  93, 158, 132,  60,  57,  83,  71, 109,  65, 162
            db  31,  45,  67, 216, 183, 123, 164, 118, 196,  23,  73, 236, 127,  12, 111, 246
            db 108, 161,  59,  82,  41, 157,  85, 170, 251,  96, 134, 177, 187, 204,  62,  90
            db 203,  89,  95, 176, 156, 169, 160,  81,  11, 245,  22, 235, 122, 117,  44, 215
            db  79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168,  80,  88, 175

section .bss
    msg_poly        resb 64             ; Message polynomial buffer

section .text

; =============================================================================
; compute_reed_solomon
; Input: 
;   ESI = pointer to encoded_data (28 bytes)
;   EDI = pointer to ec_data buffer (16 bytes)
; Output:
;   [ec_data] filled with error correction bytes
; =============================================================================
global compute_reed_solomon
compute_reed_solomon:
    pusha                                                                       ; put all registers in the stack
    
    ; Clear ec_data buffer
    push EDI
    mov ECX, EC_CODEWORDS                                                       ; make the counter 16
    xor EAX, EAX
    rep stosb                                                                   ; repeats stosb
    pop EDI
    
    ; Copy encoded_data to msg_poly
    push ESI
    push EDI
    mov ECX, DATA_CODEWORDS                                                     ; make the counter 28
    mov EDI, msg_poly                                                           ; EDI now points to msg_poly
    rep movsb                                                                   ; repeats movsb
    pop EDI
    pop ESI
    
    ; Zero-pad msg_poly for EC bytes (at position msg_poly + DATA_CODEWORDS)
    push EDI
    mov EDI, msg_poly                                                           ; EDI now points to msg_poly
    add EDI, DATA_CODEWORDS                                                     ; Point to msg_poly[28]
    mov ECX, EC_CODEWORDS                                                       ; make the counter 16
    xor EAX, EAX
    rep stosb                                                                   ; repeats stosb
    pop EDI
    
    ; Perform Reed-Solomon division
    push ESI
    push EDI
    mov ESI, 0                                                                  ; ESI is now 0
    
.rs_loop:
    cmp ESI, DATA_CODEWORDS                                                     ; compare ESI with 28
    jge .rs_done                                                                ; if greater or equal, jump to .rs_done
    
    ; Get current coefficient
    movzx EAX, byte [msg_poly + ESI]                                            ; move the byte pointed by msg_poly + ESI to EAX
    test EAX, EAX                                                               ; test if EAX is zero
    jz .rs_next                                                                 ; if zero, jump to .rs_next
    
    push ESI
    
    ; Get log of coefficient
    movzx EBX, byte [gf_log + EAX]                                              ; move log value to EBX
    
    ; Multiply generator polynomial by coefficient and XOR with msg_poly
    mov ECX, 0                                                                  ; ECX is now 0
.mult_gen:
    cmp ECX, 17                                                                 ; compare ECX with 17
    jge .mult_done                                                              ; if greater or equal, jump to .mult_done
    
    ; Get generator coefficient
    movzx EAX, byte [gen_poly + ECX]                                            ; move the byte pointed by gen_poly + ECX to EAX
    test EAX, EAX                                                               ; test if EAX is zero
    jz .skip_term                                                               ; if zero, jump to .skip_term
    
    ; Multiply in GF(256)
    movzx EDX, byte [gf_log + EAX]                                              ; move log value to EDX
    add EDX, EBX                                                                ; add EBX to EDX
    
    ; Reduce modulo 255
.reduce_loop:
    cmp EDX, 255                                                                ; compare EDX with 255
    jl .no_reduce                                                               ; if less, jump to .no_reduce
    sub EDX, 255                                                                ; subtract 255 from EDX
    jmp .reduce_loop
.no_reduce:
    
    ; Get exp of result
    movzx EAX, byte [gf_exp + EDX]                                              ; move exp value to EAX
    
    ; XOR with corresponding position in msg_poly
    push EDI
    mov EDI, ESI                                                                ; move ESI to EDI
    add EDI, ECX                                                                ; add ECX to EDI
    xor byte [msg_poly + EDI], AL                                               ; XOR the byte with AL
    pop EDI
    
.skip_term:
    inc ECX
    jmp .mult_gen
    
.mult_done:
    pop ESI
    
.rs_next:
    inc ESI
    jmp .rs_loop
    
.rs_done:
    ; Copy EC bytes from msg_poly to ec_data
    pop EDI
    pop ESI
    
    push ESI
    push EDI
    mov ECX, EC_CODEWORDS                                                       ; make the counter 16
    mov ESI, msg_poly                                                           ; ESI now points to msg_poly
    add ESI, DATA_CODEWORDS                                                     ; add 28 to ESI
    rep movsb                                                                   ; repeats movsb
    pop EDI
    pop ESI
    
    popa                                                                        ; pop all registers out of the stack
    ret
