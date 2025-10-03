section .bss
    input_buffer resb 1024      ; Buffer pour la chaîne (max 1024 octets)
    str_length  resq 1          ; Longueur réelle de la chaîne

section .text
    global _start

_start:
    ; ==========================
    ; Lire l'entrée depuis stdin
    ; ==========================
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 1024
    syscall

    ; rax = nb d'octets lus
    cmp rax, 0
    jle palindrome_yes          ; Une chaîne vide est un palindrome

    mov rcx, rax
    dec rcx                     ; rcx = index du dernier caractère
    cmp byte [input_buffer + rcx], 10
    jne .no_newline
    mov rax, rcx
.no_newline:
    mov [str_length], rax

    cmp rax, 0
    jle palindrome_yes          ; Chaîne vide, palindrome

    xor r8, r8                  ; debut = 0
    mov r9, rax                 ; fin = longueur-1
    dec r9

.loop:
    cmp r8, r9
    jge palindrome_yes          ; Si les indices se croisent, palindrome

    mov al, [input_buffer + r8]
    mov bl, [input_buffer + r9]
    cmp al, bl
    jne palindrome_no

    inc r8
    dec r9
    jmp .loop

palindrome_yes:
    mov rax, 60     ; syscall: sys_exit
    xor rdi, rdi    ; code retour 0 (OK)
    syscall

palindrome_no:
    mov rax, 60     ; syscall: sys_exit
    mov rdi, 1      ; code retour 1 (NON palindrome)
    syscall
