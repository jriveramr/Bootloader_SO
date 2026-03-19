; ==========================================
; random.asm
; Generador pseudoaleatorio (LCG) 16 bits
; ==========================================

; ------------------------------------------
; DATA
; ------------------------------------------

seed dw 0          ; semilla (se inicializa luego con BIOS time)

; ------------------------------------------
; init_seed
; Inicializa la semilla usando BIOS time
; ------------------------------------------
init_seed:
    mov ah, 00h
    int 1Ah        ; CX:DX = ticks desde arranque

    mov [seed], dx ; usamos DX como semilla
    ret

; ------------------------------------------
; random
; Genera número pseudoaleatorio
; Retorna: AX = número random
; ------------------------------------------
random:
    mov ax, [seed]

    mov bx, 25173      ; constante a
    mul bx             ; DX:AX = AX * BX

    add ax, 13849      ; constante c

    ; overflow de 16 bits actúa como mod 65536

    mov [seed], ax     ; guardar nuevo estado

    ret

; ------------------------------------------
; random_range
; Genera número en rango [0, CX-1]
; Entrada: CX = límite superior
; Salida: AX = número en rango
; ------------------------------------------
random_range:
    call random        ; AX = random

    xor dx, dx
    div cx             ; AX / CX

    mov ax, dx         ; residuo = valor en rango

    ret