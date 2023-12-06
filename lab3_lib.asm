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
; read_address - prints "Segment:Address? ____:____" prompt, must be completed to return
; Args - none
; Rets - segment - value of the segment input
;		 address - value of the address input
read_address: 
  mov si, address_help
  call println
	mov si, address_space
  call print
  mov ax, 0x0e0d
  int 0x10
    mov di, segment_buffer
read_address_input:
    
    mov ah, 0x00
    int 0x16

    cmp ah, 0x0e
    je read_address_input_bksp

    cmp ah, 0x1c
    je read_address_input_enter

    cmp ah, 0x01
    je read_address_input_esc

    cmp al, 0x20
    jae read_address_input_default

    jmp read_address_input

read_address_input_bksp:
    cmp di, segment_buffer
    je read_address_input
    mov ah, 0x03
    int 0x10
    dec dl
    cmp di, address_buffer
    jne read_address_input_bksp1
    dec dl
read_address_input_bksp1:
    mov ah, 0x02
    int 0x10
    mov ah, 0x0a
    mov al, '_'
    mov bh, 0
    mov cx, 1
    int 0x10
    mov [di], byte 0
    dec di
    jmp read_address_input

read_address_input_enter:
    cmp di, address_buffer+4
    jne read_address_input

read_address_process_input:
    mov di, segment_buffer
    mov si, segment_word
read_address_process_cond:
    cmp di, segment_buffer+8
    je read_address_process_input_for_end
    mov al, [di+2]
    shl al, 4
    or al, [di+3]
    mov ah, [di]
    shl ah, 4
    or ah, [di+1]
    mov word [si], ax
    call print_num
    call put_neline

    add di, 4
    add si, 2
    mov ah, 0
    int 0x16
    jmp read_address_process_cond
read_address_process_input_for_end:
	ret

read_address_input_esc:
    ret

read_address_input_default:
    cmp di, address_buffer+4
    je read_address_input
read_address_input_default_check_digit:
    cmp al, '0'-1
    jbe read_address_input_default_check_letter
    cmp al, '9'
    mov bl, '0'
    jbe read_address_input_default_check_positive
read_address_input_default_check_letter:
    cmp al, 'a'-1
    jbe read_address_input_default_check_negative
    cmp al, 'f'
    ja read_address_input_default_check_negative
    mov bl, 'a'-10
read_address_input_default_check_positive:
    mov ah, 0x0e
    int 0x10
    sub al, bl
    stosb
    cmp di, address_buffer
    jne read_address_input
read_address_input_default_move_cursor:
    mov ah, 0x03
    mov bh, 0
    int 0x10
    inc dl
    mov ah, 0x02
    int 0x10
read_address_input_default_check_negative:
    jmp read_address_input

