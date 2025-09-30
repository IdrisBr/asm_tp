section .text
    global _start

_start:
    mov rax, [rsp]          ; argc
    cmp qword [rsp], 2      ; au moins 1 arg ?
    jb exit_ok

    mov rsi, [rsp+16]       ; argv[1]
    mov rdi, 1              ; stdout
    call print_str

exit_ok:
    mov rax, 60
    xor rdi, rdi
    syscall

print_str:
    mov rdx, 0
.loop:
    mov al, [rsi+rdx]
    cmp al, 0
    je .write
    inc rdx
    jmp .loop
.write:
    mov rax, 1
    mov rdi, 1
    ; respecte que rsi ne soit pas modifié
    syscall
    ret
