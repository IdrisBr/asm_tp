section .text
    global _start

_start:
    mov rax, [rsp]
    cmp qword [rsp], 2      ; argc >= 2 ?
    jb no_param             ; si pas de param, exit 1

    mov rsi, [rsp+16]       ; argv[1]
    mov rdi, 1              ; STDOUT
    call print_str

    jmp exit_ok

no_param:
    mov rax, 60
    mov rdi, 1              ; exit code 1 si pas de param
    syscall

exit_ok:
    mov rax, 60
    xor rdi, rdi            ; exit code 0
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
    syscall
    ret
