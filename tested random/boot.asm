[org 0x7C00]
bits 16

jmp start

%include "random.asm"

posX dw 0
posY dw 0

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    sti

    ; -------------------------
    ; init seed
    ; -------------------------
    call init_seed

    ; -------------------------
    ; limpiar pantalla
    ; -------------------------
    mov ah, 00h
    mov al, 03h
    int 10h

    ; -------------------------
    ; generar X
    ; -------------------------
    mov cx, 80
    call random_range
    mov [posX], ax

    ; -------------------------
    ; generar Y
    ; -------------------------
    mov cx, 25
    call random_range
    mov [posY], ax

    ; -------------------------
    ; imprimir "X="
    ; -------------------------
    mov al, 'X'
    call print_char
    mov al, '='
    call print_char

    mov ax, [posX]
    call print_number

    ; espacio
    mov al, ' '
    call print_char

    ; -------------------------
    ; imprimir "Y="
    ; -------------------------
    mov al, 'Y'
    call print_char
    mov al, '='
    call print_char

    mov ax, [posY]
    call print_number

hang:
    jmp hang

; =========================
; FUNCIONES
; =========================

print_char:
    mov ah, 0x0E
    int 10h
    ret

print_number:
    mov bx, 10
    xor cx, cx

.convert:
    xor dx, dx
    div bx
    push dx
    inc cx
    cmp ax, 0
    jne .convert

.print:
    pop dx
    add dl, '0'
    mov al, dl
    call print_char
    loop .print

    ret

; =========================
; BOOT SIGNATURE
; =========================
times 510 - ($ - $$) db 0
dw 0xAA55