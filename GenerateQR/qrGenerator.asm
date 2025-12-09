;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; qrGenerator.asm - Main QR Code Generator
; =============================================================================
; This is the main coordinator that uses the following modules:
; - encode.asm: Data encoding
; - errorBytes.asm: Reed-Solomon error correction
; - mask.asm: QR structure and masking
; - writeBmp.asm: BMP file header
; - writeQr.asm: QR data placement and BMP writing
; =============================================================================

%include "io.mac"

; External functions from modules
extern encode_data_stream
extern compute_reed_solomon
extern init_qr_matrix
extern apply_mask_and_format
extern open_bmp_file
extern write_bmp_headers
extern close_bmp_file
extern place_data_modules
extern write_qr_to_bmp

section .data
    File            db "output.bmp", 0
    
    ; Default data (fallback)
    default_data    db "hello", 0
    DEFAULT_LEN     equ 5
    
    ; QR Parameters
    DATA_CODEWORDS  equ 28              ; Version 2-M data capacity
    EC_CODEWORDS    equ 16              ; Version 2-M EC codewords
    
    ; Messages
    msg_encoding    db "Encoding input data...", 10, 0
    msg_ec          db "Generating Reed-Solomon EC...", 10, 0
    msg_matrix      db "Building QR matrix...", 10, 0
    msg_writing     db "Writing BMP file...", 10, 0
    msg_done        db "QR Code saved to output.bmp!", 10, 0

section .bss
    File_descriptor resd 1
    
    ; Input variables
    input_ptr       resd 1
    input_len       resd 1
    
    ; Data buffers
    encoded_data    resb 28
    ec_data         resb 16
    
    ; QR Matrix - 25x25 = 625 modules
    qr_matrix       resb 625
    is_function     resb 625

section .text

; =============================================================================
; generate_qr_asm
; Input: [EBP+8] = char* input (or NULL for default)
; =============================================================================
global generate_qr_asm
generate_qr_asm:
    push EBP
    mov EBP, ESP
    pusha
    
    mov EAX, [EBP+8]                                                            ; EAX now has the input pointer
    cmp EAX, 0                                                                  ; compare with NULL
    je .use_default                                                             ; if zero, jump to .use_default
    
    mov [input_ptr], EAX
    
    ; Calculate string length using repne scasb
    mov EDI, EAX                                                                ; EDI now points to input string
    xor ECX, ECX
    not ECX                                                                     ; ECX is now the max counter value
    xor AL, AL
    cld
    repne scasb                                                                 ; scan for null terminator
    not ECX
    dec ECX                                                                     ; ECX now has the string length
    mov [input_len], ECX
    jmp .start_encoding

.use_default:
    mov dword [input_ptr], default_data
    mov dword [input_len], DEFAULT_LEN

.start_encoding:
    PutStr msg_encoding
    
    mov ESI, [input_ptr]                                                        ; ESI now points to input data
    mov EDI, [input_len]                                                        ; EDI now has the input length
    push encoded_data
    call encode_data_stream                                                     ; calls encode_data_stream
    add ESP, 4

    PutStr msg_ec
    
    mov ESI, encoded_data                                                       ; ESI now points to encoded_data
    mov EDI, ec_data                                                            ; EDI now points to ec_data
    call compute_reed_solomon                                                   ; calls compute_reed_solomon
    
    PutStr msg_matrix
    
    mov ESI, qr_matrix                                                          ; ESI now points to qr_matrix
    mov EDI, is_function                                                        ; EDI now points to is_function
    call init_qr_matrix                                                         ; calls init_qr_matrix
    
    mov ESI, qr_matrix
    mov EDI, is_function
    push ec_data
    push encoded_data
    call place_data_modules                                                     ; calls place_data_modules
    add ESP, 8
    
    mov ESI, qr_matrix
    mov EDI, is_function
    call apply_mask_and_format                                                  ; calls apply_mask_and_format
    
    PutStr msg_writing
    
    mov ESI, File                                                               ; ESI now points to filename
    call open_bmp_file                                                          ; calls open_bmp_file
    mov [File_descriptor], EAX                                                  ; store file descriptor
    
    mov EBX, [File_descriptor]                                                  ; EBX now has file descriptor
    call write_bmp_headers                                                      ; calls write_bmp_headers
    
    mov EBX, [File_descriptor]
    mov ESI, qr_matrix
    call write_qr_to_bmp                                                        ; calls write_qr_to_bmp
    
    mov EBX, [File_descriptor]
    call close_bmp_file                                                         ; calls close_bmp_file
    
    PutStr msg_done
    
    popa
    pop EBP
    ret
