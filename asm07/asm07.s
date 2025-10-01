section .bss
    input_buffer resb 32        ; Buffer pour lire l'entrée utilisateur (max 32 octets)

section .text
    global _start

_start:
    ; ==========================================
    ; Lecture de l'entrée utilisateur depuis stdin
    ; ==========================================
    mov rax, 0                  ; syscall: sys_read (0)
    mov rdi, 0                  ; fd: stdin (0)
    mov rsi, input_buffer       ; buffer de destination
    mov rdx, 32                 ; nombre max d'octets à lire
    syscall
    
    ; Vérifier si la lecture a échoué ou si rien n'a été lu
    cmp rax, 0
    jle read_error              ; Si rax <= 0, erreur de lecture

    ; ==========================================
    ; Conversion ASCII -> Integer (atoi custom)
    ; ==========================================
    xor rax, rax                ; rax = 0 (accumulateur pour le nombre)
    xor rcx, rcx                ; rcx = 0 (index dans le buffer)
    mov rsi, input_buffer       ; pointeur vers le buffer

.parse_loop:
    movzx rbx, byte [rsi + rcx] ; Charger un caractère du buffer
    
    ; Vérifier si c'est un newline (0x0A) ou null terminator (0x00)
    cmp bl, 0x0A
    je .parse_done
    cmp bl, 0x00
    je .parse_done
    
    ; Vérifier si c'est un chiffre ASCII ('0' = 0x30 à '9' = 0x39)
    cmp bl, '0'
    jb .parse_done              ; Si < '0', fin de parsing
    cmp bl, '9'
    ja .parse_done              ; Si > '9', fin de parsing
    
    ; Conversion ASCII -> numérique
    sub bl, '0'                 ; bl = bl - 48 (conversion ASCII -> int)
    
    ; rax = rax * 10 + bl
    imul rax, rax, 10           ; rax = rax * 10
    movzx rbx, bl               ; Étendre bl à rbx (64 bits)
    add rax, rbx                ; rax = rax + chiffre
    
    inc rcx                     ; Incrémenter l'index
    jmp .parse_loop

.parse_done:
    mov rdi, rax                ; rdi = le nombre parsé (sera notre candidat)

    ; ==========================================
    ; Vérification des cas spéciaux
    ; ==========================================
    
    ; Cas 1: Si n < 2, ce n'est PAS un nombre premier
    cmp rdi, 2
    jb not_prime                ; Si n < 2, pas premier
    
    ; Cas 2: Si n == 2, c'est premier
    cmp rdi, 2
    je is_prime
    
    ; Cas 3: Si n est pair (et n > 2), pas premier
    test rdi, 1                 ; Tester le bit de poids faible
    jz not_prime                ; Si bit = 0 (nombre pair), pas premier

    ; ==========================================
    ; Test de primalité par division d'essai
    ; Optimisation: on teste seulement jusqu'à √n
    ; et uniquement les diviseurs impairs
    ; ==========================================
    
    mov rbx, 3                  ; rbx = diviseur initial (on commence à 3)

.prime_check_loop:
    ; Vérifier si diviseur² > n (condition d'arrêt optimisée)
    mov rax, rbx
    imul rax, rbx               ; rax = diviseur²
    cmp rax, rdi
    ja is_prime                 ; Si diviseur² > n, c'est premier!

    ; Tester si n est divisible par le diviseur actuel
    mov rax, rdi                ; rax = n
    xor rdx, rdx                ; rdx = 0 (pour la division)
    div rbx                     ; rax = n / diviseur, rdx = n % diviseur
    
    ; Si le reste est 0, n est divisible → pas premier
    cmp rdx, 0
    je not_prime

    ; Passer au diviseur impair suivant (diviseur += 2)
    add rbx, 2
    jmp .prime_check_loop

; ==========================================
; Sorties du programme
; ==========================================

is_prime:
    ; Exit code 0 = nombre premier
    mov rax, 60                 ; syscall: sys_exit (60)
    xor rdi, rdi                ; exit code = 0
    syscall

not_prime:
    ; Exit code 1 = nombre NON premier
    mov rax, 60                 ; syscall: sys_exit (60)
    mov rdi, 1                  ; exit code = 1
    syscall

read_error:
    ; Exit code 2 = erreur de lecture
    mov rax, 60                 ; syscall: sys_exit (60)
    mov rdi, 2                  ; exit code = 2
    syscall
