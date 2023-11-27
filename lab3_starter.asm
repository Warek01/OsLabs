bits 16
org 0x7c00

; This code starts the code starting at the second sector
; 

; Max CERNETCHI img offset = 538112
; Alexandru DOBROJAN img offset = 599552
; Corneliu NASTAS img offset = 722432
; Ctrl + G to go to offset in vscode hex editor

; A 1.44 MB floppy has 2 heads (front and back side of disk)
; 80 tracks per side
; 18 sectors per track
; 512 bytes per sector

start:
  mov ax, 0x07e0     
  mov es, ax ; caller's buffer address

reset_floppy:
  xor ax, ax
  int 0x13
  jc reset_floppy ; retry if error       
    
read_floppy:
  mov ah, 0x2 
  mov al, 0x3 ; sectors nr (increase if not enough memory)
  mov ch, 0x0 ; track
  mov cl, 0x2 ; sector
  mov dh, 0x0 ; head
  int 0x13
  jc read_floppy ; retry if error

  jmp 0x07e0:0x0000 

times 510 - ($ - $$) db 0
dw 0xaa55
