;----------Instituto Tecnológico de Costa Rica--------------
;----------Campus Tecnológico Central Cartago---------------
;---------Escuela de Ingeniería en Computación--------------
;-------Curso IC-3101 Arquitectura de Computadoras----------
;--------------------Proyecto #02---------------------------
;---------Neithan Vargas Vargas, carne: 2025149384----------
;---------Fabricio Hernandez, carne: 2025106763-------------
;---2025/12/08 , II Periodo, Profesor: MS.c Esteban Arias---

; =============================================================================
; QR Code Reader - File I/O Module
; Handles BMP file operations: opening, closing, reading pixels, and processing
; scanlines into the QR matrix.
; =============================================================================

%include "qrReadConstants.inc"

section .data
    ; File descriptor (local to this module)
    fd              dd 0

section .bss
    ; Row buffer for reading scanlines
    row_buffer      resb 1024

section .text

; External symbols that this module needs
extern qr_matrix
extern error_code
extern input_filename

; Exported functions
global open_bmp
global close_bmp
global read_pixels
global process_scanline

; ----------------------------------------------------------------------------
; open_bmp - Opens a BMP in reading mode
; Input: [input_filename] - pointer to filename
; Output: EAX - file descriptor (negative on error)
; ----------------------------------------------------------------------------
open_bmp:

    push EBX ; save used registers for syscalls
    push ECX
    push EDX
    ; not saving EAX bc we return there

    mov EAX, 5                  ; sys_open
    mov EBX, [input_filename]   ; the global var in qrRead
    mov ECX, 0                  ; O_RDONLY
    mov EDX, 0                  ; mode
    int 0x80
    
    ; Check if file opened successfully (fd >= 0)
    cmp EAX, 0 ; the FD should not be 0, or 1 or 2, default ... files
    jl .open_failed ; failed
    
    mov [fd], EAX ; else success
    
    pop EDX ; restore the EDX
    pop ECX ; restore the ECX
    pop EBX ; restore the EBX
    ret ; returns the fd

.open_failed:

    mov dword [error_code], ERROR_FILE_OPEN ; move the error code/
    pop EDX ; restore the registers
    pop ECX ; restore EDX
    pop EBX ; this could be simplified with a return label
    ret ; return the value in EAX, not useful now

close_bmp:
    push EAX ; save the current EAX
    push EBX ; save BX as we also need it for the syscall
    
    cmp dword [fd], 0 ; The file descriptor is no longer valid
    jle .close_done ; its done
    
    mov EAX, 6      ; sys_close
    mov EBX, [fd]   ; the df if is valid
    int 0x80    ; syscall interruption whatever
    
    mov dword [fd], 0 ; move 0 to file descriptor

.close_done:
    pop EBX ; restore EBX
    pop EAX ; restore EAX
    ret ; return, we restore EAX as this does not return anything


; ----------------------------------------------------------------------------
; read_pixels - Reads pixel data from BMP file into qr_matrix in qrRead
; Skips BMP header bc who cares and quiet zones, reads QR rows bottom-up
; Sets error_code to ERROR_FILE_READ on failure
; ----------------------------------------------------------------------------
read_pixels:
    pusha
    
    ; Skip Header (54 bytes)
    mov EAX, 19                 ; sys_lseek
    mov EBX, [fd]               ; the file descriptor
    mov ECX, 54                 ; move 54 bytes!
    mov EDX, 0                  ; SEEK_SET
    int 0x80
    
    ; Check for lseek error
    cmp EAX, 0 
    jl .read_error ; if -1 error
    
    ; Skip Bottom Quiet Zone
    ; Size = QUIET_ZONE * SCALE * ROW_SIZE
    ; the quiet zone is the blanks pixels above just in case
    mov EAX, QUIET_ZONE ; size of quiet zone, 4 rows
    imul EAX, SCALE ; size of each pixel
    imul EAX, ROW_SIZE ; row size
    
    ; another system call for moving off the quiet zone
    mov ECX, EAX                ; Offset
    mov EAX, 19                 ; sys_lseek
    mov EBX, [fd]               ; the file
    mov EDX, 1                  ; SEEK_CUR
    int 0x80    ; syscall
    
    ; Check for lseek error
    cmp EAX, 0 ; if there was an error like EOF
    jl .read_error ; jump to error
    
    ; Read QR from  Row 24 down to 0
    mov ESI, QR_SIZE - 1        ; Current QR Row index
    ; work with index 0 to 24 .......................................... ye
    
.row_loop:

    cmp ESI, 0  ; check if its the row 0, then it is done
    jl .read_done ; go to done
    
    ; Read the sampling scanline
    mov EAX, 3                  ; sys_read
    mov EBX, [fd]               ; the file descriptor
    mov ECX, row_buffer         ; a buffer
    mov EDX, ROW_SIZE           ; 100 constant in .
    int 0x80 ; syscall for read
    
    ; Check if read was successful (should return ROW_SIZE bytes, so 100)
    cmp EAX, ROW_SIZE
    jl .read_error ; if less than that, return
    
    ; Process this row
    call process_scanline, ; get the bytes
    
    dec ESI
    jmp .row_loop
    
.read_done:
    popa
    ret

.read_error:
    mov dword [error_code], ERROR_FILE_READ
    popa
    ret

; ----------------------------------------------------------------------------
; process_scanline - Processes a single scanline into qr_matrix
; Input: ESI = QR Row index (0-24)
;        row_buffer contains the pixel data
; Samples the center of each module and stores black/white value
; ----------------------------------------------------------------------------
process_scanline:
    pusha
    
    ; Skip Left quiet zone
    ; Offset = QUIET_ZONE * SCALE * 3
    mov EDI, QUIET_ZONE ; size of one quiet zone
    imul EDI, SCALE ; size of 1
    imul EDI, 3 ; left bits
    
    mov ECX, 0                  ; Column index (0 to 24)
    
.col_loop:
    cmp ECX, QR_SIZE ; see if it's the last row
    jge .proc_done ; then it's done
    
    ; Calculate pixel offset for center of module
    ; Module width = SCALE (1)
    ; Total pixel offset from start of QR area = ECX * SCALE
    ; Total byte offset = (ECX * SCALE) * 3
    
    mov EAX, ECX ; move size
    imul EAX, SCALE ; get the amt of bytes
    imul EAX, 3 ; by the scale, 75 bytes
    
    add EAX, EDI ; Add QuienZone, blank part offset
    
    ; Read Blue component (BMP is BGR) at row_buffer + EAX
    lea EBX, [row_buffer] ; same as mov EBX, row_buffer
    add EBX, EAX ; add the offset, to start from right to left
    
    movzx EDX, byte [EBX]  ; Read Blue
    
    ; Determine if black or white
    ; Black (0,0,0) < 128
    ; White (255,255,255) >= 128
    
    cmp EDX, 128 ; to check the color
    jl .is_black ; it is 0 0 0
    
    ; Is White (0)
    mov DL, 0 ; whites are 0, no bit
    jmp .store_bit ; store directly
    
.is_black:
    ; Is Black (1)
    mov DL, 1 ; store a 1
    
.store_bit:
    ; Store in qr_matrix[ESI * QR_SIZE + ECX]
    mov EAX, ESI ; move the row num
    imul EAX, QR_SIZE ; mul by qr size
    add EAX, ECX ; add the offset
    
    mov [qr_matrix + EAX], DL ; move to the posicion, the pixel
    
    inc ECX ; next pixel
    jmp .col_loop ; back to col loop
    
.proc_done:
    popa ; restore register
    ret ; return, the change is qr_matrix
