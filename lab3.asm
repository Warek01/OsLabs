bits    16
org     7e00h

section .text

%include 'lab3_lib.asm'

start:
    call    reset_memory
    xor     sp, sp

    ; print the options listing str.
    mov     si, op_list_str
    mov     cx, op_list_str_len
    call    print_str

    ; read user's choice
    mov     ah, KB_READ
    int     INT_KB

    ; print user's choice
    mov     ah, VID_TTY
    int     INT_VID

    ; direct the exec. flow
    cmp     al, OP_KEYBOARD_FLOPPY
    je      kbd_to_flp

    cmp     al, OP_FLOPPY_RAM
    je      flp_to_ram

    cmp     al, OP_RAM_FLOPPY
    je      ram_to_flp

    jmp     error

kbd_to_flp:
    ; read the string
    call    break_line
    mov     si, str_in_str
    mov     cx, str_in_str_len
    call    print_str

    call    read_input

    ; save the str. to its own buffer
    mov     si, input_buffer
    mov     di, str_buffer
    mov     cx, 1
    mov     bx, 256
    call    copy_buffer

    ; read N
    call    break_line
    mov     si, n_in_str
    mov     cx, n_in_str_len
    call    print_str

    call    read_input

    mov     ax, 0
    call    check_num_input

    cmp     byte [operation_flag], 0
    je      error

    mov     di, n
    mov     si, input_buffer
    call    atoi

    ; read HTS address
    call    read_hts_addr

    cmp     byte [operation_flag], 0
    je      error

    ; preapare the buffer to write to the floppy
    mov     si, str_buffer
    mov     di, storage_buffer
    mov     cx, [n]
    mov     bx, 512
    call    copy_buffer

    ; calculate the number of sectos to write
    xor     dx, dx
    mov     ax, [copy_size]
    mov     bx, 512
    div     bx

    ; write to the floppy
    push    ax

    xor     ax, ax
	mov     es, ax
    mov     bx, storage_buffer

    pop     ax

    mov     ah, DSK_WRITE
    add     al, 0
    mov     ch, [hts + 2]
    mov     cl, [hts + 4]
    mov     dh, [hts + 0]
    mov     dl, 0

    int     INT_DSK

    ; print the error code
    call    display_error_code

    ; print the string read
    call    break_line
    call    break_line
    mov     si, str_buffer
    mov     cx, 256
    call    print_str

    jmp     terminate

flp_to_ram:
    ; read HTS address
    call    read_hts_addr

    cmp     byte [operation_flag], 0
    je      error

    ; read RAM address
    call    read_ram_addr

    cmp     byte [operation_flag], 0
    je      error

    ; read N
    call    break_line
    mov     si, n_in_str
    mov     cx, n_in_str_len
    call    print_str

    call    read_input

    mov     ax, 0
    call    check_num_input

    cmp     byte [operation_flag], 0
    je      error

    mov     di, n
    mov     si, input_buffer
    call    atoi

    ; read data from floppy
    mov     es, [address + 0]
    mov     bx, [address + 2]

    mov     ah, DSK_READ
    mov     al, [n]
    mov     ch, [hts + 2]
    mov     cl, [hts + 4]
    mov     dh, [hts + 0]
    mov     dl, 0

    int     INT_DSK

    ; print error code
    call    display_error_code

    ; print the data read
    call    paginated_output

    jmp     terminate

ram_to_flp:
    ; read RAM address
    call    read_ram_addr

    cmp     byte [operation_flag], 0
    je      error

    ; read HTS address
    call    read_hts_addr

    cmp     byte [operation_flag], 0
    je      error

    ; read Q
    call    break_line
    mov     si, n_in_str
    mov     cx, n_in_str_len
    call    print_str

    call    read_input

    mov     ax, 0
    call    check_num_input

    cmp     byte [operation_flag], 0
    je      error

    mov     di, n
    mov     si, input_buffer
    call    atoi

    ; transfer n bytes to the write buffer
    call    transfer_n_bytes_from_ram

    ; calculate the number of sectors to write
    xor     dx, dx
    mov     ax, [n]
    mov     bx, 512
    div     bx

    ; write data to floppy
    push    ax

    xor     ax, ax
    mov     es, ax
    mov     bx, storage_buffer

    pop     ax

    mov     ah, DSK_WRITE
    add     al, 1
    mov     ch, [hts + 2]
    mov     cl, [hts + 4]
    mov     dh, [hts + 0]
    mov     dl, 0
    int     INT_DSK

    ; print the error code
    call    display_error_code

    ; print the data written
    call    break_line
    call    get_cursor_pos

    inc     dh
    mov     dl, 0

    mov     es, [address]
    mov     bp, [address + 2]

    mov     bl, 07h
    mov     cx, 512

    mov     ax, 1301h
    int     10h

    jmp     terminate

