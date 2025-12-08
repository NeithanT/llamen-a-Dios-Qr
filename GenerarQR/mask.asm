;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; mask.asm - QR Code Structure and Masking Module
; =============================================================================
; This module handles:
; - QR matrix initialization
; - Drawing finder patterns, timing patterns, alignment patterns
; - Format information placement
; - Mask pattern application
; =============================================================================

%include "io.mac"

section .data
    ; QR Parameters
    QR_SIZE         equ 25              ; Version 2 = 25x25
    
    ; Format string buffer (populated by compute_format_info)
    format_bits     times 15 db 0
    
    ; Global pointers for matrix buffers (shared with writeQr.asm)
    global qr_matrix_ptr
    global is_function_ptr
    qr_matrix_ptr       dd 0
    is_function_ptr     dd 0

section .text

; =============================================================================
; init_qr_matrix
; Input:
;   ESI = pointer to qr_matrix buffer (625 bytes)
;   EDI = pointer to is_function buffer (625 bytes)
; Output:
;   qr_matrix and is_function initialized with function patterns
; =============================================================================
global init_qr_matrix
init_qr_matrix:
    pusha
    
    mov [qr_matrix_ptr], ESI                                                     ; save ESI to qr_matrix_ptr
    mov [is_function_ptr], EDI                                                   ; save EDI to is_function_ptr
    
    push ESI                                                                     ; save ESI
    mov ECX, 625                                                                 ; ECX is now 625
    xor EAX, EAX                                                                 ; EAX is now 0
    mov EDI, ESI                                                                 ; EDI now points to qr_matrix
    rep stosb                                                                    ; fill 625 bytes with 0
    pop ESI                                                                      ; restore ESI
    
    mov EDI, [is_function_ptr]                                                   ; EDI now points to is_function
    mov ECX, 625                                                                 ; ECX is now 625
    xor EAX, EAX                                                                 ; EAX is now 0
    rep stosb                                                                    ; fill 625 bytes with 0
    
    mov EAX, 0                                                                   ; EAX is now 0
    mov EBX, 0                                                                   ; EBX is now 0
    call draw_finder_pattern                                                     ; calls draw_finder_pattern
    
    mov EAX, 18                                                                  ; EAX is now 18
    mov EBX, 0                                                                   ; EBX is now 0
    call draw_finder_pattern                                                     ; calls draw_finder_pattern
    
    mov EAX, 0                                                                   ; EAX is now 0
    mov EBX, 18                                                                  ; EBX is now 18
    call draw_finder_pattern                                                     ; calls draw_finder_pattern
    
    call draw_separators                                                         ; calls draw_separators
    call draw_timing_patterns                                                    ; calls draw_timing_patterns
    
    mov EAX, 18                                                                  ; EAX is now 18
    mov EBX, 18                                                                  ; EBX is now 18
    call draw_alignment_pattern                                                  ; calls draw_alignment_pattern
    
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, 17                                                                  ; EBX is now 17
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    call reserve_format_areas                                                    ; calls reserve_format_areas
    
    popa
    ret

; =============================================================================
; draw_finder_pattern
; Input: EAX = top-left x, EBX = top-left y
; Uses ESI (qr_matrix), EDI (is_function) from stack
; =============================================================================
draw_finder_pattern:
    pusha
    
    push EAX                                                                     ; save EAX
    push EBX                                                                     ; save EBX
    mov ESI, EAX                                                                 ; ESI is now x
    mov EDX, EBX                                                                 ; EDX is now y
    
    mov ECX, 0                                                                   ; ECX is now 0
.fp_row0:
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .fp_row1_start                                                           ; if greater or equal, jump to .fp_row1_start
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, ECX                                                                 ; add ECX to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .fp_row0_next                                                            ; if greater or equal, jump to .fp_row0_next
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    push EDI                                                                     ; save EDI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop EDI                                                                      ; restore EDI
    pop ESI                                                                      ; restore ESI
.fp_row0_next:
    inc ECX                                                                      ; increment ECX
    jmp .fp_row0                                                                 ; jump to .fp_row0

.fp_row1_start:
    mov EAX, ESI                                                                 ; EAX is now ESI
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    cmp EBX, QR_SIZE                                                             ; compare EBX with 25
    jge .fp_row2_start                                                           ; if greater or equal, jump to .fp_row2_start
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 1                                                                   ; add 1 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 2                                                                   ; add 2 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 3                                                                   ; add 3 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 4                                                                   ; add 4 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 5                                                                   ; add 5 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 6                                                                   ; add 6 to EAXDX                                                                 ; EBX is now EDX
    add EBX, 1                                                                   ; add 1 to EBX
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .fp_row2_start                                                           ; if greater or equal, jump to .fp_row2_start
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI

