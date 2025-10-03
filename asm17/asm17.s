section .bss
    input resb 4096

section .data
    usage db "usage: ./asm17 <shift>",10,0

section .text
global _start

_start:
    mov rax, [rsp]
    cmp rax, 2                ; require shift param
    jne usage_error

    mov rsi, [rsp+16]         ; argv[1]
    xor rbx, rbx
    xor rcx, rcx
.parse_shift:
    mov al, [rsi+rcx]
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
    mov r13, rbx              ; shift

    mov rax, 0                ; sys_read
    mov rdi, 0                ; stdin
    mov rsi, input
    mov rdx, 4096
    syscall
    mov r12, rax              ; length
    test rax, rax
    jle output_empty

    xor rcx, rcx
.next_char:
    cmp rcx, r12
    jge output_done

    mov al, [input+rcx]
    mov bl, al                ; backup original
    ; Lowercase test
    cmp al, 'a'
    jb .check_upper
    cmp al, 'z'
    ja .copy_char
    sub al, 'a'
    add al, r13b
    mov ah, 0
    mov bl, 26
    div bl                    ; rax = (val+shift)/26, al = new char pos
    add al, 'a'
    mov [input+rcx], al
    jmp .next_pos

.check_upper:
    cmp bl, 'A'
    jb .copy_char
    cmp bl, 'Z'
    ja .copy_char
    mov al, bl
    sub al, 'A'
    add al, r13b
    mov ah, 0
    mov bl, 26
    div bl
    add al, 'A'
    mov [input+rcx], al
    jmp .next_pos

.copy_char:
    mov [input+rcx], bl

.next_pos:
    inc rcx
    jmp .next_char

output_done:
    mov rax, 1                ; sys_write
    mov rdi, 1
    mov rsi, input
    mov rdx, r12
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

output_empty:
    mov rax, 1
    mov rdi, 1
    mov rsi, input
    mov rdx, 0
    syscall
    mov rax, 60
    xor rdi, rdi
    syscall

usage_error:
    mov rsi, usage
    call print_str0
    mov rax, 60
    mov rdi, 1
    syscall

print_str0:
    mov rdx, 0
.find_end:
    cmp byte [rsi+rdx], 0
    je .done_len
    inc rdx
    jmp .find_end
.done_len:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
