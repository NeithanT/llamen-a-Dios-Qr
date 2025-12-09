; =============================================================================
; QR Code Reader - Shared Constants and Data Structures
; This file contains all shared constants, variables, and buffers used across
; the QR code reading modules.
; =============================================================================

; QR Parameters
SCALE           equ 1
QR_SIZE         equ 25
QUIET_ZONE      equ 4
ROW_SIZE        equ 100             ; (33 * 3) + 1 padding

; Error codes
ERROR_SUCCESS       equ 0
ERROR_FILE_OPEN     equ 1
ERROR_FILE_READ     equ 2
ERROR_INVALID_FMT   equ 3

; Data capacity
MAX_ENCODED_BYTES   equ 44          ; Max capacity for V2-M
MAX_CHAR_COUNT      equ 26          ; Reliable character count (see decode_stream for details)

; QR Code constants
BYTE_MODE           equ 0100b       ; Byte encoding mode indicator
QR_MATRIX_SIZE      equ 625         ; QR_SIZE * QR_SIZE
