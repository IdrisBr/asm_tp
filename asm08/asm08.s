section .bss
    buf resb 32          ; buffer pour conversion nombre en chaîne

section .text
    global _start

_start:
    mov rax, [rsp]           ; argc
    cmp rax, 2
    jne bad_args

    mov rsi, [rsp+16]        ; argv[1] (argv[0] = nom programme)
    call atonum              ; convertir chaine -> entier

    mov rcx, rax             ; rcx = N
    xor rax, rax             ; somme = 0
    mov rbx, 1               ; compteur = 1

.sumloop:
    cmp rbx, rcx             ; tant que compteur < N
    jge .done_sum
    add rax, rbx
    inc rbx
    jmp .sumloop

.done_sum:
    mov rsi, rax             ; nombre à convertir
    mov rdi, buf             ; buffer
    call utoa
    mov rdx, rax             ; longueur chaîne ascii + \n

    ; write(stdout, buf, len)
    mov rax, 1
    mov rdi, 1
    mov rsi, buf
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

bad_args:
    mov rax, 60
    mov rdi, 1
    syscall

; ----------------------------------------------------
; atonum : Convertit chaine ASCII rsi -> entier rax
; ----------------------------------------------------
atonum:
    xor rax, rax
    xor rcx, rcx
.loop:
    mov bl, [rsi + rcx]
    cmp bl, 0
    je .done
    sub bl, '0'
    cmp bl, 9
    ja .done
    imul rax, rax, 10
    movzx rdx, bl        ; chiffre étendu
    add rax, rdx
    inc rcx
    jmp .loop
.done:
    ret

; ----------------------------------------------------
; utoa : Convertit entier rsi en ASCII dans rdi
; Retourne longueur (rax)
; ----------------------------------------------------
utoa:
    mov rax, rsi
    mov rcx, 0

.revloop:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add dl, '0'
    mov byte [rdi + rcx], dl
    inc rcx
    test rax, rax
    jnz .revloop

    mov r8, rcx
    dec rcx
    mov r9, 0

.reverse_loop:
    cmp r9, rcx
    jge .end_reverse
    mov al, [rdi + r9]
    mov bl, [rdi + rcx]
    mov byte [rdi + r9], bl
    mov byte [rdi + rcx], al
    inc r9
    dec rcx
    jmp .reverse_loop

.end_reverse:
    mov byte [rdi + r8], 10
    inc r8
    mov rax, r8
    ret
