section .data
    old_str db '1337'
    new_str db 'H4CK'
    str_len equ $-old_str

section .bss
    filename resb 256       ; buffer pour le nom du fichier
    buffer   resb 1024      ; tampon lecture

section .text
global _start
_start:
    ; Vérification nombre d'arguments (argc==2)
    mov rdi, [rsp]          ; argc
    cmp rdi, 2
    jne usage_error

    ; Copie argv[1] dans filename (adresse argv[1] dans rsi)
    mov rsi, [rsp+16]       ; argv[1]
    mov rdi, filename
    call copy_string

    ; Ouverture fichier (O_RDWR)
    mov rax, 2              ; sys_open
    mov rdi, filename
    mov rsi, 2              ; O_RDWR
    mov rdx, 0
    syscall
    cmp rax, 0
    js file_error
    mov r12, rax            ; sauvegarde fd dans r12

    ; Recherche de la chaîne "1337" dans le fichier
    mov r13, 0              ; offset fichier courant
search_loop:
    ; Lecture 1024 octets dans buffer
    mov rax, 0              ; sys_read
    mov rdi, r12            ; fd
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle not_found           ; fin fichier ou erreur

    mov r14, rax            ; taille lue
    mov rbx, 0              ; index dans tampon
check_pos:
    cmp rbx, r14
    jg not_found

    ; Comparaison 4 octets à partir de buffer[rbx] avec old_str
    mov rcx, str_len
    mov rdi, buffer
    add rdi, rbx            ; adresse buffer+rbx
    mov rsi, old_str

    call memcmp4
    cmp rax, 0
    je patch_here

    inc rbx
    jmp check_pos

patch_here:
    ; Somme offset absolu = r13 + rbx
    mov rax, r13
    add rax, rbx

    ; Seek dans fichier à cette position
    mov rdi, r12            ; fd
    mov rsi, rax            ; offset absolu
    mov rdx, 0              ; SEEK_SET
    mov rax, 8              ; sys_lseek
    syscall

    ; Écriture de "H4CK" à cette position
    mov rax, 1              ; sys_write
    mov rdi, r12
    mov rsi, new_str
    mov rdx, str_len
    syscall
    cmp rax, str_len
    jne file_error

    ; Fermeture fichier
    mov rax, 3              ; sys_close
    mov rdi, r12
    syscall

    ; Succès
    mov rax, 60             ; sys_exit
    xor rdi, rdi
    syscall

not_found:
    ; Fermeture fichier avant erreur
    mov rax, 3
    mov rdi, r12
    syscall

file_error:
usage_error:
    mov rax, 60
    mov rdi, 1
    syscall

;--------------------
; copy_string: copie chaine C (0 terminated) de rsi à rdi
copy_string:
    xor rcx, rcx
.copy_loop:
    mov al, byte [rsi + rcx]
    mov byte [rdi + rcx], al
    inc rcx
    test al, al
    jnz .copy_loop
    ret

;--------------------
; memcmp4: compare 4 octets entre [rdi] et [rsi]
; renvoie 0 si égal, sinon ≠0 dans rax
memcmp4:
    mov al, [rdi]
    cmp al, [rsi]
    jne .diff
    mov al, [rdi+1]
    cmp al, [rsi+1]
    jne .diff
    mov al, [rdi+2]
    cmp al, [rsi+2]
    jne .diff
    mov al, [rdi+3]
    cmp al, [rsi+3]
    jne .diff
    mov rax, 0
    ret
.diff:
    mov rax, 1
    ret
