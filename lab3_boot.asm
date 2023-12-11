bits    16
org     7c00h

; A 1.44 MB floppy has 2 heads (front and back side of disk)
; 80 tracks per side
; 18 sectors per track
; 512 bytes per sector

; 1 head = 1,440 sectors = 737,280 bytes

; Team offsets:
; Cernetchi Maxim    "@@@FAF-212 Cernetchi MAXIM###"   : 1051 (58 track, 7 sector)
; Dobrojan Alexandru "@@@FAF-212 Dobrojan ALEXANDRU###": 1171 (65 track, 1 sector)
; Nastas Corneliu    "@@@FAF-212 Nastas CORNELIU###"   : 1411 (78 track, 7 sector)

start:
    ; reset drive
    mov     ah, 00h
    int     13h

    ; set ES:BX caller's buffer address 0000:7e00
    mov     ax, 0000h
    mov     es, ax
    mov     bx, 7e00h

    mov     ah, 02h ; read disk
    mov     al, 4   ; sectors count
    mov     ch, 0   ; track
    mov     cl, 2   ; sector
    mov     dh, 0   ; head
    mov     dl, 0   ; drive
    int     13h     ; disk interrupt

    jc      start   ; retry if error occured

    jmp     0000h:7e00h ; offset of next part

times 510 - ($ - $$) db 0 ; fill with zeroes unneeded remaininig space
dw 0xAA55 ; boot signature
