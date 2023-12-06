bits 16
org 0x7e00

%include 'lab3_lib.asm'

section .text:
start:
  mov al, 0x3
  call set_video_mode

  mov word [bufflen], 0x0

.main_loop:
  call clear_vars
  mov si, select_operation_message
  call print
  
  call read_key
  call printch
  call put_neline

  ; check that character is in needed bounds (1-3)
  cmp al, OP_KEYBOARD_FLOPPY
  jl .main_loop
  cmp al, OP_RAM_FLOPPY
  jg .wrong_op

  cmp al, OP_KEYBOARD_FLOPPY
  jz .keyboard_floppy
  cmp al, OP_FLOPPY_RAM
  jz .floppy_ram
  cmp al, OP_RAM_FLOPPY
  jz .ram_floppy
  
  jmp .wrong_op ; in case something goes wrong

.program_end:
  cli
  hlt

.wrong_op:
  call clear_screen
  mov si, wrong_op_message
  call println
  jmp .main_loop

.on_enter:
  call put_neline
  call print_buffer
  mov word [bufflen], 0x0
  jmp .main_loop

.on_backspace:
  jmp .main_loop

.keyboard_floppy: ; handle keyboard to floppy
  mov si, keyboard_floppy_message
  call println
  call read_n
  call read_head
  call read_track
  call read_sector

  mov si, input_string_message
  call println

  call read_buffer
  call put_neline

  ; Now we have N, {Head, Track, Sector} and String to write
  call reset_floppy

  push    ax

  mov     ax, 0x0
	mov     es, ax
  mov     bx, buffer

  pop     ax

  mov     ah, 0x3
  mov     al, [n]
  mov     ch, [track]
  mov     cl, [sector]
  mov     dh, [head]
  mov     dl, 0x0

  int     INT_DSK
  mov     al, ah
  xor     ah, ah
  call    print_num


  mov ah, 0
  int 0x16

  mov si, press_any_key

  call println
  call read_key
  call clear_screen
  jmp .main_loop

.floppy_ram: ; handle floppy to ram
  mov si, floppy_ram_message
  call println
  call read_n
  call read_head
  call read_track
  call read_sector
  call read_address

  call put_neline

  ; Now we have N, {Head, Track, Sector} and String to write
  call reset_floppy

  push    ax

  mov     ax, [segment_word]
	mov     es, ax
  mov     bx, buffer

  pop     ax

  mov     ah, 0x2
  mov     al, [n]
  mov     ch, [track]
  mov     cl, [sector]
  mov     dh, [head]
  mov     dl, 0x0
  mov     bx, [address]

  mov ax, [segment_word]
  call print_num
  call put_neline

  mov ax, [address]
  call print_num
  call put_neline

  int     INT_DSK
  mov     al, ah
  xor     ah, ah
  call    print_num

  mov ah, 0
  int 0x16

  jmp .main_loop

.ram_floppy: ; handle ram to floppy
  mov si, ram_floppy_message
  call println
  jmp .main_loop

add_to_buffer:
  push cx

  mov cx, word [bufflen]
  mov si, buffer
  add si, cx
  mov byte [si], al
  inc cx
  mov word [bufflen], cx

  pop cx
  ret

print_buffer:
  mov si, buffer
  call print
  call put_neline
  ret

read_buffer:
  push bp
  mov bp, sp
  pusha

.process_key:
  call read_key

  cmp al, KEY_CR
  jz .on_enter

  cmp al, KEY_BACKSPACE
  jz .on_backspace

  mov cx, word [bufflen]
  cmp cx, MAX_BUFFLEN
  jz .process_key

  call printch
  call add_to_buffer
  jmp .process_key

.on_enter:
  popa
  pop bp
  ret

.on_backspace:
  mov ah, VID_QUERY_CUR
  mov bh, 0x0
  int INT_VID

  cmp dl, 0x0
  jnz .on_backspace_cont
  mov cx, word [bufflen]
  cmp cx, 0x0
  jz .process_key
  
  cmp dh, 0x0
  jz .process_key
  dec dh
  mov dl, 0x4f
  mov ah, VID_SET_CUR_POS
  int INT_VID

  mov ah, 0xa
  mov al, KEY_SPACE
  mov bh, 0x0
  mov cx, 0x1
  int INT_VID

  mov cx, word [bufflen]
  cmp cx, 0x0
  jg .decrement_bufflen
  
  jmp .process_key

.decrement_bufflen:
  mov cx, word [bufflen]
  dec cx
  mov word [bufflen], cx
  jmp .process_key

.on_backspace_cont:
  mov cx, word [bufflen]
  cmp cx, 0x0
  jz .process_key
  call delete_char
  dec cx
  mov word [bufflen], cx
  jmp .process_key

  ret


clear_buffer:
  pusha
  mov word [bufflen], 0x0
  popa
  ret


read_n:
  pusha
  
  mov si, select_n_message
  call println
  call read_buffer
  call put_neline
  mov si, buffer
  mov cx, word [bufflen]
  mov si, buffer
  call atoi ; convert buffer to number
  mov word [n], ax ; save as Q
  call clear_buffer
  
  popa
  ret


read_head:
  pusha

  mov si, select_head_message
  call println
  call read_buffer
  call put_neline
  mov si, buffer
  mov cx, word [bufflen]
  mov si, buffer
  call atoi ; convert buffer to number
  mov word [head], ax ; save as Q
  call clear_buffer
  
  popa
  ret


read_track:
  pusha

  mov si, select_track_message
  call println
  call read_buffer
  call put_neline
  mov si, buffer
  mov cx, word [bufflen]
  mov si, buffer
  call atoi ; convert buffer to number
  mov word [track], ax ; save as Q
  call clear_buffer
  
  popa
  ret

read_sector:
  pusha

  mov si, select_sector_message
  call println
  call read_buffer
  call put_neline
  mov si, buffer
  mov cx, word [bufflen]
  mov si, buffer
  call atoi ; convert buffer to number
  mov word [sector], ax ; save as Q
  call clear_buffer
  
  popa
  ret

reset_floppy:
  pusha
  mov ah, DSK_RESET
  int INT_DSK
  popa
  ret

clear_vars:
  pusha
  mov word [bufflen], 0x0
  mov word [n], 0x0
  mov word [q], 0x0
  mov word [head], 0x0
  mov word [track], 0x0
  mov word [sector], 0x0
  popa
  ret


section .data
press_any_key db "Press any key to continue", 0x0
wrong_op_message db "You chose wrong operation, retry", 0x0
select_operation_message db "Select operation (1, 2, 3): ", 0x0
keyboard_floppy_message db "(KEYBOARD ==> FLOPPY)", 0x0
select_n_message db "N (1-30000): ", 0x0
select_q_message db "Q: ", 0x0
select_head_message db "Head: ", 0x0
select_track_message db "Track: ", 0x0
select_sector_message db "Sector: ", 0x0
floppy_ram_message db "(FLOPPY ==> RAM)", 0x0
ram_floppy_message db "(RAM ==> FLOPPY)", 0x0
input_string_message db "String: ", 0x0
empty_string db 0x0
address_help db "Segment:Address:", 0x0
address_space db "____:____", 0x0

segment_buffer dd 0
address_buffer dd 0


section .bss
buffer resb 0xff 
bufflen resw 0x1
storage_buffer resb 1
n resw 0x1
q resw 0x1
head resw 0x1
track resw 0x1
sector resw 0x1
segment_word resw 0x1
address resw 0x1


nhts                resb 8
; Nr of stuff to read/write
heads_count resw 0x1
tracks_count resw 0x1
sectors_count resw 0x1
  