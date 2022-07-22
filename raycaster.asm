format ELF64 executable 3

segment readable executable ; code

macro puts_static string* {
    push rdx
    push rsi
    push rdi
    push rax
    mov rdx, string#.size
    lea rsi, [string]
    mov rdi, 1          ; stdout
    mov rax, sys_write  ; sys_write
    syscall
    pop rax
    pop rdi
    pop rsi
    pop rdx
}

macro debug_reg reg* {
    push reg
    push rax
    puts_static debug_str
    mov rax, reg
    call print_int
    pop rax
    pop reg
}

; includes
include 'unistd64.inc'

; program
entry _start
_start:
    finit

    call color_frame_buffer
    call draw_map
    call draw_player

    lea rdi, [image_file_path]
    call write_to_file

    xor rdi, rdi ; set exit code to 0
    mov rax, sys_exit
    syscall

draw_player:
    push rax
    ; player_x * rect_w
    fld [player_x]
    sub rsp, 8 ; allocate 8 bytes for a variable
    mov qword [rsp], rect_w
    fimul dword [rsp]
    fistp qword [rsp]
    pop rax

    ; player_y * rect_h
    fld [player_y]
    sub rsp, 8 ; allocate 8 bytes for a variable
    mov qword [rsp], rect_h
    fimul dword [rsp]
    fistp qword [rsp]
    pop rbx

    mov rcx, player_w
    mov rdx, player_h
    mov rdi, player_color

    call draw_rectangle
    pop rax
    ret

draw_map:
    push r15
    push r14
    push rax
    push rbx
    mov r15, 0
    .outer:
        cmp r15, map_h
        jge .outer_end
        mov r14, 0
        @@:
            cmp r14, map_w
            jge @f

            mov rax, r15
            imul rax, map_w
            add rax, r14
            mov al, [map+rax]
            cmp al, ' '
            jne .good
            inc r14
            jmp @b
            .good:

            mov rax, r14
            imul rax, rect_w
            mov rbx, r15
            imul rbx, rect_h
            mov rcx, rect_w
            mov rdx, rect_h
            mov rdi, rect_color

            call draw_rectangle

            inc r14
            jmp @b
        @@:
        inc r15
        jmp .outer
    .outer_end:

    pop rbx
    pop rax
    pop r14
    pop r15
    ret

draw_rectangle:
    push r15
    push r14
    push rax
    push rbx
    push rcx ; width
    push rdx ; height
    push rdi ; color
    push r10
    push r11
    mov r10, rax ; horizontal position
    mov r11, rbx ; vertical position

    mov r15, 0
    .outer:
        cmp r15, rcx
        jge .outer_end
        mov r14, 0
        @@:
            cmp r14, rdx
            jge @f

            mov rax, r10
            add rax, r15
            mov rbx, r11
            add rbx, r14
            imul rbx, win_h
            add rax, rbx
            mov [frame_buffer+8*rax], rdi

            inc r14
            jmp @b
        @@:
        inc r15
        jmp .outer
    .outer_end:

    pop r11
    pop r10
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop r14
    pop r15
    ret

; params
; rax -> value to print
; returns
; nothing
print_int:
    push rax
    push r14
    push r15
    push rdx
    push rdi
    push rsi

    ; TODO: handle printing 0

    mov [int_buf+63], 0
    mov [int_buf+62], 10
    mov r15, 61
    @@:
        cmp rax, 0
        je @f
        xor rdx, rdx
        mov r14, 10
        div r14
        add rdx, '0'
        mov [int_buf+r15], dl
        dec r15
        jmp @b
    @@:
    inc r15
    mov rdi, 1
    lea rsi, [int_buf+r15]
    mov rdx, 63
    sub rdx, r15
    mov rax, sys_write
    syscall

    pop rsi
    pop rdi
    pop rdx
    pop r15
    pop r14
    pop rax
    ret

