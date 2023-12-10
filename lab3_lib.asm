
%define KEY_BACKSPACE       08h
%define KEY_SPACE           20h
%define KEY_ENTER           0dh

%define INT_VID             10h
%define INT_DSK             13h
%define INT_KB              16h

%define VID_SET_CUR_SHAPE   01h
%define VID_SET_CUR_POS     02h
%define VID_QUERY_CUR       03h

%define VID_WRITE_CHAR      0ah
%define VID_TTY             0eh
%define VID_WRITE_STR       1301h

%define KB_READ             00h

%define DSK_RESET           00h
%define DSK_READ            02h
%define DSK_WRITE           03h

%define OP_KEYBOARD_FLOPPY  31h
%define OP_FLOPPY_RAM       32h
%define OP_RAM_FLOPPY       33h

jmp     start

; ========================================

get_cursor_pos:
    mov     ah, VID_QUERY_CUR
    mov     bh, 0
    int     INT_VID

    ret

; ========================================

read_input:
    mov     si, input_buffer

    typing:
        ; read the key pressed

        mov     ah, KB_READ
        int     INT_KB

        ; handle special keys

        cmp     al, KEY_BACKSPACE
	    je      hdl_backspace

	    cmp     al, KEY_ENTER
	    je      hdl_enter

        ; prevent program form reading more than 256 characters

        cmp     si, input_buffer + 256
        je      typing

        ; save the character read to the buffer

        mov     [si], al
	    inc     si

        ; display the character read

        mov     ah, VID_TTY
	    int     INT_VID

	    jmp     typing

    hdl_backspace:

        ; if the buffer is empty, ignore backspace

	    cmp     si, input_buffer
	    je      typing

        ; else erase the previous character from the buffer

	    dec     si
    	mov     byte [si], 0

        ; and print a blank space over it on the screen

        call    get_cursor_pos

        ; if at the start of the second+ line return to the previous one and proceed in the same manner

	    cmp     dl, 0
        je      prev_line

        ; else just return the cursor one colum back and print a blank space over what was there

        call    get_cursor_pos

        mov     ah, VID_SET_CUR_POS
        dec     dl
        int     INT_VID

        mov     ah, VID_WRITE_CHAR
        mov     al, 20h
        int     INT_VID

	    jmp     typing

    prev_line:
        call    get_cursor_pos

        mov     ah, VID_SET_CUR_POS
        dec     dh
        mov     dl, 79
        int     INT_VID

        mov     ah, VID_WRITE_CHAR
        mov     al, 20h
        int     INT_VID
    
        jmp     typing

    hdl_enter:

        ; if the buffer is empty - user is not allowed to proceed

        cmp     si, input_buffer
        je      typing

        ; ensure that the buffer ends with an empty byte

        mov     byte [si], 0

        ret

; ----------------------------------------

; ax = 0/1 - dec/hex
check_num_input:
    mov     si, input_buffer
    mov     byte [operation_flag], 1

    check_char_loop:
        cmp     byte [si], 00h
        je      check_input_approved

        check_char_block:

            check_digits:
                cmp     byte [si], 30h
                jl      check_input_denied

                cmp     byte [si], 39h
                jle     char_approved

                cmp     ax, 1
                je      check_letters

                jmp     check_input_denied

            check_letters:
                cmp     byte [si], 41h
                jl      check_input_denied

                cmp     byte [si], 46h
                jg      check_input_denied

            char_approved:
                inc     si
                jmp     check_char_loop

    check_input_denied:
        mov     byte [operation_flag], 0

    check_input_approved:
        ret

; ----------------------------------------

