;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; writeQr.asm - QR Code Data Placement and BMP Writing Module
; =============================================================================
; This module handles:
; - Placing data bits into the QR matrix
; - Writing the QR matrix as a BMP image
; =============================================================================

%include "io.mac"

; External pointers from mask.asm
extern qr_matrix_ptr
extern is_function_ptr

section .data
    ; QR Parameters
    SCALE           equ 1               ; Each module = 1 pixel
    QR_SIZE         equ 25              ; Version 2 = 25x25
    QUIET_ZONE      equ 4               ; 4 modules quiet zone
    ROW_SIZE        equ 100             ; 99 + 1 padding
    
    ; Data placement state
    data_idx        dd 0
    bit_idx         dd 0
    
    ; Codeword counts
    DATA_CODEWORDS  equ 28
    EC_CODEWORDS    equ 16
    TOTAL_CODEWORDS equ 44
    
    ; Local pointers for data buffers
    encoded_data_ptr    dd 0
    ec_data_ptr         dd 0

section .bss
    row_buffer      resb 1024

section .text

; =============================================================================
; place_data_modules
; Input:
;   ESI = pointer to qr_matrix (625 bytes)
;   EDI = pointer to is_function (625 bytes)
;   [ESP+4] = pointer to encoded_data (28 bytes)
;   [ESP+8] = pointer to ec_data (16 bytes)
; =============================================================================
global place_data_modules
place_data_modules:
    pusha
    
    mov [qr_matrix_ptr], ESI
    mov [is_function_ptr], EDI
    mov EAX, [ESP + 36]                                                         ; EAX now has encoded_data pointer
    mov [encoded_data_ptr], EAX
    mov EAX, [ESP + 40]                                                         ; EAX now has ec_data pointer
    mov [ec_data_ptr], EAX
    
    mov dword [data_idx], 0
    mov dword [bit_idx], 7
    
    mov EAX, 24                                                                 ; EAX is now 24
    xor ECX, ECX                                                                ; ECX is now 0
    
.col_pair:
    cmp EAX, 0                                                                  ; compare with 0
    jl .place_done                                                              ; if less, jump to .place_done
    
    cmp EAX, 6                                                                  ; compare EAX with 6
    jne .process_pair                                                           ; if not equal, jump to .process_pair
    dec EAX                                                                     ; skip timing column
    cmp EAX, 0
    jl .place_done
    
.process_pair:
    test ECX, 1                                                                 ; test direction bit
    jnz .go_down                                                                ; if odd, jump to .go_down
    
    mov EBX, 24                                                                 ; EBX is now 24
.up_loop:
    cmp EBX, 0                                                                  ; compare with 0
    jl .next_pair                                                               ; if less, jump to .next_pair
    
    push EAX
    push EBX
    push ECX
    call try_place_data_bit                                                     ; calls try_place_data_bit
    pop ECX
    pop EBX
    pop EAX
    
    push EAX
    push EBX
    push ECX
    dec EAX                                                                     ; decrement EAX
    cmp EAX, 0
    jl .up_skip_left
    cmp EAX, 6                                                                  ; compare EAX with 6
    je .up_skip_left                                                            ; if equal, jump to .up_skip_left
    call try_place_data_bit
.up_skip_left:
    pop ECX
    pop EBX
    pop EAX
    
    dec EBX
    jmp .up_loop
    
.go_down:
    xor EBX, EBX                                                                ; EBX is now 0
.down_loop:
    cmp EBX, QR_SIZE                                                            ; compare with 25
    jge .next_pair                                                              ; if greater or equal, jump to .next_pair
    
    push EAX
    push EBX
    push ECX
    call try_place_data_bit
    pop ECX
    pop EBX
    pop EAX
    
    push EAX
    push EBX
    push ECX
    dec EAX
    cmp EAX, 0
    jl .down_skip_left
    cmp EAX, 6
    je .down_skip_left
    call try_place_data_bit
.down_skip_left:
    pop ECX
    pop EBX
    pop EAX
    
    inc EBX
    jmp .down_loop
    
.next_pair:
    inc ECX
    sub EAX, 2                                                                  ; subtract 2 from EAX
    jmp .col_pair
    
.place_done:
    popa
    ret