.fp_row2_start:
    mov ECX, 2                                                                   ; ECX is now 2
.fp_mid_rows:
    cmp ECX, 5                                                                   ; compare ECX with 5
    jge .fp_row5_start                                                           ; if greater or equal, jump to .fp_row5_start
    
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    cmp EBX, QR_SIZE                                                             ; compare EBX with 25
    jge .fp_mid_next                                                             ; if greater or equal, jump to .fp_mid_next
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 1                                                                   ; add 1 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 2                                                                   ; add 2 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 3                                                                   ; add 3 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 4                                                                   ; add 4 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 5                                                                   ; add 5 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 6                                                                   ; add 6 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, ECX                                                                 ; add ECX to EBX
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .fp_mid_next                                                             ; if greater or equal, jump to .fp_mid_next
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
.fp_mid_next:
    inc ECX                                                                      ; increment ECX
    jmp .fp_mid_rows                                                             ; jump to .fp_mid_rows

.fp_row5_start:
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    cmp EBX, QR_SIZE                                                             ; compare EBX with 25
    jge .fp_row6_start                                                           ; if greater or equal, jump to .fp_row6_start
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 1                                                                   ; add 1 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 2                                                                   ; add 2 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 3                                                                   ; add 3 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 4                                                                   ; add 4 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 5                                                                   ; add 5 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, 6                                                                   ; add 6 to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 5                                                                   ; add 5 to EBX
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .fp_row6_start                                                           ; if greater or equal, jump to .fp_row6_start
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI

.fp_row6_start:
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 6                                                                   ; add 6 to EBX
    cmp EBX, QR_SIZE                                                             ; compare EBX with 25
    jge .fp_done                                                                 ; if greater or equal, jump to .fp_done
    
    mov ECX, 0                                                                   ; ECX is now 0
.fp_row6:
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .fp_done                                                                 ; if greater or equal, jump to .fp_done
    mov EAX, ESI                                                                 ; EAX is now ESI
    add EAX, ECX                                                                 ; add ECX to EAX
    mov EBX, EDX                                                                 ; EBX is now EDX
    add EBX, 6                                                                   ; add 6 to EBX
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .fp_row6_next                                                            ; if greater or equal, jump to .fp_row6_next
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop ESI                                                                      ; restore ESI
.fp_row6_next:
    inc ECX                                                                      ; increment ECX
    jmp .fp_row6                                                                 ; jump to .fp_row6
    
.fp_done:
    pop EBX
    pop EAX
    popa
    ret

; =============================================================================
; draw_alignment_pattern
; Input: EAX = center_x (18), EBX = center_y (18)
; =============================================================================
draw_alignment_pattern:
    pusha
    
    mov EBX, 16                                                                  ; EBX is now 16
    
.align_row_loop:
    cmp EBX, 21                                                                  ; compare EBX with 21
    jge .align_done                                                              ; if greater or equal, jump to .align_done
    
    mov EAX, 16                                                                  ; EAX is now 16
    
.align_col_loop:
    cmp EAX, 21                                                                  ; compare EAX with 21
    jge .align_next_row                                                          ; if greater or equal, jump to .align_next_row
    
    push EAX                                                                     ; save EAX
    push EBX                                                                     ; save EBX
    
    mov ECX, 1                                                                   ; ECX is now 1
    cmp EBX, 16                                                                  ; compare EBX with 16
    je .set_align_module                                                         ; if equal, jump to .set_align_module
    cmp EBX, 20                                                                  ; compare EBX with 20
    je .set_align_module                                                         ; if equal, jump to .set_align_module
    cmp EAX, 16                                                                  ; compare EAX with 16
    je .set_align_module                                                         ; if equal, jump to .set_align_module
    cmp EAX, 20                                                                  ; compare EAX with 20
    je .set_align_module                                                         ; if equal, jump to .set_align_module
    
    cmp EBX, 18                                                                  ; compare EBX with 18
    jne .white_module                                                            ; if not equal, jump to .white_module
    cmp EAX, 18                                                                  ; compare EAX with 18
    je .set_align_module                                                         ; if equal, jump to .set_align_module
    
.white_module:
    mov ECX, 0                                                                   ; ECX is now 0
    
