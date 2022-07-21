format ELF64 executable 3

segment readable executable ; code

; includes
include 'unistd64.inc'

; constants
win_w = 512
win_h = 512
frame_buffer_size = win_h*win_w
ppm_buffer_size = frame_buffer_size*3

; program
entry _start
_start:
    call color_frame_buffer
    mov r15, 0
    cmp r15, win_h

    lea rdi, [image_file_path]
    call write_to_file

    mov rax, 69
    call print_int

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

    mov [int_buf+31], 0
    mov [int_buf+30], 10
    mov r15, 29
print_int_loop:
    cmp rax, 0
    je print_int_end
    xor rdx, rdx
    mov r14, 10
    div r14
    add rdx, '0'
    mov [int_buf+r15], dl
    dec r15
    jmp print_int_loop
print_int_end:
    mov rdi, 1
    lea rsi, [int_buf+r15]
    mov rdx, r15
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

    mov rsi, 1 ; write only
    mov rax, sys_open
    syscall
    mov rdi, rax
    lea rsi, [ppm_header]
    mov rdx, 16 ; TODO: do a strlen here
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
fill_ppm_buffer_loop:
    cmp r15, ppm_buffer_size
    je fill_ppm_buffer_end
    mov rax, [frame_buffer+r14]
    mov [ppm_buffer+r15], al
    shr rax, 8
    inc r15
    mov [ppm_buffer+r15], al
    shr rax, 8
    inc r15
    mov [ppm_buffer+r15], al
    inc r15

    inc r14
    jmp fill_ppm_buffer_loop
fill_ppm_buffer_end:
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
color_frame_buffer_outer:
    cmp r15, win_h
    jge color_frame_buffer_outer_end
    mov r14, 0
color_frame_buffer_inner:
    cmp r14, win_w
    jge color_frame_buffer_inner_end

    mov rax, 255
    mul r15
    mov rbx, win_h
    xor rdx, rdx
    div rbx
    mov r13, rax

    mov rax, 255
    mul r14
    mov rbx, win_w
    xor rdx, rdx
    div rbx
    shl rax, 8
    add r13, rax

    mov rax, r15
    mov rbx, win_w
    mul rbx
    add rax, r14
    mov [frame_buffer+rax], r13
    mov rax, r13

    add r14, 1
    jmp color_frame_buffer_inner
color_frame_buffer_inner_end:
    add r15, 1
    jmp color_frame_buffer_outer
color_frame_buffer_outer_end:
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
memset_L:
    cmp rax, 0
    jle memset_L_end
    mov [frame_buffer+rax], rbx
    sub rax, 1
    jmp memset_L
memset_L_end:

    pop rbx
    pop rcx
    pop rdi
    ret

segment readable writeable ; data
    frame_buffer rq frame_buffer_size ; 512*512
    int_buf rb 32
    ppm_buffer rb ppm_buffer_size ; 512*512*3
    
    image_file_path db '/home/matijadizdar/bs/asm/raycaster/image_file.ppm', 0
    ppm_header db 'P6', 10, '512 512', 10, '255', 10, 0
    