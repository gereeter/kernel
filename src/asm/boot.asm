global start
extern start64

section .bss
alignb 4096

; Initial paging tables

p4_table: ; Page Map Level 4 Table
    resb 4096
p3_table: ; Page Directory Pointer Table
    resb 4096
p2_table: ; Page Directory Table
    resb 4096

; The stack

alignb 16

stack_bottom:
; Right now, we only need a tiny amount of stack - this should be plenty
    resb 64
stack_top:


section .rodata
alignb 8

; An initial 64 bit Global Descriptor Table

gdt:
    ; All GDTs must start with a null entry
    dq 0
.code_offset: equ $-gdt
    ; The code segment (readable + executable + is a data or code segment + present + is a 64-bit code segment)
    dq 1<<41 | 1<<43 | 1<<44 | 1<<47 | 1<<53
.data_offset: equ $-gdt
    ; The data segment (writeable + is a data or code segment + present)
    dq 1<<41 | 1<<44 | 1<<47
.pointer:
    ; To refer to the GDT, the CPU uses a ten byte pointer structure. The
    ; first two bytes give the length of the GDT in bytes, minus one, and
    ; the next eight bytes give the location of the GDT
    dw $-gdt-1
    dq gdt


section .text
bits 32

; The actual code

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

setup_paging:
    ; Set the Physical Address Extensions bit (bit 5) - we go through eax because control
    ; registers are special and can't be directly changed.
    mov eax, cr4
    or eax, 1<<5
    mov cr4, eax

    ; TODO: For simplicity, we just identity map the first 2 MiB of kernel with a single
    ; huge page. However, the internet seems unclear on how recently these huge pages were
    ; supported and, if they are not supported, how to detect that fact. This requires
    ; research.

    ; TODO: 2 MiB may not be enough in the future. More may need to be mapped.

    ; Make a P4 entry pointing at P3 (present + writeable)
    mov dword [p4_table], p3_table+3 ; | 1<<0 | 1<<1    Constant ors don't work on addresses.
    ; Make a P3 entry pointing at P2 (present + writeable)
    mov dword [p3_table], p2_table+3 ; | 1<<0 | 1<<1    Constant ors don't work on addresses.
    ; Make a P2 entry pointing at 0 (present + writeable + huge)
    mov dword [p2_table], 1<<0 | 1<<1 | 1<<7

    ; Tell the CPU about our paging tables
    mov eax, p4_table
    mov cr3, eax

enable_compatibility_mode:
    ; Set the long mode bit (bit 8) in the Extended Feature Enable Register, one of
    ; the Model Specific Registers
    mov ecx, 0xc0000080
    rdmsr
    or eax, 1<<8
    wrmsr

    ; Enable paging (bit 31)
    mov eax, cr0
    or eax, 1<<31
    mov cr0, eax

enable_long_mode:
    ; Tell the CPU where our 64 bit GDT is
    lgdt [gdt.pointer]

    ; Point all the data-like segments at our new GDT's data segment - we go through ax because,
    ; like control registers, segment registers can't be set to constants.
    mov ax, gdt.data_offset
    mov ss, ax
    mov ds, ax
    mov es, ax

    ; Do a far jump into 64-bit code
    jmp gdt.code_offset:start64

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
