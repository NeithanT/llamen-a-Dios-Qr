%include "io.mac"

.DATA

    buffer          db "hello", 0

    BYTE_MODE       db "0100", 0
    CHARACTER_COUNT db 5 ; pad it to 0000 0101

.CODE


; GOTTA USE BYNARY MODEEEEEEEEEEEEEEEEEEEE

.STARTUP


    mov DL, buffer

    and DL, 0x01

    mov DL, buffer
    
    sar DL
    and DL, 0x01


    