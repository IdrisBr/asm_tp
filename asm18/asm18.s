section .data
    ; sockaddr_in: AF_INET, port 2005, 127.0.0.1
    sockaddr:
        dw 2                ; AF_INET
        dw 0x07d5           ; port 2005 (big endian)
        dd 0x7f000001       ; 127.0.0.1 en little endian
        dq 0                ; padding

    msg         db 'Hello, client!'
    msglen      equ $-msg

    timeoutval: dq 5, 0     ; struct timeval : 5s, 0us

    text_ok     db 'message: "',0
    text_end    db '"',10,0
    text_tout   db 'Timeout: no response from server',10,0

section .bss
    buf resb 256

section .text
global _start

_start:
    ; Création socket UDP
    mov rax, 41           ; sys_socket
    mov rdi, 2            ; AF_INET
    mov rsi, 2            ; SOCK_DGRAM
    xor rdx, rdx
    syscall
    test rax, rax
    js fail
    mov r12, rax          ; fd

    ; setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeoutval, 16)
    mov rax, 54
    mov rdi, r12
    mov rsi, 1            ; SOL_SOCKET
    mov rdx, 20           ; SO_RCVTIMEO
    mov r10, timeoutval
    mov r8, 16
    syscall

    ; sendto(fd, msg, msglen, 0, sockaddr, 16)
    mov rax, 44
    mov rdi, r12
    mov rsi, msg
    mov rdx, msglen
    xor r10, r10
    mov r8, sockaddr
    mov r9, 16
    syscall

    ; recvfrom(fd, buf, 256, 0, NULL, NULL)
    mov rax, 45
    mov rdi, r12
    mov rsi, buf
    mov rdx, 256
    xor r10, r10
    xor r8, r8
    xor r9, r9
    syscall
    test rax, rax
    js timeout
    cmp rax, 0
    jle timeout
    mov r13, rax

    ; Affichage réponse
    mov rsi, text_ok
    call print0
    mov rax, 1
    mov rdi, 1
    mov rsi, buf
    mov rdx, r13
    syscall
    mov rsi, text_end
    call print0

    mov rax, 3
    mov rdi, r12
    syscall

    mov rax, 60
    xor rdi, rdi
    syscall

timeout:
    mov rsi, text_tout
    call print0
    mov rax, 3
    mov rdi, r12
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

fail:
    mov rax, 60
    mov rdi, 1
    syscall

print0:
    mov rdx, 0
.p0l:
    cmp byte [rsi+rdx], 0
    je .p0w
    inc rdx
    jmp .p0l
.p0w:
    mov rax, 1
    mov rdi, 1
    syscall
    ret
