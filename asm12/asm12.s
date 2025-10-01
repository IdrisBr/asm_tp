section .bss
    input_buffer resb 1024      ; Buffer pour l'entrée (max 1024 octets)
    str_length resq 1           ; Longueur de la chaîne

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
    jle empty_input             ; Si rien n'a été lu, c'est vide
    
    ; Enlever le newline à la fin si présent
    mov rcx, rax                ; rcx = nombre d'octets lus
    dec rcx                     ; rcx pointe sur le dernier caractère
    cmp byte [input_buffer + rcx], 10  ; Vérifier si c'est un newline
    jne .no_newline
    ; Si c'est un newline, on le supprime de la longueur
    mov rax, rcx
    
.no_newline:
    ; rax contient maintenant la vraie longueur de la chaîne
    mov [str_length], rax
    
    ; Vérifier si la chaîne est vide (après suppression du newline)
    cmp rax, 0
    jle empty_input
    
    ; ==========================================
    ; Inverser la chaîne in-place
    ; Algorithme: échanger string[i] avec string[length-1-i]
    ; ==========================================
    
    xor r8, r8                  ; r8 = index début (0)
    mov r9, rax                 ; r9 = longueur
    dec r9                      ; r9 = index fin (length - 1)
    
.reverse_loop:
    ; Vérifier si on a fini (début >= fin)
    cmp r8, r9
    jge .done
    
    ; Échanger input_buffer[r8] et input_buffer[r9]
    mov al, byte [input_buffer + r8]   ; al = caractère au début
    mov bl, byte [input_buffer + r9]   ; bl = caractère à la fin
    mov byte [input_buffer + r9], al   ; mettre al à la fin
    mov byte [input_buffer + r8], bl   ; mettre bl au début
    
    ; Avancer les pointeurs
    inc r8                      ; début++
    dec r9                      ; fin--
    jmp .reverse_loop
    
.done:
    ; ==========================================
    ; Afficher la chaîne inversée
    ; ==========================================
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    mov rsi, input_buffer       ; buffer source
    mov rdx, [str_length]       ; longueur
    syscall
    
    ; Ajouter un newline
    mov byte [input_buffer], 10
    mov rax, 1
    mov rdi, 1
    mov rsi, input_buffer
    mov rdx, 1
    syscall
    
    jmp exit_success

empty_input:
    ; Cas spécial: chaîne vide, afficher juste un newline
    mov byte [input_buffer], 10
    mov rax, 1                  ; syscall: sys_write
    mov rdi, 1                  ; fd: stdout
    mov rsi, input_buffer
    mov rdx, 1
    syscall
    jmp exit_success

; ==========================================
; Sortie du programme
; ==========================================
exit_success:
    mov rax, 60                 ; syscall: sys_exit
    xor rdi, rdi                ; exit code = 0
    syscall
