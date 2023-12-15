bits 16
org 0x7c00

; Dobrojan Alexandru: 1171 (1 side 32 track, 2 sector)

%define BUFFER_LENGTH 6 ; note that last byte of buffer should be always 0 to avoid bugs with string reads that end on 0

start:
  call clear_buffer
  
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

  ; read segment and convert it
  mov si, str_segment
  mov di, buffer
  mov ch, 4
  call read_str

  mov si, buffer
  mov di, w_segment
  call atoh
  call clear_buffer

  ; read offset and convert it
  mov si, str_offset
  mov di, buffer
  mov ch, 4
  call read_str

  mov si, buffer
  mov di, w_offset
  call atoh
  call clear_buffer

  ; reset drive
  mov ah, 0
  int 0x13

  ; set ES:BX caller's buffer address
  mov es, [w_segment]
  mov bx, [w_offset]

  mov ah, 2 ; read disk
  mov al, 5 ; sectors count
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

  mov ax, [w_segment]
  mov bx, [w_offset]
  mov bp, bx ; preserve offset for code after jump
  jmp far bx ; offset of next part


; si - string to read
; di - where to put the number
atoi:
  pusha
  mov ax, 0x0
  mov bx, 0xa

.loop:
  mov cx, [si]
  inc si
  cmp cx, 0
  jz .end
  sub cx, '0'
  mul bx
  add ax, cx
  jmp .loop

.end:
  mov [di], ax
  popa
  ret


; si - src. buffer
; di - buffer to store the actuall numerical value
atoh:
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
  pusha
  mov ah, 0xe
  mov al, 0xd
  int 0x10
  mov al, 0xa
  int 0x10
  popa
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
  mov byte [buffer], 0
  mov byte [buffer + 1], 0
  mov byte [buffer + 2], 0
  mov byte [buffer + 3], 0
  ret


; ah - error integer
print_err:
  pusha
  mov si, str_err
  call print_str
  shr ax, 4 ; make al=ah and ah=0
  call print_int
  call newline
  popa
  ret


str_name db "Dobrojan Alexandru", 0xd, 0xa, "Head ", 0
str_track db "Track ", 0
str_sector db "Sector ", 0
str_err db "Err ", 0
buffer times BUFFER_LENGTH db 0
hts times 3 dw 0
w_segment dw 0
w_offset dw 0
str_pak db "Press key", 0
str_segment db "Segment ", 0
str_offset db "Offset ", 0

times $ - ($ - 512) db '='