; fills ppm buffer with the contents of frame_buffer and writes to image_file_path
write_to_file:
    push rdi
    push rsi
    push rdx

    mov rax, sys_open
    mov rsi, 1 or 0100o ; create and write
    mov rdx, 644o ; umode, owner: read+write, group: read, others: read
    syscall

    mov rdi, rax
    lea rsi, [ppm_header]
    mov rdx, ppm_header.size
    mov rax, sys_write
    syscall

    call fill_ppm_buffer
    lea rsi, [ppm_buffer]
    mov rdx, ppm_buffer_size
    mov rax, sys_write
    syscall

    mov rax, sys_close
    syscall

    pop rdx
    pop rsi
    pop rdi
    ret

fill_ppm_buffer:
    push rax
    push r15
    push r14
    mov r15, 0
    mov r14, 0
    @@:
        cmp r15, ppm_buffer_size
        je @f
        mov rax, [frame_buffer+8*r14]
        mov [ppm_buffer+r15], al
        shr rax, 8
        inc r15
        mov [ppm_buffer+r15], al
        shr rax, 8
        inc r15
        mov [ppm_buffer+r15], al
        inc r15

        inc r14
        jmp @b
    @@:
    pop r14
    pop r15
    pop rax
    ret

; puts a weird gradient in the frame buffer, for debugging
color_frame_buffer:
    push r15
    push r14
    push r13
    push rbx
    push rdx

    mov r15, 0
    .outer:
        cmp r15, win_h
        jge .outer_end
        mov r14, 0
        @@:
            cmp r14, win_w
            jge @f

            mov rax, r15
            imul rax, 255
            mov rbx, win_h
            xor rdx, rdx
            div rbx
            mov r13, rax

            mov rax, r14
            imul rax, 255
            mov rbx, win_w
            xor rdx, rdx
            div rbx
            shl rax, 8
            add r13, rax

            mov rax, r15
            imul rax, win_w
            add rax, r14
            mov [frame_buffer+8*rax], r13

            inc r14
            jmp @b
        @@:
        inc r15
        jmp .outer
    .outer_end:

    pop rdx
    pop rbx
    pop r13
    pop r14
    pop r15
    ret

memset:
    push rdi
    push rcx
    push rbx
    
    mov rax, rcx
    @@:
        cmp rax, 0
        jle @f
        mov [frame_buffer+rax], rbx
        sub rax, 1
        jmp @b
    @@:

    pop rbx
    pop rcx
    pop rdi
    ret

segment readable writeable ; data
    ; constants
    win_w = 512
    win_h = 512
    frame_buffer_size = win_h*win_w
    ppm_buffer_size = frame_buffer_size*3

    ; variables
    frame_buffer rq frame_buffer_size ; 512*512
    int_buf rb 64
    int_buf.size = $ - int_buf
    ppm_buffer rb ppm_buffer_size ; 512*512*3
    
    map_w = 16
    map_h = 16
    map db "0000222222220000",\
           "1              0",\
           "1      11111   0",\
           "1     0        0",\
           "0     0  1110000",\
           "0     3        0",\
           "0   10000      0",\
           "0   0   11100  0",\
           "0   0   0      0",\
           "0   0   1  00000",\
           "0       1      0",\
           "2       1      0",\
           "0       0      0",\
           "0 0000000      0",\
           "0              0",\
           "0002222222200000", 0
    map.size = $ - map

    rect_w = win_w / map_w
    rect_h = win_h / map_h
    ;            red          green         blue
    rect_color = (0 shl 0) + (255 shl 8) + (255 shl 16) ; cyan

    player_x dq 3.420
    player_y dq 2.345
    player_w = 5
    player_h = 5
    ;              red           green         blue
    player_color = (255 shl 0) + (255 shl 8) + (255 shl 16) ; white

    image_file_path db 'image_file.ppm', 0
    image_file_path.size = $ - image_file_path - 1
    ppm_header db 'P6', 10, '512 512', 10, '255', 10, 0
    ppm_header.size = $ - ppm_header - 1

    debug_str db '[DEBUG]: ', 0
    debug_str.size = $ - debug_str - 1
    