%define KEY_BACKSPACE 0x8
%define KEY_LF        0xa
%define KEY_CR        0xd
%define KEY_SPACE     0x20

%define INT_VID 0x10
%define INT_DSK 0x13
%define INT_KB  0x16

%define VID_SET_MODE      0x0
%define VID_SET_CUR_SHAPE 0x1
%define VID_SET_CUR_POS   0x2
%define VID_PUTCHAR       0xe
%define VID_QUERY_CUR     0x3
%define VID_SCROLL_UP     0x6
%define VID_SCROLL_DOWN   0x7
%define KB_READ           0x0
%define DSK_RESET         0x0
%define DSK_GETERR        0x1
%define DSK_READ          0x2
%define DSK_WRITE         0x3

%define OP_KEYBOARD_FLOPPY '1'
%define OP_FLOPPY_RAM      '2'
%define OP_RAM_FLOPPY      '3'

%define MAX_BUFFLEN 0xff

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


; si - string to print
print:
  pusha

.loop:
  lodsb ; mov byte al, [si] && inc si
  cmp al, 0
  jz .end
  mov ah, VID_PUTCHAR
  int INT_VID
  jmp .loop

.end:
  popa
  ret


; si - string to print
println:
  call print
  call put_neline
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
printch:
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
  call printch

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


; si - string to read, returns ax - the number
atoi:
  push cx
  push bx
  mov ax, 0x0
  mov bx, 0xa

.loop:
  xor cx, cx
  mov cl, byte [si]
  inc si
  cmp cx, 0x0
  jz .end
  sub cx, '0'
  mul bx
  add ax, cx
  jmp .loop

.end:
  pop bx
  pop cx
  ret


clear_screen:
  pusha
  call reset_cursor
  mov cx, 0
  mov al, KEY_SPACE

.loop:
  cmp cx, 80 * 25
  jz .end
  inc cx
  call printch
  jmp .loop
.end:
  call reset_cursor
  popa
  ret


reset_cursor:
  pusha
  mov ah, VID_SET_CUR_POS
  mov bh, 0x0
  mov dh, 0x0
  mov dl, 0x0
  int INT_VID
  popa
  ret


; si - string, cl - characters count
print_count:
  xor ch, ch
  
.iteration:
  cmp ch, cl
  jz .end
  lodsb
  call printch
  inc ch
  jmp .iteration

.end:
  ret
