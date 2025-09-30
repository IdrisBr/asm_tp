section .bss
    input resb 16      ; buffer pour lecture du nombre

section .text
    global _start

_start:
    ; Lecture stdin
    mov rax, 0         ; syscall read
    mov rdi, 0         ; fd 0 = stdin
    mov rsi, input
    mov rdx, 16        ; max 16 caractères
    syscall

    ; Conversion ASCII decimal vers entier
    mov rsi, input
    xor rbx, rbx       ; rbx = résultat/nombre

read_digit:
    mov al, [rsi]
    cmp al, 10         ; saut de ligne (fin de lecture)
    je check_even
    cmp al, 0
    je check_even
    cmp al, '0'
    jb check_even
    cmp al, '9'
    ja check_even

    sub al, '0'
    imul rbx, rbx, 10
    add rbx, rax
    inc rsi
    jmp read_digit

check_even:
    test bl, 1
    jz exit_zero       ; pair
    mov rdi, 1         ; impair
    mov rax, 60
    syscall

exit_zero:
    xor rdi, rdi
    mov rax, 60
    syscall