paginated_output:

    ; setup the RAM pointer

    mov     es, [address]
    mov     bp, [address + 2]

    paginated_output_loop:
        dec     word [n]
        jz      stop_paginated_output

        ; prepare a clean page

        push    es
        push    bp
        call    clear_screen
        pop     bp
        pop     es

        ; print one sector

        push    cx

        mov     bl, 07h
        mov     cx, 512

        mov     ax, 1301h
        int     10h

        ; advance pointers and counters

        pop     cx
        inc     cx
        add     bp, 512

        wait_for_page_advance_signal:

            ; read a keypress

            mov     ah, 00h
            int     16h

            ; if ENTER - break

            cmp     al, KEY_ENTER
            je      stop_paginated_output

            ; if SPACE - proceed to the next page

            cmp     al, KEY_SPACE
            jne     wait_for_page_advance_signal

        jmp     paginated_output_loop

    stop_paginated_output:
        ret

; ========================================

break_line:
    call    get_cursor_pos
    inc     dh
    mov     dl, 0

    xor     ax, ax
    mov     es, ax
    mov     bp, empty_str

    mov     bl, 07h
    mov     cx, 0

    mov     ax, VID_WRITE_STR
    int     INT_VID

    ret

; si - the effective address of a char buffer to print
; cx - the length of the buffer
print_str:
    push    cx
    push    si

    call    get_cursor_pos

    xor     ax, ax
    mov     es, ax
    pop     si
    mov     bp, si

    mov     bl, 07h
    pop     cx

    mov     ax, VID_WRITE_STR
    int     INT_VID

    ret

clear_screen:
    mov     ah, VID_SET_CUR_POS
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     INT_VID

    mov     cx, 22

    clear_screen_loop:
        push    cx

        mov     ah, VID_WRITE_CHAR
        mov     al, KEY_SPACE
        mov     bh, 0
        mov     bl, 07h
        mov     cx, 80
        int     INT_VID

        call    break_line

        pop     cx
        dec     cx
        jnz     clear_screen_loop

    mov     ah, VID_SET_CUR_POS
    mov     bh, 0
    mov     dh, 0
    mov     dl, 0
    int     INT_VID

    ret

; ========================================

; si - src. buffer
; di - buffer to store the actuall numerical value
atoi:
    atoi_conv_loop:

        ; check if all the digits were converted

        cmp     byte [si], 0
        je      atoi_conv_done

        ; convert the character's bytes to the number equivalent

        xor     ax, ax
        mov     al, [si]
        sub     al, '0'

        ; shift all the digits one place left and put a new digit at the first place

        mov     bx, [di]
        imul    bx, 10
        add     bx, ax
        mov     [di], bx

        ; advance to pint at the next charactr representing some digit

        inc     si
        jmp     atoi_conv_loop

    atoi_conv_done:
        ret

; ----------------------------------------

; si - src. buffer
; di - buffer to store the actuall numerical value
atoh:
    atoh_conv_loop:

        ; essentially works the same as the subroutine above, but ... 
        ; also need to consider that there are some letters representing - [Ah..Fh], that ... 
        ; need to be converted into numerical values - [10d..15d]

        cmp     byte [si], 0
        je      atoh_conv_done

        xor     ax, ax
        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     atoh_finish_iteration

        conv_digit:
            sub     al, 48

        atoh_finish_iteration:
            mov     bx, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bx

            inc     si

        jmp     atoh_conv_loop

    atoh_conv_done:
        ret

; ----------------------------------------

; di - pointer to the value to check
conv_check:
    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ah, 0eh
    mov     al, 3eh
    int     10h

    mov     ah, 0eh
    mov     al, 3eh
    int     10h

    mov     ah, 0eh
    mov     al, 20h
    int     10h

    mov     ax, [di]
    mov     bx, [test_result]

    xor     ax, bx
    jnz     incorrect

    correct:
        mov     ah, 0eh
        mov     al, 53h
        int     10h

        jmp     check_end

    incorrect:
        mov     ah, 0eh
        mov     al, 45h
        int     10h

    check_end:
        ret


; ========================================

