section .data
    text_to_write db "Hello Universe!",10   ; Texte à écrire (avec newline)
    text_len     equ $-text_to_write

section .bss
    filename_buffer resb 128                ; Buffer pour nom de fichier

section .text
    global _start

_start:
    ; ============== Gestion des arguments ===============
    mov rcx, [rsp]          ; rcx = argc
    cmp rcx, 2
    jne usage_error         ; Doit avoir 1 argument

    mov rdi, [rsp+16]       ; argv[1] : pointeur vers nom de fichier
    mov rsi, filename_buffer
    call copy_string        ; Copie argv[1] dans filename_buffer

    ; ============= Open/Create le fichier ============
    mov rax, 2              ; syscall: sys_open
    mov rdi, filename_buffer ; nom du fichier
    mov rsi, 577            ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0644           ; droits rw-r--r-- (octal)
    syscall
    cmp rax, 0
    jl file_error           ; Erreur d'ouverture
    mov rbx, rax            ; rbx = fd

    ; ============= Écriture dans le fichier ==========
    mov rax, 1              ; syscall: sys_write
    mov rdi, rbx            ; fd du fichier
    mov rsi, text_to_write  ; adresse de la chaîne
    mov rdx, text_len       ; longueur
    syscall
    cmp rax, text_len
    jne file_error          ; Si on n'a pas écrit tout le texte, erreur

    ; ============= Fermeture du fichier ==========
    mov rax, 3              ; syscall: sys_close
    mov rdi, rbx            ; fd
    syscall

    ; ============= Succès ==========
    jmp exit_success

usage_error:
file_error:
    mov rax, 60             ; exit 1
    mov rdi, 1
    syscall

exit_success:
    mov rax, 60             ; exit 0
    xor rdi, rdi
    syscall

; ============= Fonction copie de chaîne (argv) ==========
; Entrée : rdi = source (argv[1]), rsi = dest
copy_string:
    xor rcx, rcx
.copy:
    mov al, byte [rdi + rcx]
    mov [rsi + rcx], al
    inc rcx
    test al, al
    jnz .copy
    ret
