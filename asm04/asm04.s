section .bss
    input resb 16

section .text
    global _start

_start:
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 16
    syscall

    mov rsi, input
    xor rbx, rbx

read_digit:
    mov al, [rsi]
    cmp al, 10
    je test_even
    cmp al, 0
    je test_even
    cmp al, '0'
    jb bad_input
    cmp al, '9'
    ja bad_input

    sub al, '0'
    imul rbx, rbx, 10
    add rbx, rax
    inc rsi
    jmp read_digit

test_even:
    test bl, 1
    jz exit_zero
    mov rdi, 1
    mov rax, 60
    syscall

exit_zero:
    xor rdi, rdi
    mov rax, 60
    syscall

bad_input:
    mov rax, 60
    mov rdi, 2
    syscall
