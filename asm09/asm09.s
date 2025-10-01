section .bss
    number resq 1               ; Nombre converti (64 bits)
    output_buffer resb 80       ; Buffer pour la sortie

section .text
    global _start

_start:
    ; ==========================================
    ; Accès aux arguments depuis la stack
    ; Au démarrage: [rsp] = argc
    ;               [rsp+8] = argv[0]
    ;               [rsp+16] = argv[1]
    ;               [rsp+24] = argv[2]
    ; ==========================================
    
    mov rcx, [rsp]              ; rcx = argc
    cmp rcx, 2                  ; Vérifier qu'il y a au moins 1 argument
    jl usage_error
    
    ; Vérifier d'abord si argv[1] est "-b"
    mov r8, [rsp + 16]          ; r8 = argv[1]
    mov al, byte [r8]
    cmp al, '-'
    jne .not_option
    mov al, byte [r8+1]
    cmp al, 'b'
    jne .not_option
    mov al, byte [r8+2]
    test al, al
    jnz .not_option
    
    ; Si argv[1] == "-b", le nombre est dans argv[2]
    cmp rcx, 3                  ; Vérifier argc >= 3
    jl usage_error
    mov rdi, [rsp + 24]         ; rdi = argv[2] (le nombre)
    call parse_decimal
    mov [number], rax
    jmp print_binary
    
.not_option:
    ; argv[1] est le nombre
    mov rdi, [rsp + 16]
    call parse_decimal
    mov [number], rax
    
    ; Vérifier si argv[2] existe et est "-b"
    cmp rcx, 3
    jl print_hex
    
    mov r8, [rsp + 24]          ; r8 = argv[2]
    mov al, byte [r8]
    cmp al, '-'
    jne print_hex
    mov al, byte [r8+1]
    cmp al, 'b'
    jne print_hex
    mov al, byte [r8+2]
    test al, al
    jnz print_hex
    
    jmp print_binary

; ==========================================
; FONCTION: parse_decimal
; Entrée: rdi = pointeur vers la chaîne
; Sortie: rax = nombre converti
; ==========================================
parse_decimal:
    xor rax, rax
    xor rcx, rcx
    xor r9, r9
    
.loop:
    movzx rbx, byte [rdi + rcx]
    test bl, bl
    jz .done
    
    cmp bl, '0'
    jb invalid_input
    cmp bl, '9'
    ja invalid_input
    
    sub bl, '0'
    inc r9
    
    imul rax, rax, 10
    movzx rbx, bl
    add rax, rbx
    
    inc rcx
    jmp .loop
    
.done:
    test r9, r9
    jz invalid_input
    ret

; ==========================================
; FONCTION: print_hex
; ==========================================
print_hex:
    mov rax, [number]
    
    ; Cas spécial: 0
    test rax, rax
    jnz .not_zero
    mov byte [output_buffer], '0'
    mov byte [output_buffer+1], 10
    mov rdx, 2
    jmp .print
    
.not_zero:
    ; Convertir en hex (stockage de droite à gauche dans un buffer temporaire)
    mov rbx, rax
    xor rcx, rcx                ; Compteur de chiffres
    
    ; Utiliser la fin du buffer pour stocker temporairement
    mov rsi, output_buffer + 40 ; Milieu du buffer
    
.convert_loop:
    mov rax, rbx
    and rax, 0x0F
    
    cmp al, 9
    jle .digit
    add al, 'A' - 10
    jmp .store
.digit:
    add al, '0'
    
.store:
    mov [rsi + rcx], al
    inc rcx
    shr rbx, 4
    test rbx, rbx
    jnz .convert_loop
    
    ; Copier en inversant vers le début du buffer
    xor r8, r8                  ; Index destination
    dec rcx                     ; rcx pointe sur le dernier caractère
    
.copy_reverse:
    mov al, [rsi + rcx]
    mov [output_buffer + r8], al
    inc r8
    dec rcx
    cmp rcx, -1
    jne .copy_reverse
    
    ; Ajouter newline
    mov byte [output_buffer + r8], 10
    inc r8
    mov rdx, r8
    
.print:
    mov rax, 1
    mov rdi, 1
    mov rsi, output_buffer
    syscall
    jmp exit_success

; ==========================================
; FONCTION: print_binary
; ==========================================
print_binary:
    mov rax, [number]
    
    ; Cas spécial: 0
    test rax, rax
    jnz .not_zero
    mov byte [output_buffer], '0'
    mov byte [output_buffer+1], 10
    mov rdx, 2
    jmp .print
    
.not_zero:
    mov rbx, rax
    xor rcx, rcx
    
    ; Utiliser la fin du buffer
    mov rsi, output_buffer + 40
    
.convert_loop:
    mov rax, rbx
    and rax, 1
    add al, '0'
    mov [rsi + rcx], al
    inc rcx
    shr rbx, 1
    test rbx, rbx
    jnz .convert_loop
    
    ; Copier en inversant
    xor r8, r8
    dec rcx
    
.copy_reverse:
    mov al, [rsi + rcx]
    mov [output_buffer + r8], al
    inc r8
    dec rcx
    cmp rcx, -1
    jne .copy_reverse
    
    ; Ajouter newline
    mov byte [output_buffer + r8], 10
    inc r8
    mov rdx, r8
    
.print:
    mov rax, 1
    mov rdi, 1
    mov rsi, output_buffer
    syscall
    jmp exit_success

; ==========================================
; Sorties
; ==========================================
exit_success:
    mov rax, 60
    xor rdi, rdi
    syscall

usage_error:
invalid_input:
    mov rax, 60
    mov rdi, 1
    syscall
