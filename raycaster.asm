format ELF64 executable 3

segment readable executable ; code

macro puts_static string {
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
    call color_frame_buffer

    lea rdi, [image_file_path]
    call write_to_file

    xor rdi, rdi ; set exit code to 0
    mov rax, sys_exit
    syscall

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
    
    image_file_path db 'image_file.ppm', 0
    image_file_path.size = $ - image_file_path - 1
    ppm_header db 'P6', 10, '512 512', 10, '255', 10, 0
    ppm_header.size = $ - ppm_header - 1

    debug_str db '[DEBUG]: ', 0
    debug_str.size = $ - debug_str - 1
    