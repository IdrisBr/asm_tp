section .bss
    input resb 3         ; 2 caractères + \n

section .data
    outmsg db "1337", 10
    outlen equ $ - outmsg

section .text
    global _start

_start:
    ; lire stdin
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 3
    syscall

    ; vérifier chaque caractère
    mov al, [input]
    cmp al, '4'
    jne fail
    mov al, [input+1]
    cmp al, '2'
    jne fail
    mov al, [input+2]
    cmp al, 10          ; saut de ligne attendu
    jne fail

    ; afficher "1337"
    mov rax, 1
    mov rdi, 1
    mov rsi, outmsg
    mov rdx, outlen
    syscall

    ; exit 0
    mov rax, 60
    xor rdi, rdi
    syscall

fail:
    mov rax, 60
    mov rdi, 1          ; exit 1
    syscall