; =============================================================================
; try_place_data_bit
; Input: EAX = x, EBX = y
; =============================================================================
try_place_data_bit:
    push ECX
    push EDX
    push ESI
    push EDI
    
    cmp EAX, 0                                                                  ; check x bounds
    jl .tpd_done
    cmp EAX, QR_SIZE
    jge .tpd_done
    cmp EBX, 0                                                                  ; check y bounds
    jl .tpd_done
    cmp EBX, QR_SIZE
    jge .tpd_done
    
    mov EDI, EBX                                                                ; EDI now has y
    imul EDI, QR_SIZE                                                           ; EDI = y * 25
    add EDI, EAX                                                                ; EDI = y * 25 + x (offset)
    
    push ESI
    mov ESI, [is_function_ptr]                                                  ; ESI now points to is_function
    add ESI, EDI
    cmp byte [ESI], 0                                                           ; compare with 0
    pop ESI
    jne .tpd_done                                                               ; if function module, jump to .tpd_done
    
    mov ESI, [data_idx]                                                         ; ESI now has data index
    cmp ESI, TOTAL_CODEWORDS                                                    ; compare with 44
    jge .tpd_done                                                               ; if all data placed, jump to .tpd_done
    
    cmp ESI, DATA_CODEWORDS                                                     ; compare with 28
    jge .get_ec_byte                                                            ; if EC bytes, jump to .get_ec_byte
    
    push ESI
    push EDI
    mov EDI, [encoded_data_ptr]                                                 ; EDI now points to encoded_data
    add EDI, ESI
    movzx EDX, byte [EDI]                                                       ; EDX now has the byte value
    pop EDI
    pop ESI
    jmp .got_byte
    
.get_ec_byte:
    push ESI
    sub ESI, DATA_CODEWORDS                                                     ; ESI now has EC byte index
    push EDI
    mov EDI, [ec_data_ptr]                                                      ; EDI now points to ec_data
    add EDI, ESI
    movzx EDX, byte [EDI]                                                       ; EDX now has the byte value
    pop EDI
    pop ESI
    
.got_byte:
    mov ECX, [bit_idx]                                                          ; ECX now has bit index
    shr EDX, CL                                                                 ; shift right by bit index
    and EDX, 1                                                                  ; mask to get single bit
    
    push ESI
    mov ESI, [qr_matrix_ptr]                                                    ; ESI now points to qr_matrix
    add ESI, EDI
    mov byte [ESI], DL                                                          ; place bit in matrix
    pop ESI
    
    dec dword [bit_idx]
    cmp dword [bit_idx], 0                                                      ; compare with 0
    jge .tpd_done                                                               ; if >= 0, jump to .tpd_done
    
    mov dword [bit_idx], 7                                                      ; reset bit index
    inc dword [data_idx]                                                        ; move to next byte
    
.tpd_done:
    pop EDI
    pop ESI
    pop EDX
    pop ECX
    ret

; =============================================================================
; write_qr_to_bmp
; Input: EBX = file descriptor, ESI = pointer to qr_matrix
; =============================================================================
global write_qr_to_bmp
write_qr_to_bmp:
    push EBP
    mov EBP, ESP
    sub ESP, 8                                                                  ; allocate 8 bytes for locals
    pusha
    
    mov [EBP - 8], EBX                                                          ; save file descriptor
    mov [qr_matrix_ptr], ESI
    
    mov ECX, QUIET_ZONE                                                         ; ECX now has quiet zone size
    imul ECX, SCALE
    
.write_bottom_qz:
    push ECX
    mov EBX, [EBP - 8]                                                          ; restore file descriptor
    call write_white_row                                                        ; calls write_white_row
    pop ECX
    loop .write_bottom_qz
    
    mov dword [EBP - 4], QR_SIZE - 1                                            ; row counter starts at 24
    
.write_qr_rows:
    mov ESI, [EBP - 4]                                                          ; ESI now has current row
    cmp ESI, 0
    jl .write_top_qz                                                            ; if less than 0, jump to .write_top_qz
    
    mov EDX, SCALE
    
.repeat_qr_row:
    push EDX
    
    lea EDI, [row_buffer]                                                       ; EDI now points to row_buffer
    
    mov ECX, QUIET_ZONE
    imul ECX, SCALE
    call append_white_pixels                                                    ; calls append_white_pixels
    
    mov ECX, 0                                                                  ; column counter
    
