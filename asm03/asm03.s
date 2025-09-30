section .data
    msg db "1337", 10
    mslen equ $-msg

section .text
    global _start

_start:
    mov rax, [rsp]          ; argc (nombre d’arguments)
    cmp qword [rsp], 2      ; argc = 2 ? (programme + 1 paramètre)
    jne fail

    mov rsi, [rsp+16]       ; adresse du 1er argument (car [rsp+8] = nom programme)
    mov al, byte [rsi]
    cmp al, '4'
    jne fail
    mov al, byte [rsi+1]
    cmp al, '2'
    jne fail
    mov al, byte [rsi+2]
    cmp al, 0               ; fin de chaîne C
    jne fail

    mov rax, 1
    mov rdi, 1
    mov rsi, msg
    mov rdx, mslen
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

fail:
    mov rax, 60
    mov rdi, 1
    syscall
