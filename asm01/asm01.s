section .data
    msg db "1337", 10 ; texte suivi d’un newline (\n)
    len equ $ - msg

section .text
    global _start

_start:
    mov rax, 1        ; syscall: write
    mov rdi, 1        ; stdout
    mov rsi, msg      ; message
    mov rdx, len      ; longueur
    syscall

    mov rax, 60       ; syscall: exit
    xor rdi, rdi      ; code 0
    syscall