.build_qr_cols:
    cmp ECX, QR_SIZE                                                            ; compare with 25
    jge .qr_cols_done                                                           ; if >= 25, jump to .qr_cols_done
    
    push ECX
    mov EAX, ECX                                                                ; EAX now has column
    mov EBX, ESI                                                                ; EBX now has row
    
    push EDI
    mov EDI, EBX
    imul EDI, QR_SIZE                                                           ; EDI = row * 25
    add EDI, EAX                                                                ; EDI = offset
    push ESI
    mov ESI, [qr_matrix_ptr]                                                    ; ESI now points to qr_matrix
    add ESI, EDI
    movzx EAX, byte [ESI]                                                       ; EAX now has module value
    pop ESI
    pop EDI
    pop ECX
    
    push ECX
    mov ECX, SCALE
    call append_pixels_color                                                    ; calls append_pixels_color
    pop ECX
    
    inc ECX
    jmp .build_qr_cols
    
.qr_cols_done:
    mov ECX, QUIET_ZONE
    imul ECX, SCALE
    call append_white_pixels
    
    mov byte [EDI], 0                                                           ; add padding byte
    
    mov EAX, 4                                                                  ; sys_write
    mov EBX, [EBP - 8]
    lea ECX, [row_buffer]
    mov EDX, ROW_SIZE
    int 0x80                                                                    ; write row to file
    
    pop EDX
    dec EDX
    test EDX, EDX                                                               ; test if zero
    jnz .repeat_qr_row                                                          ; if not zero, repeat
    
    dec dword [EBP - 4]
    jmp .write_qr_rows
    
.write_top_qz:
    mov ECX, QUIET_ZONE
    imul ECX, SCALE
    
.write_top_qz_loop:
    push ECX
    mov EBX, [EBP - 8]
    call write_white_row
    pop ECX
    loop .write_top_qz_loop
    
    popa
    mov ESP, EBP
    pop EBP
    ret

; =============================================================================
; write_white_row
; Input: EBX = file descriptor
; =============================================================================
write_white_row:
    push EAX
    push ECX
    push EDX
    push EDI
    
    lea EDI, [row_buffer]                                                       ; EDI now points to row_buffer
    
    mov ECX, 99                                                                 ; 99 bytes to fill
    mov AL, 0xFF                                                                ; white color
    rep stosb                                                                   ; fill buffer with white
    
    mov byte [EDI], 0                                                           ; add padding byte
    
    mov EAX, 4                                                                  ; sys_write
    lea ECX, [row_buffer]
    mov EDX, ROW_SIZE
    int 0x80                                                                    ; write row to file
    
    pop EDI
    pop EDX
    pop ECX
    pop EAX
    ret

; =============================================================================
; append_white_pixels
; Input: ECX = number of pixels, EDI = buffer pointer
; =============================================================================
append_white_pixels:
    push EAX
.awp_loop:
    test ECX, ECX                                                               ; test if zero
    jz .awp_done                                                                ; if zero, jump to .awp_done
    mov byte [EDI], 0xFF
    mov byte [EDI + 1], 0xFF
    mov byte [EDI + 2], 0xFF
    add EDI, 3
    dec ECX
    jmp .awp_loop
.awp_done:
    pop EAX
    ret

; =============================================================================
; append_pixels_color
; Input: EAX = color (0=black, non-0=white), ECX = count, EDI = buffer pointer
; =============================================================================
append_pixels_color:
    push EAX
    test EAX, EAX                                                               ; test if zero
    jz .apc_white                                                               ; if zero, jump to .apc_white (white)
    
.apc_black_loop:
    test ECX, ECX
    jz .apc_done
    mov byte [EDI], 0x00
    mov byte [EDI + 1], 0x00
    mov byte [EDI + 2], 0x00
    add EDI, 3
    dec ECX
    jmp .apc_black_loop
    
.apc_white:
.apc_white_loop:
    test ECX, ECX
    jz .apc_done
    mov byte [EDI], 0xFF
    mov byte [EDI + 1], 0xFF
    mov byte [EDI + 2], 0xFF
    add EDI, 3
    dec ECX
    jmp .apc_white_loop
    
.apc_done:
    pop EAX
    ret
