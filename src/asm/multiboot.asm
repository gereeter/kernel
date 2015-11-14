; A Multiboot Standard 1 header

%define align 1<<0
%define magic 0x1BADB002
%define flags align
%define checksum -(magic + flags)

section .multiboot
    alignb 4
    dd magic
    dd flags
    dd checksum
