section .data
    target_string db '1337', 0
    patch_string  db 'H4CK', 0

section .bss
    filename_buffer resb 256
    buffer resb 4096

section .text
    global _start

_start:
    ; == Vérif argument ==
    mov rcx, [rsp]
    cmp rcx, 2
    jne usage_error

    mov rdi, [rsp+16]
    mov rsi, filename_buffer
    call copy_string

    ; == Open asm01 binaire en RW ==
    mov rax, 2          ; sys_open
    mov rdi, filename_buffer
    mov rsi, 2          ; O_RDWR
    mov rdx, 0
    syscall
    cmp rax, 0
    jl file_error
    mov rbx, rax

    ; == Read bloc ==
    mov rax, 0          ; sys_read
    mov rdi, rbx        ; fd
    mov rsi, buffer
    mov rdx, 4096
    syscall
    cmp rax, 1
    jl file_error
    mov r8, rax         ; r8 = nb octets lus

    ; == Recherche "1337" dans buffer ==
    xor rcx, rcx                ; index = 0
.find_loop:
    cmp rcx, r8                 ; fin de buffer ?
    jge not_found
    ; Compare 4 bytes
    mov rsi, buffer
    add rsi, rcx
    mov eax, dword [rsi]
    cmp eax, 0x37333331         ; '1337' en little endian
    jne .next
    ; trouvé!
    mov rdx, rbx                ; fd
    mov rax, 1                  ; sys_write
    mov rdi, rdx
    mov rsi, patch_string
    mov rdx, 4                  ; longueur
    ; Positionnement du curseur à l’offset
    mov rax, 8                  ; sys_lseek
    mov rdi, rbx
    mov rsi, rcx
    mov rdx, 0                  ; SEEK_SET
    syscall
    ; Ecriture patch
    mov rax, 1                  ; sys_write
    mov rdi, rbx
    mov rsi, patch_string
    mov rdx, 4
    syscall
    jmp patch_done
.next:
    inc rcx
    jmp .find_loop

not_found:
    ; Rien n'a été patché
    mov rax, 3          ; sys_close
    mov rdi, rbx
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

patch_done:
    mov rax, 3          ; sys_close
    mov rdi, rbx
    syscall
    mov rax, 60
    xor rdi, rdi        ; succès
    syscall

file_error:
usage_error:
    mov rax, 60
    mov rdi, 1
    syscall

; Copie argv vers buffer null-terminated
copy_string:
    xor rcx, rcx
.copy:
    mov al, byte [rdi+rcx]
    mov [rsi+rcx], al
    inc rcx
    test al, al
    jnz .copy
    ret
