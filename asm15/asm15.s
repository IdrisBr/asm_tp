section .bss
    filename_buffer resb 256
    elf_header resb 8           ; Pour stocker les 8 premiers octets lus

section .text
    global _start

_start:
    ; == Vérification argument ==
    mov rcx, [rsp]                  ; argc
    cmp rcx, 2
    jne usage_error                 ; Doit avoir un seul argument

    mov rdi, [rsp+16]               ; argv[1]
    mov rsi, filename_buffer
    call copy_string

    ; == open fichier ==
    mov rax, 2                      ; sys_open
    mov rdi, filename_buffer
    mov rsi, 0                      ; O_RDONLY
    mov rdx, 0                      ; mode inutile
    syscall
    cmp rax, 0
    jl file_error                   ; fail open
    mov rbx, rax                    ; rbx = fd

    ; == read octets ==
    mov rax, 0                      ; sys_read
    mov rdi, rbx                    ; fd
    mov rsi, elf_header             ; buffer
    mov rdx, 8                      ; lire 8 octets
    syscall
    cmp rax, 8
    jne not_elf                     ; pas assez d'octets

    ; == Vérifier magic ELF 64 ==
    mov al, [elf_header]            ; 0x7f
    cmp al, 0x7f
    jne not_elf

    mov al, [elf_header+1]
    cmp al, 'E'
    jne not_elf

    mov al, [elf_header+2]
    cmp al, 'L'
    jne not_elf

    mov al, [elf_header+3]
    cmp al, 'F'
    jne not_elf

    mov al, [elf_header+4]
    cmp al, 2                       ; Class: 2 (ELF64)
    jne not_elf

    mov al, [elf_header+5]
    cmp al, 1                       ; Data: 1 (Little endian, classique x86_64)
    jne not_elf

    ; == Fermeture fichier ==
    mov rax, 3
    mov rdi, rbx
    syscall

    ; == Détection positive ELF x64 ==
    mov rax, 60                     ; sys_exit
    xor rdi, rdi                    ; 0 (ELF x64 found)
    syscall

not_elf:
    mov rax, 3                      ; fermeture fichier
    mov rdi, rbx
    syscall

    mov rax, 60                     ; sys_exit
    mov rdi, 1                      ; 1 (not ELF x64)
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
