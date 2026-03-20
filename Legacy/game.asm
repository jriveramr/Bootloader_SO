[org 0x0000]
bits 16

jmp start_game

%include "random.asm"

;--------------------------------
; VARIABLES
;--------------------------------
state      db 0
row        db 0
col        db 0
saved_drive db 0        ; guardamos DL aquí al entrar

;--------------------------------
; ENTRY POINT
;--------------------------------
start_game:
    mov ax, cs
    mov ds, ax

    mov [saved_drive], dl   ; DL viene del bootloader con el drive correcto

    mov byte [state], 0

    call init_seed

    mov cx, 20
    call random_range
    mov [row], al

    mov cx, 65
    call random_range
    mov [col], al

;--------------------------------
; LOOP PRINCIPAL
;--------------------------------
main_loop:
    mov ax, 0x0600
    mov bh, 0x07
    mov cx, 0x0000
    mov dx, 0x184F
    int 0x10

    cmp byte [state], 0
    je print_normal
    cmp byte [state], 1
    je print_vertical
    cmp byte [state], 2
    je print_reverse
    cmp byte [state], 3
    je print_vertical_rev

;--------------------------------
; MODOS DE TEXTO
;--------------------------------
print_normal:
    mov si, msg
    call print_string
    jmp wait_key

print_reverse:
    mov si, msg_rev
    call print_string
    jmp wait_key

print_vertical:
    mov si, msg
    mov cx, msg_len
    mov bl, 0
.vloop:
    mov ah, 0x02
    mov bh, 0
    mov dh, [row]
    add dh, bl
    mov dl, [col]
    int 0x10
    lodsb
    mov ah, 0x0E
    int 0x10
    inc bl
    loop .vloop
    jmp wait_key

print_vertical_rev:
    mov si, msg_rev
    mov cx, msg_len
    mov bl, 0
.vloop2:
    mov ah, 0x02
    mov bh, 0
    mov dh, [row]
    add dh, bl
    mov dl, [col]
    int 0x10
    lodsb
    mov ah, 0x0E
    int 0x10
    inc bl
    loop .vloop2
    jmp wait_key

;--------------------------------
; TECLADO
;--------------------------------
wait_key:
    mov ah, 0
    int 0x16

    cmp al, 27
    je exit_to_menu

    cmp ah, 0x4B
    je rot_left
    cmp ah, 0x4D
    je rot_right
    cmp ah, 0x48
    je rot_flip
    cmp ah, 0x50
    je rot_flip

    jmp main_loop

exit_to_menu:
    ; Restaurar DL y volver al bootloader
    mov dl, [saved_drive]
    jmp 0x0000:0x7C00

;--------------------------------
; ROTACIONES
;--------------------------------
rot_left:
    inc byte [state]
    and byte [state], 3
    jmp main_loop

rot_right:
    cmp byte [state], 0
    jne .not_zero
    mov byte [state], 3
    jmp main_loop
.not_zero:
    dec byte [state]
    jmp main_loop

rot_flip:
    cmp byte [state], 0
    je .set_2
    cmp byte [state], 2
    je .set_0
    cmp byte [state], 1
    je .set_3
    cmp byte [state], 3
    je .set_1
.set_0: mov byte [state], 0
    jmp main_loop
.set_1: mov byte [state], 1
    jmp main_loop
.set_2: mov byte [state], 2
    jmp main_loop
.set_3: mov byte [state], 3
    jmp main_loop

;--------------------------------
; PRINT STRING
;--------------------------------
print_string:
    mov ah, 0x02
    mov bh, 0
    mov dh, [row]
    mov dl, [col]
    int 0x10
.next:
    lodsb
    cmp al, 0
    je .done
    mov ah, 0x0E
    int 0x10
    jmp .next
.done:
    ret

;--------------------------------
; DATOS
;--------------------------------
msg     db "ANDRES Y JOSE", 0
msg_rev db "ESOJ Y SERDNA", 0
msg_len equ 13

times 10240-($-$$) db 0