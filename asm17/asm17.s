section .bss
    input resb 4096

section .data
    usage db "usage: ./asm17 [shift]",10,0

section .text
global _start

_start:
    ; Vérifier le nombre d'arguments (1 ou 2)
    mov rdi, [rsp]
    cmp rdi, 2
    je has_arg
    cmp rdi, 1
    je no_arg
    jmp usage_error

has_arg:
    mov rsi, [rsp+16]       ; argv[1]
    xor rcx, rcx
    mov rbx, 0
.next_digit:
    mov al, byte [rsi + rcx]
    test al, al
    jz .set_shift
    sub al, '0'
    cmp al, 9
    ja usage_error
    imul rbx, rbx, 10
    add rbx, rax
    inc rcx
    jmp .next_digit
.set_shift:
    mov r13, rbx
    jmp read_stdin
no_arg:
    mov r13, 0                  ; traitement spécial : pas de shift
    jmp read_stdin

usage_error:
    mov rsi, usage
    call print_str
    mov rax, 60
    mov rdi, 1
    syscall

read_stdin:
    mov rax, 0          ; sys_read
    mov rdi, 0
    mov rsi, input
    mov rdx, 4096
    syscall
    test rax, rax
    jle done            ; 0 ou erreur => quit
    mov r12, rax        ; nb de bytes lus

    mov rcx, 0
process_loop:
    cmp rcx, r12
    jge print_result

    mov al, [input+rcx]
    cmp al, 10          ; garder les newlines
    je skip_caesar
    cmp al, 'A'
    jb no_caesar
    cmp al, 'Z'
    ja check_lower
    ; Uppercase: 'A'-'Z'
    sub al, 'A'
    add al, byte r13b
    mov bl, 26
    div bl              ; al = (lettre+shift) mod 26, ah = quotient
    add al, 'A'
    mov [input+rcx], al
    jmp next_char

check_lower:
    cmp al, 'a'
    jb no_caesar
    cmp al, 'z'
    ja no_caesar
    ; Lowercase: 'a'-'z'
    sub al, 'a'
    add al, byte r13b
    mov bl, 26
    div bl
    add al, 'a'
    mov [input+rcx], al
    jmp next_char

no_caesar:
    ; Garde le caractère inchangé
    jmp next_char

skip_caesar:
    ; Laisse le saut de ligne inchangé

next_char:
    inc rcx
    jmp process_loop

print_result:
    mov rax, 1          ; sys_write
    mov rdi, 1
    mov rsi, input
    mov rdx, r12
    syscall
done:
    mov rax, 60
    xor rdi, rdi
    syscall

; rsi = chaîne zéro-terminée à afficher
print_str:
    mov rdx, 0
.find_end:
    cmp byte [rsi+rdx], 0
    je .got_len
    inc rdx
    jmp .find_end
.got_len:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
