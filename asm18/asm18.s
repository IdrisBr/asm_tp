section .data
    msg        db 'Hello, client!',0
    sockaddr   db 2,0,7,213,127,0,0,1,0,0,0,0,0,0,0,0 ; AF_INET, port 2005, 127.0.0.1
    msglen     equ $-msg
    sockaddrlen equ 16

    timeout_msg db 'Timeout: no response from server',10,0
    resp_msg1 db 'message: "',0
    resp_msg2 db '"',10,0

section .bss
    buf resb 128

section .text
global _start

_start:
    ; Création socket UDP
    mov rax, 41           ; sys_socket
    mov rdi, 2            ; AF_INET
    mov rsi, 2            ; SOCK_DGRAM
    mov rdx, 0
    syscall
    cmp rax, 0
    jl fail               ; Erreur
    mov r12, rax          ; fd UDP dans r12

    ; Envoi du message
    mov rax, 44           ; sys_sendto
    mov rdi, r12
    mov rsi, msg
    mov rdx, msglen
    mov r10, 0            ; flags
    mov r8, sockaddr
    mov r9, sockaddrlen
    syscall

    ; Set timeout avec sys_setsockopt
    mov rax, 54           ; sys_setsockopt
    mov rdi, r12          ; fd
    mov rsi, 1            ; SOL_SOCKET
    mov rdx, 20           ; SO_RCVTIMEO
    mov r10, timeoutval
    mov r8, 8             ; taille struct timeval
    syscall

    ; Attente/lecture réponse
    mov rax, 45           ; sys_recvfrom
    mov rdi, r12
    mov rsi, buf
    mov rdx, 128
    mov r10, 0
    mov r8, sockaddr
    mov r9, sockaddrlen
    syscall
    cmp rax, 0
    jle timeout           ; Timeout ou erreur (<0)
    mov r13, rax          ; taille reçue

    ; Affichage "message: "<MSG>"
    mov rsi, resp_msg1
    call print0
    mov rax, 1
    mov rdi, 1
    mov rsi, buf
    mov rdx, r13
    syscall
    mov rsi, resp_msg2
    call print0

    mov rax, 3            ; sys_close
    mov rdi, r12
    syscall

    mov rax, 60           ; exit 0
    xor rdi, rdi
    syscall

timeout:
    mov rsi, timeout_msg
    call print0
    mov rax, 3
    mov rdi, r12
    syscall
    mov rax, 60           ; exit 1
    mov rdi, 1
    syscall

fail:
    mov rax, 60
    mov rdi, 1
    syscall

print0:
    mov rdx, 0
.loop:
    cmp byte [rsi+rdx], 0
    je .go
    inc rdx
    jmp .loop
.go:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

section .data
timeoutval: dq 5, 0   ; struct timeval : 5s, 0us