.set_align_module:
    push ECX                                                                     ; save ECX
    call set_function_module                                                     ; calls set_function_module
    pop ECX                                                                      ; restore ECX
    
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    push EDI                                                                     ; save EDI
    mov EDI, EBX                                                                 ; EDI is now EBX
    imul EDI, QR_SIZE                                                            ; multiply EDI by 25
    add EDI, EAX                                                                 ; add EAX to EDI
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], CL                                                           ; set module to CL
    pop EDI                                                                      ; restore EDI
    pop ESI                                                                      ; restore ESI
    
    pop EBX                                                                      ; restore EBX
    pop EAX                                                                      ; restore EAX
    
    inc EAX                                                                      ; increment EAX
    jmp .align_col_loop                                                          ; jump to .align_col_loop
    
.align_next_row:
    inc EBX                                                                      ; increment EBX
    jmp .align_row_loop                                                          ; jump to .align_row_loop
    
.align_done:
    popa
    ret

; =============================================================================
; draw_separators
; Draws white separator lines around finder patterns
; =============================================================================
draw_separators:
    pusha
    
    mov ECX, 0                                                                   ; ECX is now 0
.sep_tl:
    cmp ECX, 8                                                                   ; compare ECX with 8
    jge .sep_tr                                                                  ; if greater or equal, jump to .sep_tr
    
    mov EAX, ECX                                                                 ; EAX is now ECX
    mov EBX, 7                                                                   ; EBX is now 7
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .sep_tl_next                                                             ; if greater or equal, jump to .sep_tl_next
    mov EAX, 7                                                                   ; EAX is now 7
    mov EBX, ECX                                                                 ; EBX is now ECX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
.sep_tl_next:
    inc ECX                                                                      ; increment ECX
    jmp .sep_tl                                                                  ; jump to .sep_tl
    
.sep_tr:
    mov ECX, 0                                                                   ; ECX is now 0
.sep_tr_loop:
    cmp ECX, 8                                                                   ; compare ECX with 8
    jge .sep_bl                                                                  ; if greater or equal, jump to .sep_bl
    
    mov EAX, 17                                                                  ; EAX is now 17
    add EAX, ECX                                                                 ; add ECX to EAX
    mov EBX, 7                                                                   ; EBX is now 7
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .sep_tr_vert                                                             ; if greater or equal, jump to .sep_tr_vert
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
.sep_tr_vert:
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .sep_tr_next                                                             ; if greater or equal, jump to .sep_tr_next
    mov EAX, 17                                                                  ; EAX is now 17
    mov EBX, ECX                                                                 ; EBX is now ECX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
.sep_tr_next:
    inc ECX                                                                      ; increment ECX
    jmp .sep_tr_loop                                                             ; jump to .sep_tr_loop
    
.sep_bl:
    mov ECX, 0                                                                   ; ECX is now 0
.sep_bl_loop:
    cmp ECX, 8                                                                   ; compare ECX with 8
    jge .sep_done                                                                ; if greater or equal, jump to .sep_done
    
    mov EAX, ECX                                                                 ; EAX is now ECX
    mov EBX, 17                                                                  ; EBX is now 17
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .sep_bl_next                                                             ; if greater or equal, jump to .sep_bl_next
    mov EAX, 7                                                                   ; EAX is now 7
    mov EBX, 18                                                                  ; EBX is now 18
    add EBX, ECX                                                                 ; add ECX to EBX
    cmp EBX, QR_SIZE                                                             ; compare EBX with 25
    jge .sep_bl_next                                                             ; if greater or equal, jump to .sep_bl_next
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 0                                                            ; set module to 0
    pop ESI                                                                      ; restore ESI
    
.sep_bl_next:
    inc ECX                                                                      ; increment ECX
    jmp .sep_bl_loop                                                             ; jump to .sep_bl_loop
    
.sep_done:
    popa
    ret

; =============================================================================
; draw_timing_patterns
; Draws alternating black/white timing patterns
; =============================================================================
draw_timing_patterns:
    pusha
    
    mov ECX, 8                                                                   ; ECX is now 8
    