; ========================================

display_error_code:
    push    ax

    ; print "EC="
    call    break_line
    mov     si, err_code_msg
    mov     cx, err_code_msg_len
    call    print_str

    ; print the error code (an integer)
    pop     ax

    mov     al, '0'
    add     al, ah
    mov     ah, VID_TTY
    int     INT_VID

    ret

error:
    call    get_cursor_pos

    xor     ax, ax
    mov     es, ax
    mov     bp, err_msg

    mov     cx, err_msg_len
    mov     bl, 07h

    mov     ax, VID_WRITE_STR
    int     INT_VID

    jmp     terminate

terminate:
    call    break_line
    mov     si, pak_msg
    mov     cx, pak_msg_len
    call    print_str

    wait_for_confirm:
        mov     ah, KB_READ
        int     INT_KB

        cmp     al, KEY_ENTER
        jne     wait_for_confirm

    call    clear_screen

    jmp     start

; ========================================

reset_memory:
    call    reset_floppy
    call    clear_vars
    
    mov     si, input_buffer
    mov     di, input_buffer + 256
    call    clear_buffer

    mov     si, str_buffer
    mov     di, str_buffer + 256
    call    clear_buffer

    mov     si, hts
    mov     di, hts + 6
    call    clear_buffer

    mov     si, address
    mov     di, address + 8
    call    clear_buffer

    mov     si, storage_buffer
    mov     di, storage_buffer + 1
    call    clear_buffer

    call    reset_registers

    ret

; ----------------------------------------

reset_floppy:
    mov     ah, DSK_RESET
    int     INT_DSK
    
    ret

; ----------------------------------------

clear_vars:
    mov     word [n], 0000h
    mov     word [q], 0000h
  
    ret

; ----------------------------------------

; si - starting address of the buffer
; di - ending address of the buffer
clear_buffer:
    clear_buffer_loop:
        mov     byte [si], 0
        inc     si

        cmp     si, di
        jl      clear_buffer_loop

    ret

; ----------------------------------------

reset_registers:
    xor     ax, ax
    xor     bx, bx
    xor     cx, cx
    xor     dx, dx
    xor     si, si
    xor     di, di
    mov     es, ax
    xor     bp, bp

    ret

; ========================================

stop:


section .data


empty_str               db 00h

pak_msg                 db "Press any key to continue...", 00h
pak_msg_len             equ 28

wrong_op_msg            db "ERR: Unknown option!", 00h
wrong_op_msg_len        equ 20

op_list_str             db "1. KBD ==> FLP | 2. FLP ==> RAM | 3. RAM ==> FLP : ", 00h
op_list_str_len         equ 51

n_in_str                db "N (times / sectors / bytes) = ", 00h
n_in_str_len            equ 30

hts_in_head_str         db "HTS:", 00h
hts_in_head_str_len     equ 4

hts_in_str              db "Head   = Track  = Sector = ", 00h
hts_in_str_len          equ 9

str_in_str              db "String = ", 00h
str_in_str_len          equ 9

addr_in_head_str        db "Specify the address (XXXX:YYYY):", 00h
addr_in_head_str_len    equ 32

addr_in_str             db "SEGMENT = OFFSET  = ", 00h
addr_in_str_len         equ 10

n                       dw 0
q                       dw 0

err_msg                 db " >> ERR", 00h
err_msg_len             equ 7

err_code_msg            db "EC=", 00h
err_code_msg_len        equ 3

operation_flag          dw 0
mp_16bit_counter        dw 0
copy_size               dw 0

test_result             dw 0020h

; ========================================

section .bss

input_buffer        resb 256
str_buffer          resb 256
hts                 resb 6
address             resb 4
storage_buffer      resb 1