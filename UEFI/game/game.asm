; ─────────────────────────────────────────────────────────────────────────────
; game.asm — Juego de nombres, UEFI bare-metal x86-64
; Ensamblado con NASM → PE/COFF via lld-link
; ─────────────────────────────────────────────────────────────────────────────

bits 64
default rel

; ─── Constantes ───────────────────────────────────────────────────────────────
EFI_SUCCESS    equ 0
EFI_NOT_READY  equ 0x8000000000000006

SCAN_UP        equ 0x01
SCAN_DOWN      equ 0x02
SCAN_RIGHT     equ 0x03
SCAN_LEFT      equ 0x04
SCAN_ESC       equ 0x17

KEY_R          equ 0x0072
KEY_Q          equ 0x0071

OUT_OUTPUT_STRING   equ 8
OUT_CLEAR_SCREEN    equ 48
OUT_SET_CURSOR      equ 56

IN_RESET            equ 0
IN_READ_KEY         equ 8

ST_CON_IN           equ 48
ST_CON_OUT          equ 64

NAME_COL       equ 10
NAME_ROW       equ 5

section .text
global efi_main

; ─────────────────────────────────────────────────────────────────────────────
; clear_and_position: ClearScreen + SetCursor en NAME_COL, NAME_ROW
; ─────────────────────────────────────────────────────────────────────────────
clear_and_position:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 40

    mov     rcx, [con_out]
    mov     rax, [rcx + OUT_CLEAR_SCREEN]
    call    rax

    mov     rcx, [con_out]
    mov     rdx, [name_col]
    mov     r8,  [name_row]
    mov     rax, [rcx + OUT_SET_CURSOR]
    call    rax

    add     rsp, 40
    pop     rbp
    ret

; ─────────────────────────────────────────────────────────────────────────────
; get_name_length → resultado en RCX
;   Cuenta caracteres de msg_names hasta \r o \0
; ─────────────────────────────────────────────────────────────────────────────
get_name_length:
    lea     rsi, [msg_names]
    xor     rcx, rcx
.loop:
    mov     ax, [rsi + rcx*2]
    cmp     ax, 0x000D
    je      .done
    cmp     ax, 0x0000
    je      .done
    inc     rcx
    jmp     .loop
.done:
    ret

; ─────────────────────────────────────────────────────────────────────────────
; render: dibuja msg_names segun current_state
;
;   Estado 0 — normal:          jose y henry  (horizontal izq→der)
;   Estado 1 — 90° derecha:     una letra por fila, primera letra arriba
;   Estado 2 — 180°:            yrnej y esoj  (horizontal invertido)
;   Estado 3 — 270° / 90° izq:  una letra por fila, ultima letra arriba
; ─────────────────────────────────────────────────────────────────────────────
render:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 40

    call    clear_and_position

    mov     rax, [current_state]
    cmp     rax, 0
    je      .state0
    cmp     rax, 1
    je      .state1
    cmp     rax, 2
    je      .state2
    cmp     rax, 3
    je      .state3
    jmp     .state0             ; fallback

; ── Estado 0: texto normal ────────────────────────────────────────────────────
.state0:
    mov     rcx, [con_out]
    lea     rdx, [msg_names]
    mov     rax, [rcx + OUT_OUTPUT_STRING]
    call    rax
    jmp     .render_done

; ── Estado 1: 90° derecha — primera letra arriba, cada letra en su fila ───────
.state1:
    call    get_name_length     ; RCX = longitud
    mov     r12, rcx            ; guardar longitud
    xor     r13, r13            ; r13 = indice (0..len-1)