.timing_loop:
    cmp ECX, 17                                                                  ; compare ECX with 17
    jge .timing_done                                                             ; if greater or equal, jump to .timing_done
    
    mov EAX, ECX                                                                 ; EAX is now ECX
    and EAX, 1                                                                   ; AND EAX with 1
    xor EAX, 1                                                                   ; XOR EAX with 1
    mov EDX, EAX                                                                 ; EDX is now EAX
    
    mov EAX, ECX                                                                 ; EAX is now ECX
    mov EBX, 6                                                                   ; EBX is now 6
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov [ESI], DL                                                                ; set module to DL
    pop ESI                                                                      ; restore ESI
    
    mov EAX, 6                                                                   ; EAX is now 6
    mov EBX, ECX                                                                 ; EBX is now ECX
    call set_function_module                                                     ; calls set_function_module
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    mov [ESI], DL                                                                ; set module to DL
    pop ESI                                                                      ; restore ESI
    
    inc ECX                                                                      ; increment ECX
    jmp .timing_loop                                                             ; jump to .timing_loop
    
.timing_done:
    popa
    ret

; =============================================================================
; reserve_format_areas
; Reserves areas for format information
; =============================================================================
reserve_format_areas:
    pusha
    
    mov ECX, 0                                                                   ; ECX is now 0
.fmt_tl:
    cmp ECX, 9                                                                   ; compare ECX with 9
    jge .fmt_right                                                               ; if greater or equal, jump to .fmt_right
    
    mov EAX, ECX                                                                 ; EAX is now ECX
    mov EBX, 8                                                                   ; EBX is now 8
    cmp EAX, 6                                                                   ; compare EAX with 6
    je .fmt_tl_col                                                               ; if equal, jump to .fmt_tl_col
    call set_function_module                                                     ; calls set_function_module
    
.fmt_tl_col:
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, ECX                                                                 ; EBX is now ECX
    cmp EBX, 6                                                                   ; compare EBX with 6
    je .fmt_tl_next                                                              ; if equal, jump to .fmt_tl_next
    call set_function_module                                                     ; calls set_function_module
    
.fmt_tl_next:
    inc ECX                                                                      ; increment ECX
    jmp .fmt_tl                                                                  ; jump to .fmt_tl
    
.fmt_right:
    mov ECX, 0                                                                   ; ECX is now 0
.fmt_r_loop:
    cmp ECX, 8                                                                   ; compare ECX with 8
    jge .fmt_bottom                                                              ; if greater or equal, jump to .fmt_bottom
    
    mov EAX, 24                                                                  ; EAX is now 24
    sub EAX, ECX                                                                 ; subtract ECX from EAX
    mov EBX, 8                                                                   ; EBX is now 8
    call set_function_module                                                     ; calls set_function_module
    
    inc ECX                                                                      ; increment ECX
    jmp .fmt_r_loop                                                              ; jump to .fmt_r_loop
    
.fmt_bottom:
    mov ECX, 0                                                                   ; ECX is now 0
.fmt_b_loop:
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .fmt_done                                                                ; if greater or equal, jump to .fmt_done
    
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, 24                                                                  ; EBX is now 24
    sub EBX, ECX                                                                 ; subtract ECX from EBX
    call set_function_module                                                     ; calls set_function_module
    
    inc ECX                                                                      ; increment ECX
    jmp .fmt_b_loop                                                              ; jump to .fmt_b_loop
    
.fmt_done:
    popa
    ret

; =============================================================================
; set_function_module
; Input: EAX = x, EBX = y
; Output: EDI = offset in qr_matrix/is_function
; Marks module as function pattern
; =============================================================================
set_function_module:
    push EAX                                                                     ; save EAX
    push EDX                                                                     ; save EDX
    push ESI                                                                     ; save ESI
    
    mov EDI, EBX                                                                 ; EDI is now EBX
    imul EDI, QR_SIZE                                                            ; multiply EDI by 25
    add EDI, EAX                                                                 ; add EAX to EDI
    
    push EDI                                                                     ; save EDI
    mov ESI, [is_function_ptr]                                                   ; ESI now points to is_function
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], 1                                                            ; set module to 1
    pop EDI                                                                      ; restore EDI
    
    pop ESI
    pop EDX
    pop EAX
    ret

; =============================================================================
; apply_mask_and_format
; Input:
;   ESI = pointer to qr_matrix
;   EDI = pointer to is_function
; Applies mask pattern 0 and writes format information
; =============================================================================
global apply_mask_and_format
apply_mask_and_format:
    pusha
    
    mov [qr_matrix_ptr], ESI                                                     ; save ESI to qr_matrix_ptr
    mov [is_function_ptr], EDI                                                   ; save EDI to is_function_ptr
    
    mov EBX, 0                                                                   ; EBX is now 0
.mask_row:
    cmp EBX, QR_SIZE                                                             ; compare EBX with 25
    jge .write_format                                                            ; if greater or equal, jump to .write_format
    
    mov EAX, 0                                                                   ; EAX is now 0
