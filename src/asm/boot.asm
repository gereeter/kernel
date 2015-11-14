; The stack
section .bss
stack_bottom:
; Right now, we only need a tiny amount of stack - this should be plenty
resb 64
stack_top:

; The actual code
global start

section .text
bits 32
start:
    ; The sanity checks ahead need some stack
    mov esp, stack_top

test_for_cpuid:
    ; We can call CPUID iff the ID-bit (bit 21) can be flipped in the FLAGS register

    ; Load FLAGS into eax - we go through the stack because apparently there isn't a better way
    pushfd
    pop eax

    ; Try flipping the ID-bit
    xor eax, 1<<21
    push eax
    popfd

    ; Load FLAGS
    pushfd
    pop ecx

    ; Test if FLAGS changed
    cmp eax, ecx
    jne no_cpuid

test_for_long_mode:
    ; Testing for long mode comes in two parts.
    ; First, we check that cpuid is powerful enough to check for long mode.

    ; When eax is 0x80000000, cpuid returns its largest allowed function. Since
    ; our next call will be with 0x80000001, any return value less than than
    ; indicates that checking for long mode isn't allowed, so clearly long mode
    ; itself won't be.
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb no_long_mode

    ; Second, we actually ask if long mode is supported.
    mov eax, 0x80000001
    cpuid
    ; The 29th bit of edx indicates long mode.
    test edx, 1<<29
    jz no_long_mode

main:
    hlt

; Error cases
no_cpuid:
    mov dword [0xb8000], 0x0c4f0c4e ; NO
    mov dword [0xb8004], 0x0c430c20 ;  C
    mov dword [0xb8008], 0x0c550c50 ; PU
    mov dword [0xb800c], 0x0c440c49 ; ID
    hlt

no_long_mode:
    mov dword [0xb8000], 0x0c4f0c4e ; NO
    mov dword [0xb8004], 0x0c4c0c20 ;  L
    mov dword [0xb8008], 0x0c4e0c4f ; ON
    mov dword [0xb800c], 0x0c200c47 ; G
    mov dword [0xb8010], 0x0c4f0c4d ; MO
    mov dword [0xb8014], 0x0c450c44 ; DE
    hlt
