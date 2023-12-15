bits 16
org 0x7e00

start:
  mov ah, 0x0
  mov al, 3
  int 0x10

  mov cx, 5
  mov si, test_func
  call exec_after
  call pak
  jmp 0x0000:0x7c00


; si - string to write, stops at zero byte
print_str:
  pusha
  cmp word [si], 0
  jz .done

.loop:
  lodsb
  cmp al, 0
  jz .done
  mov ah, 0xe
  int 0x10
  jmp .loop

.done:
  popa
  ret


newline:
  push ax
  mov ah, 0xe
  mov al, 0xd
  int 0x10
  mov al, 0xa
  int 0x10
  pop ax
  ret


; ax - number to print
print_int:
  pusha
  mov cx, 10 
  push 0

.convert_loop:
  xor dx, dx
  div cx
  add dl, '0'
  push dx
  cmp ax, 0
  jnz .convert_loop

.print_loop:
  pop ax
  cmp al, 0 
  jz .end
  mov ah, 0xe
  int 0x10
  jmp .print_loop

.end:
  popa
  ret


; cx - seconds to count
; si - function to call
exec_after:
  pusha
  push cx
  mov ah, 0

.loop_second:
  cmp cx, 0
  jz .print
  push cx
  xor cx, cx
  xor bx, bx
  xor ax, ax
  xor dx, dx
  int 0x1a ; dx - low count, cx - high count
  mov bx, dx ; when started

.count_loop:
  mov ah, 0
  int 0x1a 
  sub dx, bx
  cmp dx, 18
  jl .count_loop

  pop cx
  xor ch, ch
  mov al, cl
  call print_int
  dec cx
  call newline
  
  jmp .loop_second

.print:
  mov ax, 0
  pop cx
  call newline

.print_loop:
  cmp ax, cx
  jz .end
  call si
  inc ax
  jmp .print_loop

.end:
  popa
  ret


test_func:
  pusha
  mov si, str_string
  call print_str
  popa
  ret


pak:
  pusha
  call newline
  mov si, str_pak
  call print_str
  mov ah, 0
  int 0x16
  call newline
  popa
  ret


str_string db "Test string", 0xd, 0xa, 0
str_pak db "Press any key to continue ...", 0