.mask_col:
    cmp EAX, QR_SIZE                                                             ; compare EAX with 25
    jge .mask_next_row                                                           ; if greater or equal, jump to .mask_next_row
    
    push EDI                                                                     ; save EDI
    mov EDI, EBX                                                                 ; EDI is now EBX
    imul EDI, QR_SIZE                                                            ; multiply EDI by 25
    add EDI, EAX                                                                 ; add EAX to EDI
    
    push ESI                                                                     ; save ESI
    mov ESI, [is_function_ptr]                                                   ; ESI now points to is_function
    add ESI, EDI                                                                 ; add offset to ESI
    cmp byte [ESI], 0                                                            ; compare byte with 0
    pop ESI                                                                      ; restore ESI
    jne .mask_skip                                                               ; if not equal, jump to .mask_skip
    
    mov ECX, EAX                                                                 ; ECX is now EAX
    add ECX, EBX                                                                 ; add EBX to ECX
    and ECX, 1                                                                   ; AND ECX with 1
    jnz .mask_skip                                                               ; if not zero, jump to .mask_skip
    
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    add ESI, EDI                                                                 ; add offset to ESI
    xor byte [ESI], 1                                                            ; XOR byte with 1
    pop ESI                                                                      ; restore ESI
    
.mask_skip:
    pop EDI                                                                      ; restore EDI
    inc EAX                                                                      ; increment EAX
    jmp .mask_col                                                                ; jump to .mask_col
    
.mask_next_row:
    inc EBX                                                                      ; increment EBX
    jmp .mask_row                                                                ; jump to .mask_row
    
.write_format:
    call compute_format_info                                                     ; calls compute_format_info                                                     ; calls compute_format_info
    ; Write format information bits (15 bits)
    ; Format bits for Level M, Mask 0: 101010000010010
    ; 
    ; According to QR Code specification ISO/IEC 18004:
    ;
    ; COPY 1 (around top-left finder):
    ;   Bits 0-5: column 8, rows 0-5 (vertical, top to bottom)
    ;   Bit 6: column 8, row 7 (skip row 6 = timing)
    ;   Bit 7: column 8, row 8
    ;   Bit 8: column 7, row 8 (horizontal, going left)
    ;   Bits 9-14: columns 5-0, row 8 (skip column 6 = timing)
    ;
    ; COPY 2 (bottom-left + top-right):
    ;   Bits 0-6: column 8, rows (QR_SIZE-1) to (QR_SIZE-7) (bottom-left)
    ;   Bits 7-14: columns (QR_SIZE-8) to (QR_SIZE-1), row 8 (top-right)

    mov ECX, 0                                                                   ; ECX is now 0
.format_copy1_part1:
    cmp ECX, 6                                                                   ; compare ECX with 6
    jge .format_copy1_bit6                                                       ; if greater or equal, jump to .format_copy1_bit6
    
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, ECX                                                                 ; EBX is now ECX
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    inc ECX                                                                      ; increment ECX
    jmp .format_copy1_part1                                                      ; jump to .format_copy1_part1
    
.format_copy1_bit6:
    mov ECX, 6                                                                   ; ECX is now 6
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, 7                                                                   ; EBX is now 7
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    mov ECX, 7                                                                   ; ECX is now 7
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, 8                                                                   ; EBX is now 8
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    mov ECX, 8                                                                   ; ECX is now 8
    mov EAX, 7                                                                   ; EAX is now 7
    mov EBX, 8                                                                   ; EBX is now 8
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    mov ECX, 9                                                                   ; ECX is now 9
.format_copy1_part2:
    cmp ECX, 15                                                                  ; compare ECX with 15
    jge .format_copy2_start                                                      ; if greater or equal, jump to .format_copy2_start
    
    mov EAX, 14                                                                  ; EAX is now 14
    sub EAX, ECX                                                                 ; subtract ECX from EAX
    mov EBX, 8                                                                   ; EBX is now 8
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    inc ECX                                                                      ; increment ECX
    jmp .format_copy1_part2                                                      ; jump to .format_copy1_part2
    
.format_copy2_start:
    mov ECX, 0                                                                   ; ECX is now 0
