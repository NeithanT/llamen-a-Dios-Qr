%include "io.mac"
%include "qrReadConstants.inc"
;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; QR Code Reader - For Model 2-M Correction (25x25)
; Reads a BMP file and gets the string !
; There are some modules in here:
; - qrReadIO: File I/O operations
; - qrReadFunctionMap: Function pattern identification
; - qrReadExtract: Data bit extraction
; - qrReadDecode: Stream decoding
; =============================================================================

; NOTE: These are all global! 
section .data
    ; File and buffer pointers
    input_filename  dd 0    ; the file name pointer ! char*
    output_buffer   dd 0    ; char pointer for the output, cool
    
    ; Decoding state
    bit_idx         dd 7    ; byte index, works for all files
    data_idx        dd 0    ; data index, works for all modules
    byte_val        dd 0    ; current byte scanned
    
    ; Error tracking
    error_code      dd 0                ; 0=success
                                        ; There are other states like 1=file_open, 2=file_read, 3=invalid_format
    
    ; Error messages
    msg_err_open    db "Error: Could not open file.", 10, 0
    msg_err_read    db "Error: Could not read file data.", 10, 0
    msg_err_format  db "Error: Invalid QR format or mode.", 10, 0

section .bss
    ; QR data structures (shared across modules)
    qr_matrix       resb QR_MATRIX_SIZE ; 625 bytes (25x25)
    is_function     resb QR_MATRIX_SIZE ; Function pattern map
    encoded_data    resb MAX_ENCODED_BYTES ; Max capacity for V2-M

section .text

; External functions from refactored modules
extern open_bmp
extern close_bmp
extern read_pixels
extern init_function_map
extern extract_data_bits
extern decode_stream

; Main entry point
global read_qr_asm
global qr_matrix
global is_function
global encoded_data
global input_filename
global output_buffer
global error_code
global bit_idx
global data_idx

; -----------------------------------------------------------------------------
; read_qr_asm - Main entry point for QR code reading
; Remember that C is a righter pusher, and the function definition for this is:
; extern void read_qr_asm(char* filename, char* buffer);
; the buffer is pushed first, then filename
; [EBP+8] = filename (pointer to string)
; [EBP+12] = output buffer (pointer to buffer for decoded text)
; The Output will be the decoded text, written to buffer
; -----------------------------------------------------------------------------

read_qr_asm:

    enter 0, 0  ; create the stack frame
    pusha       ; save registers
    
    ; Initialize error tracking
    mov dword [error_code], 0 ; currently is success
    
    ; Get parameters from stack
    ; Stack: [EBP] = Old EBP, [EBP+4] = Ret, [EBP+8] = filename, [EBP+12] = out_buffer
    mov EAX, [EBP+8]    ; filename
    mov [input_filename], EAX   ; save the filename for later
    mov EAX, [EBP+12]   ; save the buffer pointer
    mov [output_buffer], EAX    ; save the output pointer to later
    
    ; Step 1: Open BMP file !
    call open_bmp   ; syscall with open, blah blah
    cmp EAX, 0      ; the syscalls returns to EAX the FILE_DESCRIPTOR
    jl .error_open  ; if not, there is an error
    
    ; Step 2: Read pixel data into qr_matrix
    call read_pixels            ; read the actual data into a 2d matrix
    cmp dword [error_code], 0   ; check if there was an error while reading
    jne .error_read             ; if error happend, is different from zero
    
    ; Step 3: Close file
    call close_bmp  ; close the file, we got everything needed
    
    ; Step 4: Initialize function pattern map
    call init_function_map  ; demask the pattern
    
    ; Step 5: Extract data bits from QR matrix
    call extract_data_bits  ; read the data bits, ignoring everything else
    
    ; Step 6: Decode the data stream
    call decode_stream  ; this basically verifies it its in binary mode 
    cmp dword [error_code], 0   ; if is not, error code in this case
    jne .error_format   ; go to error
    
    ; Success - decoded text is now in output_buffer
    jmp .exit_func

.error_open:
    ; Write error message to output buffer
    mov EDI, [output_buffer]    ; move the output pointer
    mov ESI, msg_err_open   ; move the error message
    call copy_string    ; copy the error message to the pointer
    jmp .exit_func  ; return 

.error_read:
    call close_bmp ; close the file
    mov EDI, [output_buffer] ; move the output buffer
    mov ESI, msg_err_read ; move the errors
    call copy_string ; copy the error into the output
    jmp .exit_func ; return 

.error_format:
    mov EDI, [output_buffer] ;  move the output
    mov ESI, msg_err_format ; move the err of format
    call copy_string ; copy
    ; no need to jmp
.exit_func:
    popa ; restore
    pop EBP ; restore enter
    ret ; ret

; copy_string - Helper to copy error strings to output buffer
; Input: ESI = source, EDI = destination

copy_string:
    push EAX ; save used registers
    push ESI ; save original source
    push EDI ; save original destination
    
.copy_loop:
    lodsb ; load the byte of ESI from into AL
    test AL, AL ; check if the string is done
    jz .copy_done ; it '\0' done
    stosb ; else store in EDI
    jmp .copy_loop
    
.copy_done:
    mov byte [EDI], 0       ; Null terminator
    pop EDI ; restore original EDI
    pop ESI ; 0riginal ESI
    pop EAX ; restore EAX
    ret ; go back to the prev func
