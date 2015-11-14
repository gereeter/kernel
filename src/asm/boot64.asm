global start64

section .text
bits 64

; Our actual boot up code, this time in 64-bits

start64:
    hlt
