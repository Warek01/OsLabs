bits 16
org 0x7c00

; This code starts the code starting at the second sector
; https://stackoverflow.com/questions/39534327/bootloader-not-loading-second-sector

; Max CERNETCHI img offset = 538112
; Alexandru DOBROJAN img offset = 599552
; Corneliu NASTAS img offset = 722432
; Ctrl + G to go to offset in vscode hex editor

start:
  mov ax, 0x07e0     
  mov es, ax  
    
floppy:
  mov ah, 0x2 
  mov al, 0x1 ; sectors nr
  mov ch, 0x0 ; track
  mov cl, 0x2 ; sector
  mov dh, 0x0 ; head
  int 0x13
  jc floppy

  jmp 0x07e0:0x0000 

times 510 - ($ - $$) db 0
dw 0xaa55
