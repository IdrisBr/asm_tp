section .bss
    number resq 1               ; Nombre converti (64 bits)
    output_buffer resb 80       ; Buffer pour la sortie

section .text
    global _start

_start:
    ; ==========================================
    ; Accès aux arguments depuis la stack
    ; Au démarrage: [rsp] = argc
    ;               [rsp+8] = argv[0] (nom du programme)
    ;               [rsp+16] = argv[1] (premier argument)
    ;               [rsp+24] = argv[2] (deuxième argument)
    ; ==========================================
    
    mov rcx, [rsp]              ; rcx = argc (nombre d'arguments)
    cmp rcx, 2                  ; Vérifier qu'il y a au moins 1 argument
    jl usage_error              ; Si argc < 2, erreur d'usage
    
    ; Récupérer argv[1] (le nombre décimal)
    mov rdi, [rsp + 16]         ; rdi = pointeur vers argv[1]
    
    ; Parser le nombre décimal
    call parse_decimal          ; rax contiendra le nombre
    mov [number], rax           ; Sauvegarder le nombre
    
    ; Vérifier si argc >= 3 (option -b présente)
    cmp rcx, 3
    jl print_hex                ; Si pas d'option, afficher en hexa
    
    ; Récupérer argv[2] pour vérifier si c'est "-b"
    mov r8, [rsp + 24]          ; r8 = pointeur vers argv[2]
    
    ; Vérifier si c'est "-b"
    mov al, byte [r8]
    cmp al, '-'
    jne print_hex
    mov al, byte [r8+1]
    cmp al, 'b'
    jne print_hex
    mov al, byte [r8+2]
    test al, al                 ; Vérifier que c'est bien la fin
    jnz print_hex
    
    jmp print_binary

; ==========================================
; FONCTION: parse_decimal
; Entrée: rdi = pointeur vers la chaîne
; Sortie: rax = nombre converti
; ==========================================
parse_decimal:
    xor rax, rax                ; rax = 0 (accumulateur)
    xor rcx, rcx                ; rcx = 0 (index)
    xor r9, r9                  ; r9 = compteur de chiffres
    
.loop:
    movzx rbx, byte [rdi + rcx] ; Charger un caractère
    
    ; Vérifier fin de chaîne
    test bl, bl
    jz .done
    
    ; Vérifier si c'est un chiffre
    cmp bl, '0'
    jb invalid_input
    cmp bl, '9'
    ja invalid_input
    
    ; Conversion ASCII -> int
    sub bl, '0'
    inc r9                      ; Compter le chiffre
    
    ; rax = rax * 10 + digit
    imul rax, rax, 10
    movzx rbx, bl
    add rax, rbx
    
    inc rcx
    jmp .loop
    
.done:
    ; Vérifier qu'au moins un chiffre a été lu
    test r9, r9
    jz invalid_input
    ret

; ==========================================
; FONCTION: print_hex
; Convertit le nombre en hexadécimal et l'affiche
; ==========================================
print_hex:
    mov rax, [number]           ; Charger le nombre
    mov rsi, output_buffer      ; Pointeur vers le buffer de sortie
    
    ; Cas spécial: nombre = 0
    test rax, rax
    jnz .not_zero
    
    mov byte [rsi], '0'
    mov byte [rsi+1], 10        ; Newline
    mov rdx, 2                  ; Longueur = 2
    jmp .print
    
.not_zero:
    ; Conversion en hexadécimal (de droite à gauche)
    mov rbx, rax                ; rbx = nombre à convertir
    mov rcx, 0                  ; rcx = index dans le buffer
    
    ; Remplir le buffer de droite à gauche
.convert_loop:
    mov rax, rbx
    and rax, 0x0F               ; Extraire les 4 bits de poids faible
    
    ; Convertir 0-15 en caractère hex
    cmp al, 9
    jle .digit
    add al, 'A' - 10            ; A-F (MAJUSCULES)
    jmp .store
.digit:
    add al, '0'                 ; 0-9
    
.store:
    mov [output_buffer + rcx], al
    inc rcx
    shr rbx, 4                  ; Décaler de 4 bits vers la droite
    test rbx, rbx
    jnz .convert_loop
    
    ; Inverser la chaîne (elle est à l'envers)
    mov r8, 0                   ; r8 = début
    mov r9, rcx                 ; r9 = fin
    dec r9
    
.reverse_loop:
    cmp r8, r9
    jge .reverse_done
    
    ; Échanger output_buffer[r8] et output_buffer[r9]
    mov al, [output_buffer + r8]
    mov bl, [output_buffer + r9]
    mov [output_buffer + r8], bl
    mov [output_buffer + r9], al
    
    inc r8
    dec r9
    jmp .reverse_loop
    
.reverse_done:
    ; Ajouter newline
    mov byte [output_buffer + rcx], 10
    inc rcx
    mov rdx, rcx                ; rdx = longueur totale
    
.print:
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    mov rsi, output_buffer
    syscall
    
    jmp exit_success

; ==========================================
; FONCTION: print_binary
; Convertit le nombre en binaire et l'affiche
; ==========================================
print_binary:
    mov rax, [number]           ; Charger le nombre
    mov rsi, output_buffer      ; Pointeur vers le buffer de sortie
    
    ; Cas spécial: nombre = 0
    test rax, rax
    jnz .not_zero
    
    mov byte [rsi], '0'
    mov byte [rsi+1], 10        ; Newline
    mov rdx, 2                  ; Longueur = 2
    jmp .print
    
.not_zero:
    mov rbx, rax                ; rbx = nombre à convertir
    mov rcx, 0                  ; rcx = index dans le buffer
    
    ; Remplir le buffer de droite à gauche
.convert_loop:
    mov rax, rbx
    and rax, 1                  ; Extraire le bit de poids faible
    add al, '0'                 ; Convertir en caractère '0' ou '1'
    mov [output_buffer + rcx], al
    inc rcx
    shr rbx, 1                  ; Décaler de 1 bit vers la droite
    test rbx, rbx
    jnz .convert_loop
    
    ; Inverser la chaîne
    mov r8, 0                   ; r8 = début
    mov r9, rcx                 ; r9 = fin
    dec r9
    
.reverse_loop:
    cmp r8, r9
    jge .reverse_done
    
    ; Échanger output_buffer[r8] et output_buffer[r9]
    mov al, [output_buffer + r8]
    mov bl, [output_buffer + r9]
    mov [output_buffer + r8], bl
    mov [output_buffer + r9], al
    
    inc r8
    dec r9
    jmp .reverse_loop
    
.reverse_done:
    ; Ajouter newline
    mov byte [output_buffer + rcx], 10
    inc rcx
    mov rdx, rcx                ; rdx = longueur totale
    
.print:
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    mov rsi, output_buffer
    syscall
    
    jmp exit_success

; ==========================================
; Sorties du programme
; ==========================================
exit_success:
    mov rax, 60                 ; syscall: sys_exit
    xor rdi, rdi                ; exit code = 0
    syscall

usage_error:
invalid_input:
    mov rax, 60                 ; syscall: sys_exit
    mov rdi, 1                  ; exit code = 1
    syscall
