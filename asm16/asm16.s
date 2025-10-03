section .data
    search_bytes db '1337'
    patch_bytes  db 'H4CK'

section .bss
    filename_buffer resb 256
    file_buffer resb 4096

section .text
    global _start

_start:
    mov rcx, [rsp]
    cmp rcx, 2
    jne usage_error

    mov rdi, [rsp+16]
    mov rsi, filename_buffer
    call copy_string

    ; Ouvrir fichier en lecture/écriture
    mov rax, 2              ; sys_open
    mov rdi, filename_buffer
    mov rsi, 2              ; O_RDWR
    mov rdx, 0
    syscall
    cmp rax, 0
    jl file_error
    mov rbx, rax            ; fd

    ; Lire contenu fichier
    mov rax, 0              ; sys_read
    mov rdi, rbx
    mov rsi, file_buffer
    mov rdx, 4096
    syscall
    cmp rax, 1
    jl file_error
    mov r8, rax             ; taille lue

    xor rcx, rcx            ; index début boucle
.find_loop:
    cmp rcx, r8
    jg not_found

    mov rsi, file_buffer
    add rsi, rcx

    mov eax, dword [rsi]
    cmp eax, 0x37333331     ; '1337' en little endian
    jne .next

    ; Positionner curseur à rcx pour écriture
    mov rax, 8              ; sys_lseek
    mov rdi, rbx
    mov rsi, rcx
    mov rdx, 0              ; SEEK_SET
    syscall

    ; Ecrire patch
    mov rax, 1              ; sys_write
    mov rdi, rbx
    mov rsi, patch_bytes
    mov rdx, 4
    syscall
    jmp patch_done

.next:
    inc rcx
    jmp .find_loop

not_found:
    mov rax, 3              ; sys_close
    mov rdi, rbx
    syscall
    mov rax, 60
    mov rdi, 1              ; exit code 1 (pas trouvé)
    syscall

patch_done:
    mov rax, 3              ; sys_close
    mov rdi, rbx
    syscall
    mov rax, 60
    xor rdi, rdi            ; exit code 0 succès
    syscall

usage_error:
file_error:
    mov rax, 60
    mov rdi, 1
    syscall

; Copie une chaîne depuis argv vers buffer (null-terminated)
copy_string:
    xor rcx, rcx
.copy:
    mov al, byte [rdi + rcx]
    mov [rsi + rcx], al
    inc rcx
    test al, al
    jnz .copy
    ret
