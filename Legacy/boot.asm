[org 0x7C00]
bits 16

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    mov [boot_drive], dl

menu:
    call clear_screen

    mov dh, 10
    mov dl, 25
    call set_cursor

    mov si, msg_menu
    call print_string

.wait_key:
    mov ah, 0
    int 0x16
    cmp al, 13
    je load_game
    jmp .wait_key

;--------------------------------
; CARGAR JUEGO DESDE DISCO
;--------------------------------
load_game:
    ; Reset controlador de disco
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13

    ; Destino: segmento 0x0800, offset 0x0000
    mov ax, 0x0800
    mov es, ax
    xor bx, bx

    ; Intentar lectura hasta 3 veces
    mov si, 3           ; contador de reintentos

.retry:
    mov ah, 0x02
    mov al, 20          ; sectores a leer
    mov ch, 0           ; cilindro 0
    mov dh, 0           ; cabeza 0
    mov cl, 2           ; desde sector 2
    mov dl, [boot_drive]
    int 0x13
    jnc .ok             ; sin carry = éxito

    ; Falló: reset y reintentar
    pusha
    mov ah, 0x00
    mov dl, [boot_drive]
    int 0x13
    popa

    dec si
    jnz .retry

    ; 3 intentos fallidos
    jmp disk_error

.ok:
    mov dl, [boot_drive]
    jmp 0x0800:0x0000

disk_error:
    call clear_screen
    mov si, msg_error
    call print_string
    jmp $

;--------------------------------
; UTILIDADES
;--------------------------------
clear_screen:
    mov ax, 0x0003
    int 0x10
    ret

set_cursor:
    mov ah, 0x02
    mov bh, 0
    int 0x10
    ret

print_string:
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
boot_drive  db 0
msg_menu    db "Presiona ENTER para iniciar el juego", 0
msg_error   db "Error al cargar el juego desde disco", 0

times 510-($-$$) db 0
dw 0xAA55