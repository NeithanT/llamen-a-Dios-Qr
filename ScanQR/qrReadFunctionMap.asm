;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; QR Code Reader - Function Pattern Module
; Handles marking of QR function patterns (finders, timing, alignment, format)
; to exclude them from data extraction.
; =============================================================================

%include "qrReadConstants.inc"

section .text

; External symbols
extern is_function

; Exported functions
global init_function_map
global mark_finder
global mark_point

;--------------------------------------------------------------------------------------------------------------------------------------
; init_function_map - as its name says, ......
; This is to separete the finders, separators, timing, alignment,
; dark module, and format information areas.

init_function_map:

    pusha ; save registers
    
    ; Clear map
    mov ECX, QR_MATRIX_SIZE ; have the 625 bytes
    mov EDI, is_function ; 625 byte buffer
    xor AL, AL ; set it to 0
    rep stosb ; repeat, set all to 0
    
    ; Finder Patterns (3 corners)
    ; Top-Left indexes, 0, 0
    mov EAX, 0
    mov EBX, 0
    call mark_finder
    
    ; Top-Right
    mov EAX, 18 ; index x
    mov EBX, 0  ; index y
    call mark_finder
    
    ; Bottom-Left
    mov EAX, 0 ; index x
    mov EBX, 18; index y
    call mark_finder
    
    ; Separators the white 8x8 areas around finders
    ; Top-Left separator
    mov ECX, 0

.sep_tl:

    cmp ECX, 8
    jge .sep_tr
    mov EAX, ECX
    mov EBX, 7
    call mark_point
    mov EAX, 7
    mov EBX, ECX
    call mark_point
    inc ECX
    jmp .sep_tl
    
    ; Top-Right separator
.sep_tr:
    mov ECX, 0
.sep_tr_loop:
    cmp ECX, 8
    jge .sep_bl
    mov EAX, 17
    add EAX, ECX
    mov EBX, 7
    call mark_point
    mov EAX, 17
    mov EBX, ECX
    call mark_point
    inc ECX
    jmp .sep_tr_loop
    
    ; Bottom-Left separator
.sep_bl:
    mov ECX, 0
.sep_bl_loop:
    cmp ECX, 8
    jge .timing
    mov EAX, ECX
    mov EBX, 17
    call mark_point
    mov EAX, 7
    mov EBX, 18
    add EBX, ECX
    call mark_point
    inc ECX
    jmp .sep_bl_loop
    
    ; Timing Patterns
.timing:
    mov ECX, 8
.timing_loop:
    cmp ECX, 17
    jge .align
    mov EAX, ECX
    mov EBX, 6
    call mark_point
    mov EAX, 6
    mov EBX, ECX
    call mark_point
    inc ECX
    jmp .timing_loop
    
    ; Alignment Pattern at (18,18) - 5x5 area
.align:
    ; Center at 18,18. Range 16-20
    mov EAX, 16
.align_y:
    cmp EAX, 21
    jge .dark
    mov EBX, 16
.align_x:
    cmp EBX, 21
    jge .align_next_y
    push EAX
    push EBX
    xchg EAX, EBX       ; mark_point takes EAX=x, EBX=y
    call mark_point
    pop EBX
    pop EAX
    inc EBX
    jmp .align_x
.align_next_y:
    inc EAX
    jmp .align_y
    
    ; Dark module at (8, 17)
.dark:
    mov EAX, 8
    mov EBX, 17
    call mark_point
    
    ; Format Information Areas
    ; Horizontal: (0-8, 8) and (17-24, 8)
    ; Vertical: (8, 0-8) and (8, 17-24)
.format:
    mov ECX, 0
.fmt_loop:
    cmp ECX, 9
    jge .fmt_loop2
    mov EAX, ECX
    mov EBX, 8
    call mark_point
    mov EAX, 8
    mov EBX, ECX
    call mark_point
    inc ECX
    jmp .fmt_loop
    
.fmt_loop2:
    mov ECX, 17
.fmt_loop3:
    cmp ECX, 25
    jge .done_map
    mov EAX, ECX
    mov EBX, 8
    call mark_point
    mov EAX, 8
    mov EBX, ECX
    call mark_point
    inc ECX
    jmp .fmt_loop3
    
.done_map:
    popa
    ret

; mark_finder - Marks a 7x7 finder pattern starting from cordinates(x, y)
; Input: EAX = x coordinate (top-left)
;        EBX = y coordinate (top-left)

mark_finder:
    pusha ; save all registers
    mov ESI, EAX                ; Save x
    mov EDI, EBX                ; Save y
    mov ECX, 0                  ; y counter/ offset

; mark y  
.mf_y:

    cmp ECX, 7  ; it has to a 7 x 7 area, so count to 0
    jge .mf_done ; masking done
    mov EDX, 0   ; x offset
    
; mark x
.mf_x:

    cmp EDX, 7 ; count until 7 bits offset
    jge .mf_next_y ; go to next y bit
    mov EAX, ESI ; move, the cordinate
    add EAX, EDX ; add the offset
    mov EBX, EDI ; move the y cordinate
    add EBX, ECX ; add the y offset
    call mark_point ; mark the point
    inc EDX ; go to next x
    jmp .mf_x ; loop
    
.mf_next_y:
    inc ECX ; go to next y
    jmp .mf_y ; loop y
    
.mf_done: 
    popa ; restore registers when done
    ret ; return, not rlly a return of anything, just marking

; ----------------------------------------------------------------------------
; mark_point - Marks a single point in the function pattern map
; Input: EAX = x coordinate
;        EBX = y coordinate
; -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
mark_point:
    pusha ; save registers
    
    ; Bounds checking
    cmp EAX, QR_SIZE ; just in case, if it exits the x
    jge .mp_done ; done
    cmp EBX, QR_SIZE ; just in case, for the y
    jge .mp_done ; done
    
    ; Calculate offset: y * QR_SIZE + x
    imul EBX, QR_SIZE ; the actual byte number
    add EBX, EAX ; add the x offset
    mov byte [is_function + EBX], 1 ; set it to 1, valid pixel
    
.mp_done:
    popa ; restore register
    ret ; done
