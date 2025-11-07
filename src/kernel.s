[BITS 32]

_kernel:
    .start:
        ;; remember start address of kernel main
    
    mov eax, 0x01
    mov esi, 0x02
    mov edi, 0x00

    .end:
        ;; exit kernal with provided exit code

times 512 - ($ -$$) db 0
