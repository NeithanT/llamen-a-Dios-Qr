;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

;------------------------------------------------------------------------------
; QR Code Reader - Decoder Module
; Handles decoding of the data stream: parses mode indicator, character count,
; and extracts actual data bytes from the bit stream of encoded
;------------------------------------------------------------------------------

%include "qrReadConstants.inc"

section .text

; External symbols
extern encoded_data
extern bit_idx
extern error_code
extern output_buffer

; Exported functions
global decode_stream

; decode_stream - Decodes the encoded data stream
; WE have to read
;   1. Mode indicator (4 bits) - expects Byte Mode (0100)
;   2. The Character count, which is 8 bits for V2
;   3. Data bytes (8 bits each) ! the rest of the info

; Handles byte boundary(that it does not go over char count) and validates printable ASCII.
; Sets error_code to ERROR_INVALID_FMT on format errors, this is a constant on qrRead.asm
; this is just to verify if the mode indicator is in bynary and if so , send the stream back

decode_stream:
    pusha ; save the registers
    
    mov ESI, encoded_data ; get the binary stream
    mov EDI, [output_buffer] ; the output_buffer, it was a char pointer
    
    ; 1. Check Mode Indicator (4 bits)!
    ; the First byte, top 4 bits
    mov AL, [ESI] ; moves a byte, kkkk <- 4 bytes of the indicador + 0000 some other things
    shr AL, 4 ; shift right to only have the kkkk bits
    cmp AL, BYTE_MODE       ; Expect Byte mode (0100b)
    jne .invalid_format ; if not, something is wrong, go back
    
    ; 2. Read Character Count (8 bits for V2)
    ; Lower 4 bits of byte 0 + upper 4 bits of byte 1
    mov AL, [ESI] ; moves the first byte
    and AL, 0x0F ; only have the first 4 left
    shl AL, 4 ; move them to reserve space
    
    mov BL, [ESI+1] ; move the other byte
    shr BL, 4 ; only get the left most 4 bytes
    or AL, BL ; paste them together
    
    movzx ECX, AL ; Character count, we have a counter now!
    
    ; Sanity check on length
    cmp ECX, 0 ; check if string is empty
    jz .done_decode ; jump to done
    cmp ECX, 32             ; This could be 28 so it does not go overflow
    ja .invalid_format ; jg but for signed :D
    
    ; we only have capacity for 26 bytes at the end, 44 total, 18 correction
    cmp ECX, MAX_CHAR_COUNT ; see if for some reason it goes over
    jle .count_ok           ; the number is OK
    mov ECX, MAX_CHAR_COUNT ; Reduce to 26 characters
    
.count_ok:
    ; 3. Read Data
    ; We are at bit offset of 12 (4 mode + 8 count)
    ; This means that in byte 1, bits index 0 to 3 are the start of data
    
    mov EDX, 1              ; Current byte index
    mov dword [bit_idx], 3  ; Current bit index (start from bit 3 of byte 1
    ; note that this is only for byte 1, after that, the bytes have 7!
    
.char_loop:

    test ECX, ECX ; it the count is done, could also be cmp 0
    jz .done_decode ; we done with the count
    
    push ECX ; save the count
    
    ; Read 8 bits for character
    xor EBX, EBX            ; Accumulator for character
    mov ECX, 8              ; Bits to read
    
.bit_loop:

    test ECX, ECX ; see if is the \0 char
    jz .char_done ; then we are done
    
    ; Boundary check
    cmp EDX, MAX_ENCODED_BYTES ; in case of going over 26
    jge .invalid_format_pop ; not a valid format then
    
    ; Read bit from encoded_data[EDX] at position bit_idx
    mov AL, [ESI + EDX] ; get a byte
    push ECX ; save ECX, which is the bit counter
    mov ECX, [bit_idx] ; move the current bits we have to get
    shr AL, CL ; remove the first n(n in ECX) bits
    pop ECX ; restore ECX
    and AL, 1 ; leave only the first one
    
    ; Shift accumulator and add bit
    shl EBX, 1 ; make space for the next bit
    or BL, AL ; paste it together
    
    ; Move to next bit
    dec dword [bit_idx] ; decrease the bit index, to go to the next one
    js .wrap_byte       ; Jump if sign flag, to see if bit_inx went negative, when the byte is done
    
.continue_bit:

    dec ECX ; then we can continue to the next
    jmp .bit_loop ; loop for the next

.wrap_byte:
    ; Wrap to next byte
    mov dword [bit_idx], 7 ; going back to finish the byte
    inc EDX ; go to the next encoded data byte
    jmp .continue_bit ; continue to the next byte
    
.char_done:
    ; Validate printable ASCII (32-126)
    ; This is here bc early broken test
    cmp BL, 32 ; see if it's not tabs or weird things
    jl .skip_char ; if is less skip that char
    cmp BL, 126 ; if it is more, skip that char
    jg .skip_char ; the skipping phase
    
    ; Store character in output buffer
    mov [EDI], BL ; move the Byte, is good to go
    inc EDI ; next byte in output buffer
    
.skip_char:

    pop ECX ; restore char count
    dec ECX ; go to the next char
    jmp .char_loop ; repeat reading
    
.done_decode:

    mov byte [EDI], 0       ; Null terminate the string
    popa ; restore register
    ret ; restore good !

.invalid_format_pop:
    pop ECX                 ; Clean up stack

.invalid_format:
    mov dword [error_code], ERROR_INVALID_FMT ; move the error code
    mov EDI, [output_buffer] ; move the output
    mov byte [EDI], 0 ; null terminate it for no errors
    popa ; restore registers
    ret ; return to the original function
