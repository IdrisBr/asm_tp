section .bss
    num1 resq 1                 ; Premier nombre (64 bits)
    num2 resq 1                 ; Deuxième nombre (64 bits)
    num3 resq 1                 ; Troisième nombre (64 bits)
    max_val resq 1              ; Valeur maximale trouvée
    output_buffer resb 32       ; Buffer pour la sortie

section .text
    global _start

_start:
    ; ==========================================
    ; Vérifier le nombre d'arguments
    ; Au démarrage: [rsp] = argc
    ;               [rsp+8] = argv[0]
    ;               [rsp+16] = argv[1]
    ;               [rsp+24] = argv[2]
    ;               [rsp+32] = argv[3]
    ; ==========================================
    
    mov rcx, [rsp]              ; rcx = argc
    cmp rcx, 4                  ; Vérifier qu'il y a exactement 3 arguments
    jne usage_error             ; Si argc != 4, erreur
    
    ; ==========================================
    ; Parser les trois nombres
    ; ==========================================
    
    ; Parser argv[1] -> num1
    mov rdi, [rsp + 16]
    call parse_signed_int
    mov [num1], rax
    
    ; Parser argv[2] -> num2
    mov rdi, [rsp + 24]
    call parse_signed_int
    mov [num2], rax
    
    ; Parser argv[3] -> num3
    mov rdi, [rsp + 32]
    call parse_signed_int
    mov [num3], rax
    
    ; ==========================================
    ; Trouver le maximum des trois nombres
    ; Algorithme: max = max(max(num1, num2), num3)
    ; ==========================================
    
    mov rax, [num1]             ; rax = num1
    mov rbx, [num2]             ; rbx = num2
    
    ; Comparer num1 et num2
    cmp rax, rbx
    jge .first_is_max           ; Si num1 >= num2, garder num1
    mov rax, rbx                ; Sinon, prendre num2
    
.first_is_max:
    ; rax contient maintenant max(num1, num2)
    ; Comparer avec num3
    mov rbx, [num3]             ; rbx = num3
    cmp rax, rbx
    jge .found_max              ; Si max(num1,num2) >= num3, c'est le max final
    mov rax, rbx                ; Sinon, num3 est le maximum
    
.found_max:
    mov [max_val], rax          ; Sauvegarder le maximum
    
    ; ==========================================
    ; Afficher le résultat (juste le nombre, pas de texte)
    ; ==========================================
    mov rdi, rax                ; rdi = nombre à afficher
    call print_signed_int
    
    jmp exit_success

; ==========================================
; FONCTION: parse_signed_int
; Entrée: rdi = pointeur vers la chaîne
; Sortie: rax = nombre converti (signé)
; ==========================================
parse_signed_int:
    xor rax, rax                ; rax = 0 (accumulateur)
    xor rcx, rcx                ; rcx = 0 (index)
    xor r8, r8                  ; r8 = 0 (flag de signe, 0=positif, 1=négatif)
    xor r9, r9                  ; r9 = 0 (compteur de chiffres)
    
    ; Vérifier si le premier caractère est '-'
    mov bl, byte [rdi]
    cmp bl, '-'
    jne .parse_loop
    inc r8                      ; Marquer comme négatif
    inc rcx                     ; Sauter le '-'
    
.parse_loop:
    movzx rbx, byte [rdi + rcx]
    
    ; Vérifier fin de chaîne
    test bl, bl
    jz .done
    
    ; Vérifier si c'est un chiffre
    cmp bl, '0'
    jb .invalid
    cmp bl, '9'
    ja .invalid
    
    ; Conversion ASCII -> int
    sub bl, '0'
    inc r9                      ; Compter le chiffre
    
    ; rax = rax * 10 + digit
    imul rax, rax, 10
    movzx rbx, bl
    add rax, rbx
    
    inc rcx
    jmp .parse_loop
    
.done:
    ; Vérifier qu'au moins un chiffre a été lu
    test r9, r9
    jz .invalid
    
    ; Appliquer le signe si nécessaire
    test r8, r8
    jz .positive
    neg rax                     ; Transformer en négatif
    
.positive:
    ret
    
.invalid:
    jmp invalid_input

; ==========================================
; FONCTION: print_signed_int
; Entrée: rdi = nombre à afficher (signé 64 bits)
; Sortie: affiche le nombre suivi d'un newline
; ==========================================
print_signed_int:
    mov rax, rdi                ; rax = nombre à afficher
    mov rsi, output_buffer      ; rsi = buffer de sortie
    xor rcx, rcx                ; rcx = index dans le buffer
    
    ; Gérer le signe
    test rax, rax
    jns .positive               ; Si positif, continuer
    
    ; Si négatif, ajouter '-' et inverser le nombre
    mov byte [rsi], '-'
    inc rcx
    neg rax                     ; rax = |rax|
    
.positive:
    ; Cas spécial: 0
    test rax, rax
    jnz .not_zero
    mov byte [rsi + rcx], '0'
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
