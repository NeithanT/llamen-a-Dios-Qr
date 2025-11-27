
%include "io.mac"

.DATA

    cool    db "Compiles", 0
    
.CODE


.STARTUP

    PutStr cool
    nwln

.EXIT
