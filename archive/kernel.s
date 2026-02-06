[ORG 0x1000]
[BITS 32]

; what to write %1
; offset to write %2
%macro print 3
    
    jmp %%PREP
    %%M: db %1
    %%E: db 0h

%%PREP:
    mov edi, 0xB8000
    add edi, %2
    mov esi, %%M
    mov ah, %3
%%LOOP:
    lodsb
    ;; load into ah
    or al, al
    jz %%DONE

    mov [edi], ax
    add edi, 2

    jmp %%LOOP
%%DONE:
%endmacro

_kernel:
    .start:
        ;; remember start address of kernel main
    
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000    
    
    mov edi, 0xB8000
    mov ecx, 2000

    mov ax, 0x1F20
    rep stosw

    mov edi, 0xB8000
    print "Welcome to ", 1980, 0x1f
    print "VenOS :-]", 2002, 0b00011111

    jmp $

    .end:
        ;; exit kernal with provided exit code

times 512 - ($ -$$) db 0
