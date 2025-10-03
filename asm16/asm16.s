section .data
    old_str db '1337'
    new_str db 'H4CK'
    str_len equ $-old_str

    err_no_arg      db "Erreur: Pas d'argument",10
    err_open        db "Erreur ouverture fichier",10
    err_read        db "Erreur lecture fichier",10
    err_not_found   db "Chaîne '1337' non trouvée",10
    err_write       db "Erreur écriture fichier",10

section .bss
    filename resb 256
    buffer   resb 1024

section .text
global _start

_start:
    ; Vérification argc == 2
    mov rdi, [rsp]       ; argc
    cmp rdi, 2
    je arg_ok
    mov rdi, err_no_arg
    call print_string
    jmp exit_err

arg_ok:
    mov rsi, [rsp+16]    ; argv[1]
    mov rdi, filename
    call copy_string

    ; open(filename, O_RDWR)
    mov rax, 2
    mov rdi, filename
    mov rsi, 2           ; O_RDWR
    mov rdx, 0
    syscall
    cmp rax, 0
    jl error_open
    mov r12, rax

search_loop:
    mov rax, 0           ; sys_read
    mov rdi, r12
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0
    jle not_found
    mov r14, rax

    mov rbx, 0
check_pos:
    cmp rbx, r14
    jg not_found

    mov rcx, str_len
    mov rdi, buffer
    add rdi, rbx
    mov rsi, old_str
    call memcmp4
    cmp rax, 0
    je patch_here

    inc rbx
    jmp check_pos

patch_here:
    ; Offset fichier = offset lu + pos buffer
    mov rax, r13
    add rax, rbx

    mov rdi, r12
    mov rsi, rax
    mov rdx, 0
    mov rax, 8           ; sys_lseek
    syscall
    ; Écriture patch
    mov rax, 1           ; sys_write
    mov rdi, r12
    mov rsi, new_str
    mov rdx, str_len
    syscall
    cmp rax, str_len
    jne error_write

    ; Fermeture fichier et exit success
    mov rax, 3           ; sys_close
    mov rdi, r12
    syscall

    mov rax, 60          ; sys_exit
    xor rdi, rdi
    syscall

not_found:
    mov rdi, err_not_found
    call print_string
    jmp close_exit_err

error_open:
    mov rdi, err_open
    call print_string
    jmp exit_err

error_write:
    mov rdi, err_write
    call print_string
    jmp close_exit_err

close_exit_err:
    mov rax, 3           ; sys_close
    mov rdi, r12
    syscall

exit_err:
    mov rax, 60          ; sys_exit
    mov rdi, 1
    syscall

;----------------------------------------------------
; Routine copiestring
copy_string:
    xor rcx, rcx
.copy_loop:
    mov al, byte [rsi + rcx]
    mov byte [rdi + rcx], al
    inc rcx
    test al, al
    jnz .copy_loop
    ret

;----------------------------------------------------
; Routine memcmp4
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

;----------------------------------------------------
; Routine print_string (stdout)
print_string:
    mov rax, 1           ; sys_write
    mov rdi, 1           ; stdout
    mov rdx, 0
.find_len:
    cmp byte [rdi + rdx], 0
    je .done_len
    inc rdx
    jmp .find_len
.done_len:
    syscall
    ret
