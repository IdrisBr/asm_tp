section .bss
    input_buffer resb 1024      ; Buffer pour l'entrée (max 1024 octets)
    vowel_count resq 1          ; Compteur de voyelles
    output_buffer resb 32       ; Buffer pour la sortie

section .text
    global _start

_start:
    ; ==========================================
    ; Lire l'entrée depuis stdin
    ; ==========================================
    mov rax, 0                  ; syscall: sys_read
    mov rdi, 0                  ; fd: stdin
    mov rsi, input_buffer       ; buffer de destination
    mov rdx, 1024               ; nombre max d'octets à lire
    syscall
    
    ; rax contient le nombre d'octets lus
    cmp rax, 0
    jle empty_input
    
    mov rcx, rax                ; rcx = nombre d'octets lus
    
    ; ==========================================
    ; Compter les voyelles
    ; Voyelles: a, e, i, o, u, y, A, E, I, O, U, Y
    ; ==========================================
    xor rbx, rbx                ; rbx = compteur de voyelles (0)
    xor r8, r8                  ; r8 = index dans le buffer (0)
    
.count_loop:
    ; Vérifier si on a fini de traiter tous les caractères
    cmp r8, rcx
    jge .done
    
    ; Charger le caractère courant
    movzx rax, byte [input_buffer + r8]
    
    ; Vérifier si c'est une voyelle (minuscule ou majuscule)
    ; Inclure Y comme voyelle
    
    cmp al, 'a'
    je .is_vowel
    cmp al, 'e'
    je .is_vowel
    cmp al, 'i'
    je .is_vowel
    cmp al, 'o'
    je .is_vowel
    cmp al, 'u'
    je .is_vowel
    cmp al, 'y'
    je .is_vowel
    
    cmp al, 'A'
    je .is_vowel
    cmp al, 'E'
    je .is_vowel
    cmp al, 'I'
    je .is_vowel
    cmp al, 'O'
    je .is_vowel
    cmp al, 'U'
    je .is_vowel
    cmp al, 'Y'
    je .is_vowel
    
    ; Pas une voyelle, passer au caractère suivant
    jmp .next_char
    
.is_vowel:
    inc rbx                     ; Incrémenter le compteur de voyelles
    
.next_char:
    inc r8                      ; Passer au caractère suivant
    jmp .count_loop
    
.done:
    mov [vowel_count], rbx      ; Sauvegarder le résultat
    jmp print_result

empty_input:
    ; Cas spécial: entrée vide
    mov qword [vowel_count], 0
    jmp print_result

; ==========================================
; Afficher le résultat (uniquement le nombre)
; ==========================================
print_result:
    mov rdi, [vowel_count]      ; rdi = nombre à afficher
    call print_unsigned_int
    jmp exit_success

; ==========================================
; FONCTION: print_unsigned_int
; Entrée: rdi = nombre non signé à afficher
; Sortie: affiche le nombre suivi d'un newline
; ==========================================
print_unsigned_int:
    mov rax, rdi                ; rax = nombre à afficher
    mov rsi, output_buffer      ; rsi = buffer de sortie
    xor rcx, rcx                ; rcx = index dans le buffer
    
    ; Cas spécial: 0
    test rax, rax
    jnz .not_zero
    mov byte [rsi], '0'
    inc rcx
    jmp .add_newline
    
.not_zero:
    ; Convertir le nombre en chaîne (de droite à gauche)
    mov rbx, rax
    mov r8, 0                   ; r8 = compteur de chiffres
    
    ; Utiliser la fin du buffer comme zone temporaire
    mov rdi, output_buffer + 20
    
.convert_loop:
    xor rdx, rdx
    mov rax, rbx
    mov r9, 10
    div r9                      ; rax = rbx / 10, rdx = rbx % 10
    
    add dl, '0'                 ; Convertir le reste en ASCII
    mov [rdi + r8], dl
    inc r8
    
    mov rbx, rax                ; rbx = quotient
    test rbx, rbx
    jnz .convert_loop
    
    ; Copier les chiffres en inversant
    dec r8
.copy_reverse:
    mov dl, [rdi + r8]
    mov [rsi + rcx], dl
    inc rcx
    dec r8
    cmp r8, -1
    jne .copy_reverse
    
.add_newline:
    ; Ajouter newline
    mov byte [rsi + rcx], 10
    inc rcx
    
    ; Afficher le résultat
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    mov rdx, rcx                ; longueur
    syscall
    ret

; ==========================================
; Sortie du programme
; ==========================================
exit_success:
    mov rax, 60                 ; syscall: sys_exit
    xor rdi, rdi                ; exit code = 0
    syscall
