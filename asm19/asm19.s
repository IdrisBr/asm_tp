section .data
    sock_addr:
        dw 2                ; AF_INET
        dw 0x0539           ; port 1337 (1337 = 0x0539, big endian)
        dd 0                ; INADDR_ANY
        dq 0                ; padding

    msg_listen db "Listening on port 1337",10,0
    filename   db "messages",0

section .bss
    buf resb 256

section .text
global _start

_start:
    ; Affichage indication écoute
    mov rsi, msg_listen
    call print_str

    ; socket(AF_INET, SOCK_DGRAM, 0)
    mov rax, 41
    mov rdi, 2
    mov rsi, 2
    xor rdx, rdx
    syscall
    test rax, rax
    js exit1
    mov r12, rax        ; fd UDP

    ; bind(fd, &sock_addr, 16)
    mov rax, 49
    mov rdi, r12
    mov rsi, sock_addr
    mov rdx, 16
    syscall
    test rax, rax
    js clean_exit

open_file:
    ; O_CREAT | O_WRONLY | O_APPEND = 0x241
    mov rax, 2
    mov rdi, filename
    mov rsi, 0x241
    mov rdx, 0644
    syscall
    test rax, rax
    js clean_exit
    mov r13, rax         ; fd fichier

mainloop:
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
    js clean_exit_file   ; sortie si erreur

    mov r14, rax         ; nb octets lus si >0

    ; write(fichier, buf, r14)
    mov rax, 1
    mov rdi, r13
    mov rsi, buf
    mov rdx, r14
    syscall

    ; write(fichier, "\n", 1)    ; ajout retour chariot
    mov rax, 1
    mov rdi, r13
    mov rsi, nlchar
    mov rdx, 1
    syscall

    jmp mainloop         ; boucle infinie
    ; (Ctrl+C pour quitter, fichier append)

clean_exit_file:
    mov rax, 3
    mov rdi, r13
    syscall

clean_exit:
    mov rax, 3
    mov rdi, r12
    syscall
exit1:
    mov rax, 60
    mov rdi, 1
    syscall

print_str:
    mov rdx, 0
.p_loop:
    cmp byte [rsi+rdx], 0
    je .go
    inc rdx
    jmp .p_loop
.go:
    mov rax, 1
    mov rdi, 1
    syscall
    ret

section .data
nlchar db 10