read_hts_addr:

    ; print head

    call    break_line
    mov     si, hts_in_head_str
    mov     cx, hts_in_head_str_len
    call    print_str

    ; setup counter: cx=0 - read head, cx=1 - read track, ...
    ; hts_in_str + cx * hts_in_str_len: cx=0 - "Head   = ", cx=1 - "Track  = ", ...
    ; [hts + cx * 2]: cx=0 - head value, cx=1 - track value, ...

    mov     word [mp_16bit_counter], 0

    read_hts_addr_loop:
        call    break_line

        mov     si, hts_in_str
        mov     cx, [mp_16bit_counter]
        imul    cx, hts_in_str_len
        add     si, cx
        mov     cx, hts_in_str_len
        call    print_str

        call    read_input

        mov     ax, 0
        call    check_num_input

        cmp     byte [operation_flag], 0
        je      read_hts_addr_end

        mov     di, hts
        mov     cx, [mp_16bit_counter]
        imul    cx, 2
        add     di, cx
        mov     si, input_buffer
        call    atoi
        
        inc     word [mp_16bit_counter]

        cmp     word [mp_16bit_counter], 2
        jle     read_hts_addr_loop

    read_hts_addr_end:
        ret

; ----------------------------------------

read_ram_addr:

    ; print head

    call    break_line
    mov     si, addr_in_head_str
    mov     cx, addr_in_head_str_len
    call    print_str

    ; the same princeple as in the read_hts_addr

    mov     word [mp_16bit_counter], 0

    read_ram_addr_loop:
        call break_line

        mov     si, addr_in_str
        mov     cx, [mp_16bit_counter]
        imul    cx, addr_in_str_len
        add     si, cx
        mov     cx, addr_in_str_len
        call    print_str

        call    read_input

        mov     ax, 1
        call    check_num_input

        cmp     byte [operation_flag], 0
        je      read_ram_addr_end

        mov     di, address
        mov     cx, [mp_16bit_counter]
        imul    cx, 2
        add     di, cx
        mov     si, input_buffer
        call    atoh

        inc     word [mp_16bit_counter]

        cmp     word [mp_16bit_counter], 1
        jle     read_ram_addr_loop

    read_ram_addr_end:
        ret

; ========================================

; si - src. buffer
; di - target buffer
; cx - n times to copy
; bx - block size
copy_buffer:
    mov     word [copy_size], 0

    push    si
    mov     dx, 0

    find_end:
        cmp     byte [si], 00h
        je      end_found

        inc     si
        inc     dx

        jmp     find_end

    end_found:
        pop     si

        inc     cx
        push    cx
        push    dx
        push    cx

    copy_buffer_loop:
        pop     cx
        dec     cx
        jz      zeroing

        push    cx
        push    si
        push    dx

        copy_characters_loop:
            mov     al, [si]
            mov     [di], al

            inc     si
            inc     di

            dec     dx
            jnz     copy_characters_loop

        pop     dx
        pop     si

        add     word [copy_size], dx

        jmp     copy_buffer_loop

    zeroing:
        pop     dx
        pop     cx
        dec     cx

        imul    dx, cx

        mov     ax, dx
        xor     dx, dx
        div     bx

        zeroing_loop1:
            cmp     dx, bx
            je      copy_buffer_finished

            mov     byte [di], 00h
            inc     di
            inc     dx
            inc     word [copy_size]

            jmp     zeroing_loop1

    copy_buffer_finished:
        ret

; ----------------------------------------

transfer_n_bytes_from_ram:
    xor     dx, dx
    mov     ax, [n]
    mov     bx, 512
    div     bx

    mov     cx, 0
    
    mov     es, [address]
    mov     bp, [address + 2]

    mov     si, storage_buffer

    copy_bytes_loop:
        cmp     cx, [n]
        jge     zeroing_loop2

        xor     ax, ax
        mov     al, [es:bp]
        mov     [si], al
        
        inc     bp
        inc     si
        inc     cx

        jmp     copy_bytes_loop

    zeroing_loop2:
        mov     byte [si], 0
            
        inc     si
        inc     dx

        cmp     dx, 512
        jl      zeroing_loop2
    
    ret