.state1_loop:
    cmp     r13, r12
    jge     .render_done

    ; SetCursorPosition(NAME_COL, NAME_ROW + indice)
    mov     rcx, [con_out]
    mov     rdx, [name_col]
    mov     r8,  [name_row]
    add     r8,  r13
    mov     rax, [rcx + OUT_SET_CURSOR]
    call    rax

    ; Imprimir caracter en posicion r13
    lea     rsi, [msg_names]
    mov     ax,  [rsi + r13*2]
    mov     [char_buf],    ax
    mov     word [char_buf+2], 0

    mov     rcx, [con_out]
    lea     rdx, [char_buf]
    mov     rax, [rcx + OUT_OUTPUT_STRING]
    call    rax

    inc     r13
    jmp     .state1_loop

; ── Estado 2: 180° — texto invertido horizontal ───────────────────────────────
.state2:
    call    get_name_length     ; RCX = longitud
    dec     rcx                 ; indice del ultimo caracter
    mov     r12, rcx
.state2_loop:
    cmp     r12, 0
    jl      .render_done

    lea     rsi, [msg_names]
    mov     ax,  [rsi + r12*2]
    mov     [char_buf],    ax
    mov     word [char_buf+2], 0

    mov     rcx, [con_out]
    lea     rdx, [char_buf]
    mov     rax, [rcx + OUT_OUTPUT_STRING]
    call    rax

    dec     r12
    jmp     .state2_loop

; ── Estado 3: 270° / 90° izq — ultima letra arriba, cada letra en su fila ─────
.state3:
    call    get_name_length     ; RCX = longitud
    dec     rcx                 ; indice del ultimo caracter
    mov     r12, rcx            ; r12 = indice actual (va bajando)
    xor     r13, r13            ; r13 = fila relativa (va subiendo)
.state3_loop:
    cmp     r12, 0
    jl      .render_done

    ; SetCursorPosition(NAME_COL, NAME_ROW + fila_relativa)
    mov     rcx, [con_out]
    mov     rdx, [name_col]
    mov     r8,  [name_row]
    add     r8,  r13
    mov     rax, [rcx + OUT_SET_CURSOR]
    call    rax

    ; Imprimir caracter en posicion r12
    lea     rsi, [msg_names]
    mov     ax,  [rsi + r12*2]
    mov     [char_buf],    ax
    mov     word [char_buf+2], 0

    mov     rcx, [con_out]
    lea     rdx, [char_buf]
    mov     rax, [rcx + OUT_OUTPUT_STRING]
    call    rax

    dec     r12
    inc     r13
    jmp     .state3_loop

.render_done:
    ; Instrucciones en fila 22
    mov     rcx, [con_out]
    mov     rdx, 0
    mov     r8,  22
    mov     rax, [rcx + OUT_SET_CURSOR]
    call    rax

    mov     rcx, [con_out]
    lea     rdx, [msg_ready]
    mov     rax, [rcx + OUT_OUTPUT_STRING]
    call    rax

    add     rsp, 40
    pop     rbp
    ret

; ─────────────────────────────────────────────────────────────────────────────
; efi_main
; ─────────────────────────────────────────────────────────────────────────────
efi_main:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 40

    mov     rax, [rdx + ST_CON_OUT]
    mov     [con_out], rax
    mov     rax, [rdx + ST_CON_IN]
    mov     [con_in], rax

    ; Inicializar semilla aleatoria
    call    init_seed

    ; Estado inicial = 0
    mov     qword [current_state], 0

    call    randomize_position
    call    render

    ; Reset ConIn
    mov     rcx, [con_in]
    xor     rdx, rdx
    mov     rax, [rcx + IN_RESET]
    call    rax

; ─────────────────────────────────────────────────────────────────────────────
; key_loop
; ─────────────────────────────────────────────────────────────────────────────
key_loop:
    sub     rsp, 16

    mov     rcx, [con_in]
    lea     rdx, [rsp]
    mov     rax, [rcx + IN_READ_KEY]
    call    rax

    cmp     rax, EFI_NOT_READY
    je      .no_key

    movzx   r8, word [rsp]
    movzx   r9, word [rsp + 2]
    add     rsp, 16

    cmp     r8, SCAN_RIGHT
    je      .key_right
    cmp     r8, SCAN_DOWN
    je      .key_down
    cmp     r8, SCAN_LEFT
    je      .key_left
    cmp     r8, SCAN_UP
    je      .key_up
    cmp     r8, SCAN_ESC
    je      .key_esc

    cmp     r9, KEY_R
    je      .key_r
    cmp     r9, KEY_Q
    je      .key_q

    jmp     key_loop

