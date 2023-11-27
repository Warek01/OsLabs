bits 16
org 0x7e00

%include 'lab3_lib.asm'

section .text:
start:
  mov al, 0x3
  call set_video_mode

  mov word [bufflen], 0x0

.main_loop:
  mov si, select_operation_message
  call print
  
  call read_key
  call printch
  call put_neline

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

  ; cmp al, KEY_CR
  ; jz .on_enter

  ; cmp al, KEY_BACKSPACE
  ; jz .on_backspace

  ; call add_to_buffer
  
  jmp .main_loop

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

.keyboard_floppy:
  mov si, keyboard_floppy_message
  call println
  jmp .main_loop

.floppy_ram:
  mov si, floppy_ram_message
  call println
  jmp .main_loop

.ram_floppy:
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


section .data
wrong_op_message db "You chose wrong operation, retry", 0x0
select_operation_message db "Select operation (1, 2, 3): ", 0x0
keyboard_floppy_message db "(KEYBOARD ==> FLOPPY)", 0x0
floppy_ram_message db "(FLOPPY ==> RAM)", 0x0
ram_floppy_message db "(RAM ==> FLOPPY)", 0x0

section .bss
buffer resb 0xff 
bufflen resw 0x1
  