.format_copy2_bottom:
    cmp ECX, 7                                                                   ; compare ECX with 7
    jge .format_copy2_right                                                      ; if greater or equal, jump to .format_copy2_right
    
    mov EAX, 8                                                                   ; EAX is now 8
    mov EBX, QR_SIZE - 1                                                         ; EBX is now 24
    sub EBX, ECX                                                                 ; subtract ECX from EBX
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    inc ECX                                                                      ; increment ECX
    jmp .format_copy2_bottom                                                     ; jump to .format_copy2_bottom
    
.format_copy2_right:
    mov ECX, 7                                                                   ; ECX is now 7
.format_copy2_right_loop:
    cmp ECX, 15                                                                  ; compare ECX with 15
    jge .format_done                                                             ; if greater or equal, jump to .format_done
    
    mov EAX, QR_SIZE - 8                                                         ; EAX is now 17
    add EAX, ECX                                                                 ; add ECX to EAX
    sub EAX, 7                                                                   ; subtract 7 from EAX
    mov EBX, 8                                                                   ; EBX is now 8
    push ECX                                                                     ; save ECX
    call write_format_bit                                                        ; calls write_format_bit
    pop ECX                                                                      ; restore ECX
    
    inc ECX                                                                      ; increment ECX
    jmp .format_copy2_right_loop                                                 ; jump to .format_copy2_right_loop
    
.format_done:
    popa
    ret

; =============================================================================
; compute_format_info
; Calculates 15-bit format information for Level M, Mask 0
; and populates format_bits array
; =============================================================================
compute_format_info:
    pusha
    
    mov AX, 0                                                                    ; AX is now 0
    
    shl AX, 10                                                                   ; shift AX left by 10
    
    mov CX, 4                                                                    ; CX is now 4
.bch_loop:
    mov DX, AX                                                                   ; DX is now AX
    mov BX, CX                                                                   ; BX is now CX
    add BX, 10                                                                   ; add 10 to BX
    push CX                                                                      ; save CX
    mov CX, BX                                                                   ; CX is now BX
    shr DX, CL                                                                   ; shift DX right by CL
    pop CX                                                                       ; restore CX
    and DX, 1                                                                    ; AND DX with 1
    jz .bch_skip                                                                 ; if zero, jump to .bch_skip
    
    mov BX, 0x537                                                                ; BX is now 0x537
    push CX                                                                      ; save CX
    shl BX, CL                                                                   ; shift BX left by CL
    pop CX                                                                       ; restore CX
    xor AX, BX                                                                   ; XOR AX with BX
    
.bch_skip:
    dec CX                                                                       ; decrement CX
    cmp CX, 0                                                                    ; compare CX with 0
    jge .bch_loop                                                                ; if greater or equal, jump to .bch_loop
    
    and AX, 0x3FF                                                                ; AND AX with 0x3FF
    
    xor AX, 0x5412                                                               ; XOR AX with 0x5412
    
    mov CX, 0                                                                    ; CX is now 0
    mov EDI, 0                                                                   ; EDI is now 0
    
.unpack_loop:
    mov DX, AX                                                                   ; DX is now AX
    push CX                                                                      ; save CX
    shr DX, CL                                                                   ; shift DX right by CL
    pop CX                                                                       ; restore CX
    and DX, 1                                                                    ; AND DX with 1
    mov [format_bits + EDI], DL                                                  ; save DL to format_bits
    
    inc EDI                                                                      ; increment EDI
    inc CX                                                                       ; increment CX
    cmp CX, 15                                                                   ; compare CX with 15
    jl .unpack_loop                                                              ; if less, jump to .unpack_loop
    
    popa
    ret

; =============================================================================
; write_format_bit
; Input: EAX = x, EBX = y, ECX = bit index (0-14)
; =============================================================================
write_format_bit:
    pusha
    
    push ESI                                                                     ; save ESI
    lea ESI, [format_bits]                                                       ; ESI now points to format_bits
    add ESI, ECX                                                                 ; add ECX to ESI
    movzx EDX, byte [ESI]                                                        ; EDX is now the bit value
    pop ESI                                                                      ; restore ESI
    
    push ESI                                                                     ; save ESI
    mov ESI, [qr_matrix_ptr]                                                     ; ESI now points to qr_matrix
    push EDI                                                                     ; save EDI
    mov EDI, EBX                                                                 ; EDI is now EBX
    imul EDI, QR_SIZE                                                            ; multiply EDI by 25
    add EDI, EAX                                                                 ; add EAX to EDI
    add ESI, EDI                                                                 ; add offset to ESI
    mov byte [ESI], DL                                                           ; set module to DL
    pop EDI                                                                      ; restore EDI
    pop ESI                                                                      ; restore ESI
    
    popa
    ret