.no_key:
    add     rsp, 16
    jmp     key_loop

; ─── Flechas: modifican estado y llaman render ────────────────────────────────

.key_left:
    mov     rax, [current_state]
    inc     rax
    and     rax, 3
    mov     [current_state], rax
    call    render
    jmp     key_loop

.key_right:
    mov     rax, [current_state]
    add     rax, 3
    and     rax, 3
    mov     [current_state], rax
    call    render
    jmp     key_loop

.key_down:
.key_up:
    mov     rax, [current_state]
    add     rax, 2
    and     rax, 3
    mov     [current_state], rax
    call    render
    jmp     key_loop

; ─── Reiniciar ────────────────────────────────────────────────────────────────
.key_r:
    mov     qword [current_state], 0
    call    randomize_position
    call    render
    jmp     key_loop

; ─── Salir ────────────────────────────────────────────────────────────────────
.key_q:
.key_esc:
    call    clear_and_position
    mov     rcx, [con_out]
    lea     rdx, [msg_quit]
    mov     rax, [rcx + OUT_OUTPUT_STRING]
    call    rax
.halt:
    hlt
    jmp     .halt
; ─────────────────────────────────────────────────────────────────────────────
; randomize_position: calcula col en [0,79] y fila en [0,24]
;                     y las guarda en name_col y name_row
; ─────────────────────────────────────────────────────────────────────────────
randomize_position:
    push    rbp
    mov     rbp, rsp
    sub     rsp, 40

    mov     cx, 80
    call    random_range
    movzx   rax, ax
    mov     [name_col], rax

    mov     cx, 25
    call    random_range
    movzx   rax, ax
    mov     [name_row], rax

    add     rsp, 40
    pop     rbp
    ret
; ─────────────────────────────────────────────────────────────────────────────
; init_seed: inicializa semilla con RDTSC
; ─────────────────────────────────────────────────────────────────────────────
init_seed:
    rdtsc
    xor     eax, edx
    mov     [seed], ax
    ret

; ─────────────────────────────────────────────────────────────────────────────
; random → AX = numero pseudoaleatorio 16 bits
; ─────────────────────────────────────────────────────────────────────────────
random:
    mov     ax, [seed]
    mov     bx, 25173
    mul     bx
    add     ax, 13849
    mov     [seed], ax
    ret

; ─────────────────────────────────────────────────────────────────────────────
; random_range → AX = numero en [0, CX-1]
; Entrada: CX = limite superior
; ─────────────────────────────────────────────────────────────────────────────
random_range:
    call    random
    xor     dx, dx
    div     cx
    mov     ax, dx
    ret

; ─── Datos ────────────────────────────────────────────────────────────────────
section .data

con_out:       dq 0
con_in:        dq 0
current_state: dq 0
char_buf:      dw 0, 0

msg_names:
    dw  'j','o','s','e',' ','y',' ','h','e','n','r','y'
    dw  0x000D, 0x000A
    dw  0x0000

msg_ready:
    dw  0x2190,'/',0x2191,':',' ','e','s','t','a','d','o',' ','-'
    dw  ' ',0x2192,'/',0x2193,':',' ','e','s','t','a','d','o',' ','+'
    dw  ' ',' ','R',':',' ','r','e','i','n','i','c','i','a','r'
    dw  ' ',' ','Q',':',' ','s','a','l','i','r'
    dw  0x000D, 0x000A
    dw  0x0000

msg_quit:
    dw  'S','a','l','i','e','n','d','o','.','.','.'
    dw  0x000D, 0x000A, 0x0000

seed: dw 0
name_col: dq 0
name_row: dq 0