[BITS 16]
[ORG 0x7c00]      

_start:
    hlt

times 510 - ($ - $$) db 0
dw 0xAA55
