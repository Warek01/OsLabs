KEY_BACKSPACE     equ 0x8
KEY_LF            equ 0xa
KEY_CR            equ 0xd
KEY_SPACE         equ 0x20

INT_VID           equ 0x10
INT_KB            equ 0x16

VID_SET_MODE      equ 0x0
VID_SET_CUR_SHAPE equ 0x1
VID_SET_CUR_POS   equ 0x2
VID_PUTCHAR       equ 0xe
VID_QUERY_CUR     equ 0x3
VID_SCROLL_UP     equ 0x6
VID_SCROLL_DOWN   equ 0x7
KB_READ           equ 0x0

jmp start

; ax - number to print
print_num:
  pusha
  mov cx, 10 
  push 0

print_num_convert_loop:
  xor dx, dx
  div cx
  add dl, '0'
  push dx
  cmp ax, 0
  jnz print_num_convert_loop

print_num_print_loop:
  pop ax
  cmp al, 0 
  jz print_num_end
  mov ah, VID_PUTCHAR 
  int INT_VID
  jmp print_num_print_loop

print_num_end:
  popa
  ret


; ax - string to print
print:
  pusha
  mov si, ax
print_loop:
  lodsb ; mov byte al, [si] && inc si
  cmp al, 0
  jz print_end
  mov ah, VID_PUTCHAR
  int INT_VID
  jmp print_loop

print_end:
  popa
  ret


put_neline:
  pusha
  mov ah, VID_PUTCHAR
  mov al, KEY_LF
  int INT_VID
  mov al, KEY_CR
  int INT_VID
  popa
  ret


; al - character to print
print_ch:
  mov ah, VID_PUTCHAR
  int INT_VID
  ret
  

; output al - character code
read_key:
  mov ah, KB_READ
  int INT_KB
  ret


delete_char:
  pusha

  mov al, KEY_BACKSPACE
  call print_ch

  mov ah, 0xa
  mov al, KEY_SPACE
  mov bh, 0
  mov cx, 1
  int INT_VID

  popa
  ret


; al - video mode
set_video_mode:
  pusha
  mov ah, VID_SET_MODE
  int INT_VID
  popa
  ret
