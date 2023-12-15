bits 16
org 0x7c00

; Dobrojan Alexandru: 1171 (1 side 32 track, 2 sector)

%define BUFFER_LENGTH 4

start:
  call clear_buffer
  xor ax, ax
  xor bx, bx
  xor cx, cx
  xor dx, dx
  xor si, si
  xor di, di
  
  mov ah, 0x0
  mov al, 0x3
  int 0x10

  mov si, str_name
  mov di, buffer
  mov ch, 1
  call read_str
  
  ; convert buffer to head
  mov si, buffer
  mov di, hts
  call atoi
  call clear_buffer

  ; convert buffer to track
  mov si, str_track
  mov di, buffer
  mov ch, 2
  call read_str
  
  mov si, buffer
  mov di, hts + 2
  call atoi
  call clear_buffer

  ; convert buffer to sector
  mov si, str_sector
  mov di, buffer
  mov ch, 2
  call read_str
  
  mov si, buffer
  mov di, hts + 4
  call atoi
  call clear_buffer

  ; reset drive
  mov ah, 0
  int 0x13

  ; set ES:BX caller's buffer address 0000:7e00
  mov ax, 0
  mov es, ax
  mov bx, 0x7e00

  mov ah, 2 ; read disk
  mov al, 4 ; sectors count
  mov ch, [hts + 2] ; track
  mov cl, [hts + 4] ; sector
  mov dh, [hts] ; head
  mov dl, 0 ; drive
  int 0x13
  call print_err

  mov si, str_pak
  call print_str

  push ax
  mov ah, 0x0
  int 0x16
  pop ax

  cmp ah, 0
  jc start
  jnz start
  jmp 0x0000:0x7e00 ; offset of next part


; si - src. buffer
; di - buffer to store the actuall numerical value
atoi:
  pusha
  mov word [di], 0

.loop:
  ; check if all the digits were converted
  cmp byte [si], 0
  je .done

  ; convert the character's bytes to the number equivalent
  xor ax, ax
  mov al, [si]
  sub al, '0'

  ; shift all the digits one place left and put a new digit at the first place
  mov bx, [di]
  imul bx, 10
  add bx, ax
  mov [di], bx

  ; advance to pint at the next charactr representing some digit
  inc si
  jmp .loop

.done:
  popa
  ret


; si - src. buffer
; di - buffer to store the actuall numerical value
atoh:
  ; essentially works the same as the subroutine above, but ... 
  ; also need to consider that there are some letters representing - [Ah..Fh], that ... 
  ; need to be converted into numerical values - [10d..15d]
  pusha
.loop:
  cmp byte [si], 0
  je .done
  xor ax, ax
  mov al, [si]
  cmp al, 65
  jl .conv  
  sub al, 55
  jmp .finnish_iteration

.conv:
  sub al, 48

.finnish_iteration:
  mov bx, [di]
  imul bx, 16
  add bx, ax
  mov [di], bx
  inc si
  jmp .loop

.done:
  popa
  ret

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


; si - text to display before input
; di - where to put input
; ch - max length
read_str:
  pusha

  cmp si, 0
  jz .read_start
  call print_str

.read_start:
  xor ax, ax
  xor cl, cl
  mov si, di

.iteration:
  mov ah, 0
  int 0x16

  cmp al, 0xd
  jz .handle_enter

  cmp al, 0x8
  jz .handle_backspace

  cmp cl, ch
  jz .iteration

  mov ah, 0xe
  int 0x10

  xor ah, ah
  mov byte [si], al
  inc cl
  inc si
  jmp .iteration

.handle_enter:
  jmp .done

.handle_backspace:
  cmp cl, 0
  jz .iteration

  mov ah, 0xe
  mov al, 0x8
  int 0x10

  mov ah, 0xa
  mov al, 0x20
  int 0x10
  dec cl
  jmp .iteration

.done:
  call newline
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

clear_buffer:
  pusha
  mov cx, 0

.loop:
  cmp cx, BUFFER_LENGTH
  jz .end
  mov si, buffer
  add si, cx
  mov byte [si], 0
  inc cx
  jmp .loop

.end:
  popa
  ret


; ah - error integer
print_err:
  pusha
  mov si, str_err
  call print_str
  mov al, ah
  xor ah, ah
  call print_int
  call newline
  popa
  ret

; al - char to print
print_char:
  pusha
  mov ah, 0xe
  int 0x10
  popa
  ret


str_name db "Dobrojan Alexandru", 0xd, 0xa, "Head = ", 0
str_track db "Track = ", 0
str_sector db "Sector = ", 0
str_err db "Err = ", 0
buffer times BUFFER_LENGTH db 0
hts times 3 dw 0
str_pak db "Press any key to continue ...", 0


align 512
