section .bss
    input resb 3         ; 2 caractères + \n

section .data
    outmsg db "1337", 10
    outlen equ $ - outmsg

section .text
    global _start

_start:
    ; lire sur stdin
    mov rax, 0           ; syscall read
    mov rdi, 0           ; fd = stdin
    mov rsi, input       ; buffer
    mov rdx, 3           ; max 3 octets
    syscall

    ; vérifier "42"
    mov al, [input]
    cmp al, '4'
    jne wrong
    mov al, [input+1]
    cmp al, '2'
    jne wrong

    ; si "42", afficher
    mov rax, 1
    mov rdi, 1
    mov rsi, outmsg
    mov rdx, outlen
    syscall

    mov rax, 60
    xor rdi, rdi         ; exit 0
    syscall

wrong:
    mov rax, 60
    mov rdi, 1           ; exit 1
    syscall
