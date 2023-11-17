use16
org 0x7c00

MAX_BUFF_LEN equ 256
buffer equ 0x7c00 + 512

include 'lib.asm'


start:
  mov al, 3
  call set_video_mode

process_key:
  call read_key

  cmp al, KEY_CR
  jz on_enter

  cmp al, KEY_BACKSPACE
  jz on_backspace

  mov cx, word [bufflen]
  cmp cx, MAX_BUFF_LEN
  jz process_key

  call print_ch
  call add_to_buffer
  jmp process_key

on_enter:
  call put_neline
  
  mov cx, word [bufflen]
  cmp cx, 0
  jz process_key

  call print_buffer
  mov word [bufflen], 0
  jmp process_key

on_backspace:
  mov ah, VID_QUERY_CUR
  mov bh, 0
  int INT_VID

  cmp dl, 0
  jnz on_backspace_cont
  cmp dh, 0
  jz process_key
  dec dh
  mov dl, 79
  mov ah, VID_SET_CUR_POS
  int INT_VID

  mov ah, 0xa
  mov al, KEY_SPACE
  mov bh, 0
  mov cx, 1
  int INT_VID

  mov cx, word [bufflen]
  cmp cx, 0
  jg decrement_bufflen
  
  jmp process_key

decrement_bufflen:
  mov cx, word [bufflen]
  dec cx
  mov word [bufflen], cx
  jmp process_key

on_backspace_cont:
  mov cx, word [bufflen]
  cmp cx, 0
  jz process_key
  call delete_char
  dec cx
  mov word [bufflen], cx
  jmp process_key


add_to_buffer:
  pusha
  mov bx, word [bufflen]
  mov byte [buffer + bx], al
  inc bx
  mov word [bufflen], bx
  popa
  ret


print_buffer:
  pusha
  xor cx, cx

print_buffer_iteration:
  cmp cx, word [bufflen]
  jz print_buffer_end
  mov si, buffer
  add si, cx
  mov al, [si]
  call print_ch
  inc cx
  jmp print_buffer_iteration

print_buffer_end:
  call put_neline
  popa
  ret
  

bufflen dw 0


times 510 - ($ - $$) db 0
dw 0xaa55
