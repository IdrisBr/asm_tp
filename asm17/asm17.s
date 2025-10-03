section .bss
    input resb 4096

section .data
    usage db "usage: ./asm17 <shift>",10,0

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2
    jne usage_error

    ; Parsing shift param
    mov rsi, [rsp+16]
    xor rbx, rbx
    xor rcx, rcx
.parse_shift:
    mov al, [rsi + rcx]
    test al, al
    jz .done_parse
    cmp al, '0'
    jb usage_error
    cmp al, '9'
    ja usage_error
    imul rbx, rbx, 10
    sub al, '0'
    add rbx, rax
    inc rcx
    jmp .parse_shift
.done_parse:
    mov r13b, bl     ; r13b = shift dans 0-255

    ; lecture stdin
    mov rax, 0
    mov rdi, 0
    mov rsi, input
    mov rdx, 4096
    syscall
    mov r12, rax         ; longueur lue

    xor rcx, rcx
.loop:
    cmp rcx, r12
    jge .done
    mov al, [input + rcx]

    ; test lowercase
    cmp al, 'a'
    jb .majuscule
    cmp al, 'z'
    ja .autre
    sub al, 'a'
    add al, r13b
    mov ah, 0
    cmp al, 26
    jl .pas_mod
    sub al, 26
.pas_mod:
    add al, 'a'
    mov [input + rcx], al
    inc rcx
    jmp .loop

.majuscule:
    cmp al, 'A'
    jb .autre
    cmp al, 'Z'
    ja .autre
    sub al, 'A'
    add al, r13b
    mov ah, 0
    cmp al, 26
    jl .pas_mod2
    sub al, 26
.pas_mod2:
    add al, 'A'
    mov [input + rcx], al
    inc rcx
    jmp .loop

.autre:
    ; caractère inchangé
    mov [input + rcx], al
    inc rcx
    jmp .loop

.done:
    mov rax, 1
    mov rdi, 1
    mov rsi, input
    mov rdx, r12
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

usage_error:
    mov rsi, usage
    call print0
    mov rax, 60
    mov rdi, 1
    syscall

print0:
    mov rdx, 0
.nextchar:
    cmp byte [rsi + rdx], 0
    je .pr
    inc rdx
    jmp .nextchar
.pr:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
