bits 16
org 0x0000


section .text:
start:
  mov ah, 0x0
  mov al, 0x3
  int 0x10

  mov ah, 0xe
  mov al, 'A'
  int 0x10

  cli
  hlt

section .data

section .bss
buffer resb 256
bufflen resw 1
  