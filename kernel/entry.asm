[BITS 64]
[global _start]
[global kernel_stack_top]
[extern kmain]

section .bss
align 16

kernel_stack_bottom:
  resb 16384

kernel_stack_top:

section .text

_start:
  ; gdt segments
  mov ax, 0x10
  mov ss, ax
  mov ds, ax
  mov es, ax

  ; set fs and gs to 0 because they are not used in 64 bits mode
  xor ax, ax
  mov fs, ax
  mov gs, ax

  mov rsp, kernel_stack_top
  ; align to 16 bytes (ABI System V x86_64)
  and rsp, ~0xf

  ; start of the stack
  xor rbp, rbp

  call kmain

  cli

.halt:
  hlt
  jmp .halt
