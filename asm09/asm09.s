section .data
    hex_prefix db '0x', 0
    binary_prefix db '0b', 0
    newline db 10, 0

section .bss
    input_buffer resb 32        ; Buffer pour l'entrée utilisateur
    output_buffer resb 80       ; Buffer pour la sortie (hex/binary)
    number resq 1               ; Nombre converti (64 bits)

section .text
    global _start

_start:
    ; ==========================================
    ; Vérifier les arguments de ligne de commande
    ; ==========================================
    ; argc est dans [rsp], argv[0] dans [rsp+8], argv[1] dans [rsp+16], etc.
    
    pop rax                     ; rax = argc (nombre d'arguments)
    cmp rax, 2                  ; Vérifier qu'il y a au moins 1 argument
    jl usage_error              ; Si argc < 2, erreur
    
    pop rdi                     ; rdi = argv[0] (nom du programme, non utilisé)
    pop rdi                     ; rdi = argv[1] (le nombre décimal)
    
    ; ==========================================
    ; Parser le nombre décimal depuis argv[1]
    ; ==========================================
    call parse_decimal          ; rax contiendra le nombre
    mov [number], rax           ; Sauvegarder le nombre
    
    ; ==========================================
    ; Vérifier si l'option -b est présente
    ; ==========================================
    pop r8                      ; r8 = argv[2] (option éventuelle)
    test r8, r8                 ; Vérifier si argv[2] existe
    jz print_hex                ; Si pas d'option, afficher en hexa par défaut
    
    ; Vérifier si c'est "-b"
    mov al, byte [r8]
    cmp al, '-'
    jne print_hex
    mov al, byte [r8+1]
    cmp al, 'b'
    je print_binary
    
    ; Sinon afficher en hexa
    jmp print_hex

; ==========================================
; FONCTION: parse_decimal
; Entrée: rdi = pointeur vers la chaîne
; Sortie: rax = nombre converti
; ==========================================
parse_decimal:
    xor rax, rax                ; rax = 0 (accumulateur)
    xor rcx, rcx                ; rcx = 0 (index)
    
.loop:
    movzx rbx, byte [rdi + rcx] ; Charger un caractère
    
    ; Vérifier fin de chaîne
    test bl, bl
    jz .done
    cmp bl, 10                  ; Newline
    je .done
    cmp bl, ' '
    je .done
    
    ; Vérifier si c'est un chiffre
    cmp bl, '0'
    jb invalid_input
    cmp bl, '9'
    ja invalid_input
    
    ; Conversion ASCII -> int
    sub bl, '0'
    
    ; rax = rax * 10 + digit
    imul rax, rax, 10
    movzx rbx, bl
    add rax, rbx
    
    inc rcx
    jmp .loop
    
.done:
    ret

; ==========================================
; FONCTION: print_hex
; Convertit le nombre en hexadécimal et l'affiche
; ==========================================
print_hex:
    mov rax, [number]           ; Charger le nombre
    
    ; Afficher le préfixe "0x"
    mov rdi, hex_prefix
    call print_string
    
    ; Préparer la conversion hex
    mov rsi, output_buffer
    mov rcx, 16                 ; 16 chiffres hex max pour 64 bits
    mov rbx, rax                ; rbx = le nombre à convertir
    
    ; Trouver le premier chiffre non-nul
    mov r8, 60                  ; Commencer par le quartet le plus significatif (bit 60-63)
    
.find_first:
    cmp r8, 0
    jl .print_zero              ; Si on arrive à -4, le nombre est 0
    
    mov rax, rbx
    mov cl, r8b                 ; Shift count
    shr rax, cl                 ; Extraire le quartet
    and rax, 0x0F               ; Masquer pour obtenir 4 bits
    
    cmp rax, 0
    jne .convert_loop_start     ; Si non-nul, commencer la conversion
    
    sub r8, 4                   ; Passer au quartet suivant
    jmp .find_first

.print_zero:
    mov byte [output_buffer], '0'
    mov byte [output_buffer+1], 0
    mov rdi, output_buffer
    call print_string
    jmp exit_success

.convert_loop_start:
    xor r9, r9                  ; r9 = index dans output_buffer
    
.convert_loop:
    mov rax, rbx
    mov cl, r8b
    shr rax, cl
    and rax, 0x0F
    
    ; Convertir 0-15 en caractère hex
    cmp al, 9
    jle .digit
    add al, 'a' - 10            ; a-f
    jmp .store
.digit:
    add al, '0'                 ; 0-9
    
.store:
    mov [output_buffer + r9], al
    inc r9
    
    sub r8, 4
    cmp r8, 0
    jge .convert_loop
    
    ; Terminer la chaîne
    mov byte [output_buffer + r9], 0
    
    ; Afficher le résultat
    mov rdi, output_buffer
    call print_string
    
    jmp exit_success

; ==========================================
; FONCTION: print_binary
; Convertit le nombre en binaire et l'affiche
; ==========================================
print_binary:
    mov rax, [number]           ; Charger le nombre
    
    ; Afficher le préfixe "0b"
    mov rdi, binary_prefix
    call print_string
    
    ; Gérer le cas spécial de 0
    test rax, rax
    jnz .find_first_bit
    
    mov byte [output_buffer], '0'
    mov byte [output_buffer+1], 0
    mov rdi, output_buffer
    call print_string
    jmp exit_success
    
.find_first_bit:
    mov rbx, rax                ; rbx = le nombre
    mov rcx, 63                 ; Commencer par le bit le plus significatif
    
    ; Trouver le premier bit à 1
.find_loop:
    bt rbx, rcx                 ; Tester le bit rcx
    jc .convert_start           ; Si carry flag = 1, bit trouvé
    dec rcx
    jmp .find_loop
    
.convert_start:
    xor r9, r9                  ; r9 = index dans output_buffer
    
.convert_loop:
    bt rbx, rcx                 ; Tester le bit rcx
    jc .bit_one
    
    mov byte [output_buffer + r9], '0'
    jmp .next_bit
    
.bit_one:
    mov byte [output_buffer + r9], '1'
    
.next_bit:
    inc r9
    dec rcx
    cmp rcx, 0
    jge .convert_loop
    
    ; Terminer la chaîne
    mov byte [output_buffer + r9], 0
    
    ; Afficher le résultat
    mov rdi, output_buffer
    call print_string
    
    jmp exit_success

; ==========================================
; FONCTION: print_string
; Entrée: rdi = pointeur vers la chaîne
; ==========================================
print_string:
    push rdi
    
    ; Calculer la longueur de la chaîne
    xor rax, rax                ; rax = compteur de longueur
.len_loop:
    cmp byte [rdi + rax], 0
    je .print
    inc rax
    jmp .len_loop
    
.print:
    mov rdx, rax                ; rdx = longueur
    pop rsi                     ; rsi = pointeur vers la chaîne
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    syscall
    ret

; ==========================================
; Sorties du programme
; ==========================================
exit_success:
    ; Afficher un newline
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    mov rax, 60                 ; syscall: sys_exit
    xor rdi, rdi                ; exit code = 0
    syscall

usage_error:
invalid_input:
    mov rax, 60                 ; syscall: sys_exit
    mov rdi, 1                  ; exit code = 1
    syscall
