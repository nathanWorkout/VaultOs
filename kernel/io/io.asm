global outb
global inb

section .text

; convention System V ABI : di as the 1 arg and si as the 2 arg (but sil for 8 bits)

outb:
    mov dx, di ; port num
    mov al, sil ; val
    out dx, al
    ret

inb:
    mov dx, di ; port num
    in al, dx
    ret
