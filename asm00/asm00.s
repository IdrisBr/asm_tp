section .text
    global _start

_start:
    mov rax, 60     ; syscall exit
    xor rdi, rdi    ; code retour 0
    syscall
