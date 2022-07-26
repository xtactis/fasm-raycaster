format ELF64 executable 3

segment readable executable ; code

; includes
include 'unistd64.inc'
include 'colors.inc'
include 'debug.asm'
include 'extra_flops.asm'

; program
entry _start
_start:
    finit
    sub rsp, 2
    fstcw word [rsp]               ; store control word
    mov ax, word [rsp]
    and ah, 11110011b               ; clear _only_ RC field
    or  ah, 00000100b               ; set _only_ RC field (rounding to -∞)
    mov word [rsp], ax
    fldcw word [rsp]
    add rsp, 2
    
    call init_sprites

    ; TODO generalize image reading and maybe do it at runtime idk
    call read_texture_file
    call read_monsters_file
    call animate

    xor rdi, rdi ; set exit code to 0
    mov rax, sys_exit
    syscall

init_sprites:
    push rax
    
    mov rax, 1.834
    mov qword [monsters + 8*0 + sizeof.Sprite*0], rax
    mov rax, 8.765
    mov qword [monsters + 8*1 + sizeof.Sprite*0], rax
    mov qword [monsters + 8*2 + sizeof.Sprite*0], 0

    mov rax, 5.323
    mov qword [monsters + 8*0 + sizeof.Sprite*1], rax
    mov rax, 5.365
    mov qword [monsters + 8*1 + sizeof.Sprite*1], rax
    mov qword [monsters + 8*2 + sizeof.Sprite*1], 1

    mov rax, 4.123
    mov qword [monsters + 8*0 + sizeof.Sprite*2], rax
    mov rax, 10.265
    mov qword [monsters + 8*1 + sizeof.Sprite*2], rax
    mov qword [monsters + 8*2 + sizeof.Sprite*2], 1

    pop rax
    ret

read_texture_file:
    push rax
    push rbx
    push rcx
    push rdx
    push r15
    push r14

    mov r15, 0
    .outer:
        cmp r15, texture_size
        jge .outer_end
        
        mov r14, 0
        @@:
            cmp r14, texture_width
            jge @f

            mov rcx, r15
            imul rcx, texture_width
            add rcx, r14
            imul rcx, 3
            mov rbx, 0
            mov dl, [wall_texture_file+rcx]
            mov bl, dl
            mov dl, [wall_texture_file+rcx+1]
            mov bh, dl
            mov dl, [wall_texture_file+rcx+2]
            shl edx, 16
            add ebx, edx

            mov rcx, r15
            imul rcx, texture_width
            add rcx, r14
            mov [textures+8*rcx], rbx

            inc r14
            jmp @b
        @@:

        inc r15
        jmp .outer
    .outer_end:

    pop r14
    pop r15
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

read_monsters_file:
    push rax
    push rbx
    push rcx
    push rdx
    push r15
    push r14

    mov r15, 0
    .outer:
        cmp r15, sprite_size
        jge .outer_end
        
        mov r14, 0
        @@:
            cmp r14, sprite_width
            jge @f

            mov rcx, r15
            imul rcx, sprite_width
            add rcx, r14
            imul rcx, 4
            mov rbx, 0
            mov dl, [monster_sprite_file+rcx]
            mov bl, dl
            mov dl, [monster_sprite_file+rcx+1]
            mov bh, dl
            mov dl, [monster_sprite_file+rcx+2]
            shl edx, 16
            add ebx, edx
            mov dl, [monster_sprite_file+rcx+3]
            shl edx, 24
            add ebx, edx

            mov rcx, r15
            imul rcx, sprite_width
            add rcx, r14
            mov [sprites+8*rcx], rbx

            inc r14
            jmp @b
        @@:

        inc r15
        jmp .outer
    .outer_end:

    pop r14
    pop r15
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

animate:
    push rax
    push rdi
    push r15
    
    mov r15, 0
    @@:
        cmp r15, 1
        jge @f

        mov rax, clear_color
        call fill_frame_buffer
        call draw_map
        call draw_player
        call draw_visibility_cone
        call draw_enemies_map
        call draw_sprites
        mov rax, 3
        call draw_sprite

        mov rax, r15
        call generate_animation_path

        lea rdi, [animation_path]
        call write_to_file

        fld [player_a]
        fldpi
        fild_imm 180
        fdivp st1, st0
        faddp st1, st0
        fstp [player_a]
        inc r15
        jmp @b
    @@:

    pop r15
    pop rdi
    pop rax
    ret

draw_sprites:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push r15
    push r14
    push r13
    push r8

    mov r15, 0
    @@:
        cmp r15, 3
        jge @f

        mov rax, r15
        imul rax, sizeof.Sprite
        add rax, 8*1
        fld qword [monsters + rax]
        fld qword [player_y]
        fsubp
        
        mov rax, r15
        imul rax, sizeof.Sprite
        add rax, 8*0
        fld qword [monsters + rax]
        fld qword [player_x]
        fsubp

        fpatan
        .loopsub:
            ; loop and subtract 2pi
            fld st0
            fld qword [player_a]
            fsubp
            fldpi
            fcompp
            fstsw ax ; copy the Status Word containing the result to AX
            fwait
            sahf ; transfer the condition codes to the CPU's flag register
            jpe float_error_handler
            jnb .endsub
            fldpi
            fldpi
            faddp
            fsubp
            jmp .loopsub
        .endsub:
        .loopadd:
            ; loop and add 2pi
            fld st0
            fld qword [player_a]
            fsubp
            fldpi
            fchs
            fcompp
            fstsw ax ; copy the Status Word containing the result to AX
            fwait
            sahf ; transfer the condition codes to the CPU's flag register
            jpe float_error_handler
            jb .endadd
            fldpi
            fldpi
            faddp
            faddp
            jmp .loopadd
        .endadd:
        ; st0 is now sprite_dir
        fld [player_x]
        mov rax, r15
        imul rax, sizeof.Sprite
        add rax, 8*0
        fld qword [monsters + rax]
        fsubp
        fld st0
        fmulp
        fld [player_y]
        mov rax, r15
        imul rax, sizeof.Sprite
        add rax, 8*1
        fld qword [monsters + rax]
        fsubp
        fld st0
        fmulp
        faddp
        fsqrt ; sprite_dist
        ; st0 is sprite_dist, st1 is sprite_dir
        fild_imm view_h
        fxch
        fdivp
        fistp_reg rax
        cmp rax, 2000
        jl .min_done
        .min1000:
            mov rax, 2000
        .min_done:
        ; st0 is sprite_dir, rax is sprite_screen_size
        fld [player_a]
        fsubp
        fild_imm (view_w)
        fmulp
        fld_imm player_fov
        fdivp
        fistp_reg rbx
        add rbx, (view_w)/2
        mov rcx, rax
        shr rcx, 1
        sub rbx, rcx
        neg rcx
        add rcx, view_h/2
        ; rax is sprite_screen_size, rbx is h_offset, rcx is v_offset

        mov r14, 0
        .h_loop:
            cmp r14, rax
            jge .h_end

            mov rdx, rbx
            add rdx, r14
            cmp rdx, 0
            jl .h_continue
            cmp rdx, view_w
            jge .h_continue

            add rdx, view_w

            mov r13, 0
            .v_loop:
                cmp r13, rax
                jge .v_end

                mov rdi, rcx
                add rdi, r13
                cmp rdi, 0
                jl .v_continue
                cmp rdi, view_h
                jge .v_continue

                imul rdi, win_w
                add rdi, rdx
                ; (view_w + h_offset+r14)+(v_offset+r13)*win_w
                mov [frame_buffer + 8*rdi], black

            .v_continue:
                inc r13
                jmp .v_loop
            .v_end:

        .h_continue:
            inc r14
            jmp .h_loop
        .h_end:

        inc r15
        jmp @b
    @@:

    pop r8
    pop r13
    pop r14
    pop r15
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

draw_enemies_map:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    push r15

    mov r15, 0
    @@:
        cmp r15, monsters_count
        jge @f

        mov rax, r15
        imul rax, sizeof.Sprite
        add rax, 8*0
        fld qword [monsters + rax]
        sub rsp, 8 ; allocate 8 bytes for a variable
        mov qword [rsp], rect_w
        fimul dword [rsp]
        fistp qword [rsp]
        pop rax
        mov rbx, r15
        imul rbx, sizeof.Sprite
        add rbx, 8*1
        fld qword [monsters + rbx]
        sub rsp, 8 ; allocate 8 bytes for a variable
        mov qword [rsp], rect_w
        fimul dword [rsp]
        fistp qword [rsp]
        pop rbx
        mov rcx, 5
        mov rdx, 5
        mov rdi, monster_color
        call draw_rectangle

        inc r15
        jmp @b
    @@:

    pop r15
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

draw_texture:
    push rax
    push rbx
    push rcx
    push rdx
    push r15
    push r14

    mov r15, 0
    .outer:
        cmp r15, texture_size
        jge .outer_end
        
        mov r14, 0
        @@:
            cmp r14, texture_size
            jge @f

            mov rcx, r15
            imul rcx, texture_width
            add rcx, r14
            mov rbx, rax
            imul rbx, texture_size
            add rcx, rbx
            mov rbx, [textures+8*rcx]

            mov rcx, r15
            imul rcx, win_w
            add rcx, r14
            mov [frame_buffer+8*rcx], rbx

            inc r14
            jmp @b
        @@:

        inc r15
        jmp .outer
    .outer_end:

    pop r14
    pop r15
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

draw_sprite:
    push rax
    push rbx
    push rcx
    push rdx
    push r15
    push r14

    mov r15, 0
    .outer:
        cmp r15, sprite_size
        jge .outer_end
        
        mov r14, 0
        @@:
            cmp r14, sprite_size
            jge @f

            mov rcx, r15
            imul rcx, sprite_width
            add rcx, r14
            mov rbx, rax
            imul rbx, sprite_size
            add rcx, rbx
            mov rbx, [sprites+8*rcx]
            ; if alpha channel is 0, don't draw pixel
            cmp rbx, 0x00FFFFFF ; this is a hacky way of checking it
            je .continue        ; since technically the color part of
                                ; the image could be anything

            mov rcx, r15
            imul rcx, win_w
            add rcx, r14
            mov [frame_buffer+8*rcx], rbx

        .continue:
            inc r14
            jmp @b
        @@:

        inc r15
        jmp .outer
    .outer_end:

    pop r14
    pop r15
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

generate_animation_path:
    push r15
    push r14
    push rdx
    push rax

    mov r15, animation_path+animation_path.idx_start
    @@: ; loop begin
        cmp rax, 0
        je @f
        xor rdx, rdx
        mov r14, 10
        div r14
        add rdx, '0'
        mov [r15], dl
        dec r15
        jmp @b
    @@: ; loop end
    pop rax
    pop rdx
    pop r14
    pop r15
    ret

draw_visibility_cone:
    push r15
    push rax
    sub rsp, 8*1
    define .angle   rsp+8*0

    mov r15, 0
    @@: ; loop begin
        cmp r15, view_w
        jge @f
        
        fld qword [player_a]
        fld_imm player_fov
        fild_imm 2
        fdivp st1, st0
        fsubp st1, st0
        fld_imm player_fov
        fild_imm r15
        fild_imm view_w
        fdivp st1, st0
        fmulp st1, st0
        faddp
        fstp qword [.angle]
        mov rax, [.angle]
        call draw_ray

        inc r15
        jmp @b
    @@: ; loop end

    add rsp, 8*1
    pop rax
    pop r15
    ret

; expects the angle in rax as a 64 bit float
draw_ray:
    push rax
    push rbx
    push rcx
    push rdx
    push r15
    sub rsp, 8*6
    define .angle           rsp+8*5
    define .loop_iterator   rsp+8*4
    define .loop_end        rsp+8*3
    define .loop_step       rsp+8*2
    define .pos_x           rsp+8*1
    define .pos_y           rsp+8*0
    mov [.angle], rax
    mov rax, 0.0
    mov [.loop_iterator], rax
    mov rax, 20.0
    mov [.loop_end], rax
    mov rax, 0.01
    mov [.loop_step], rax
    

    @@: ; loop begin
        fld qword [.loop_iterator]
        fld qword [.loop_end]
        fcomp ; compare ST0 and ST1 which are 20.0 and 0.0 respectively
        fstp qword [.loop_iterator]
        fstsw ax ; copy the Status Word containing the result to AX
        fwait
        sahf ; transfer the condition codes to the CPU's flag register
        jpe float_error_handler
        jb @f

        ; pos_x = player_x + .loop_iterator*cos(.angle);
        fld qword [.angle]
        fcos
        fmul qword [.loop_iterator]
        fadd [player_x]
        fstp qword [.pos_x]
        
        ; pos_y = player_y + .loop_iterator*sin(.angle);
        fld qword [.angle]
        fsin
        fmul qword [.loop_iterator]
        fadd [player_y]
        fstp qword [.pos_y]

        mov rax, qword [.pos_y]
        cast_float_to_int rax, qword [.pos_y]
        imul rax, map_w
        cast_float_to_int rbx, qword [.pos_x]
        add rax, rbx
        mov al, [map+rax]
        cmp al, ' '
        je .continue
            mov cl, al
            mov rax, r15 ; r15 is the iterator in draw_visibility_cone
            mov rbx, qword [.loop_iterator]
            mov rdx, qword [.angle]
            mov r8, qword [.pos_x]
            mov r9, qword [.pos_y]
            call draw_vertical_segment
            jmp @f
        .continue:

        fld qword [.pos_x]
        fimul_imm rect_w
        fld qword [.pos_y]
        fimul_imm rect_w
        fistp_reg rbx
        fistp_reg rax
        imul rbx, win_w
        add rax, rbx
        mov [frame_buffer+8*rax], ray_color

        fld qword [.loop_iterator]
        fadd qword [.loop_step]
        fstp qword [.loop_iterator]
        jmp @b
    @@: ; loop end

    add rsp, 8*6
    pop r15
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

draw_vertical_segment:
    push r8  ; pos_x : double
    push r9  ; pos_y : double
    push rax ; rax is the iterator in draw_visibility_cone
    push rbx ; dist : double
    push rcx ; wall_type : char
    push rdx ; angle : double
    push rdi
    push r15 

    sub rsp, 8*2
    define .hit_x           rsp+8*1
    define .hit_y           rsp+8*0

    mov qword [.hit_x], r8
    mov qword [.hit_y], r9

    fld qword [.hit_x]
    fld st0
    fld_imm 0.5
    faddp
    frndint
    fsubp st1, st0
    fld st0
    fstp qword [.hit_x]
    fabs
    fld qword [.hit_y]
    fld st0
    fld_imm 0.5
    faddp
    frndint
    fsubp st1, st0
    fld st0
    fstp qword [.hit_y]
    fabs
    mov rdi, rax
    fcompp
    fstsw ax ; copy the Status Word containing the result to AX
    fwait
    sahf ; transfer the condition codes to the CPU's flag register
    mov rax, rdi
    jpe float_error_handler
    jb .hit_x_greater
    .hit_y_greater:
        fld qword [.hit_y]
        jmp .continue
    .hit_x_greater:
        fld qword [.hit_x]
    .continue:
    fild_imm texture_size
    fmulp st1, st0
    fistp_reg rdi
    cmp rdi, 0
    jge .x_texcoord_ge
        add rdi, texture_size
    .x_texcoord_ge:

    ; view_h dist*(ang-play_a)

    fild_imm view_h
    fld_imm rbx
    fld_imm rdx
    fld qword [player_a]
    fsubp st1, st0
    fcos
    fmulp st1, st0
    fdivp st1, st0
    fistp_reg r15 ; segment_height : int

    add rax, view_w ; pix_x

    sub cl, '0'
    imul rcx, texture_size
    add rcx, rdi

    mov r9, 0
    @@:
        cmp r9, r15
        jge @f

        mov rbx, r15
        shr rbx, 1
        neg rbx
        add rbx, view_h/2
        add rbx, r9
        cmp rbx, 0
        jl .continue_for
        cmp rbx, view_h
        jge .continue_for

        mov r8, rax
        mov rax, r9
        imul rax, texture_size
        mov rdx, 0 ; TODO division is weird, make sure you don't fuck this up anywhere
        div r15 ; clobbers rdx
        imul rax, texture_width
        add rax, rcx
        mov rax, [textures+8*rax]
        xchg rax, r8

        imul rbx, win_w
        add rbx, rax
        mov [frame_buffer+8*rbx], r8

    .continue_for:
        inc r9
        jmp @b
    @@:

    add rsp, 8*2

    pop r15
    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop r9
    pop r8
    ret

draw_player:
    push rax
    push rbx
    push rcx
    push rdx
    push rdi

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

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    ret

draw_map:
    push r15
    push r14
    push rax
    push rbx
    push rcx
    push rdx
    push rdi
    mov r15, 0
    .outer:
        cmp r15, map_h
        jge .outer_end
        mov r14, 0
        @@: ; loop begin
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

            sub al, '0'
            imul rax, texture_size
            mov rdi, [textures+8*rax]
            mov rax, r14
            imul rax, rect_w
            mov rbx, r15
            imul rbx, rect_h
            mov rcx, rect_w
            mov rdx, rect_h

            call draw_rectangle

            inc r14
            jmp @b
        @@: ; loop end
        inc r15
        jmp .outer
    .outer_end:

    pop rdi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    pop r14
    pop r15
    ret

draw_rectangle:
    push r15
    push r14
    push rax ; horizontal position
    push rbx ; vertical position
    push rcx ; width
    push rdx ; height
    push rdi ; color
    push r10
    push r11
    mov r10, rax
    mov r11, rbx

    mov r15, 0
    .outer:
        cmp r15, rcx
        jge .outer_end
        mov r14, 0
        @@: ; loop begin
            cmp r14, rdx
            jge @f

            mov rax, r10
            add rax, r15
            mov rbx, r11
            add rbx, r14
            imul rbx, win_w
            add rax, rbx

            cmp rax, frame_buffer_size
            jge @f

            mov [frame_buffer+8*rax], rdi

            inc r14
            jmp @b
        @@: ; loop end
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
    push rcx ; rcx and r11 get clobbered by syscall
    push r11

    ; TODO: handle printing 0

    mov [int_buf+63], 0
    mov [int_buf+62], 10
    mov r15, 61
    @@: ; loop begin
        cmp rax, 0
        je @f
        xor rdx, rdx
        mov r14, 10
        div r14
        add rdx, '0'
        mov [int_buf+r15], dl
        dec r15
        jmp @b
    @@: ; loop end
    inc r15
    mov rdi, 1
    lea rsi, [int_buf+r15]
    mov rdx, 63
    sub rdx, r15
    mov rax, sys_write
    syscall

    pop r11
    pop rcx
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
    push rcx ; rcx and r11 get clobbered by syscall
    push r11

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

    pop r11
    pop rcx
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
    @@: ; loop begin
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
    @@: ; loop end
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
        cmp r15, view_h
        jge .outer_end
        mov r14, 0
        @@: ; loop begin
            cmp r14, win_w
            jge @f

            mov rax, r15
            imul rax, 255
            mov rbx, view_h
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
        @@: ; loop end
        inc r15
        jmp .outer
    .outer_end:

    pop rdx
    pop rbx
    pop r13
    pop r14
    pop r15
    ret

fill_frame_buffer:
    push r15
    push r14
    push rbx

    mov r15, 0
    .outer:
        cmp r15, view_h
        jge .outer_end
        mov r14, 0
        @@: ; loop begin
            cmp r14, win_w
            jge @f

            mov rbx, r15
            imul rbx, win_w
            add rbx, r14
            mov [frame_buffer+8*rbx], rax

            inc r14
            jmp @b
        @@: ; loop end
        inc r15
        jmp .outer
    .outer_end:

    pop rbx
    pop r14
    pop r15
    ret


float_error_handler:
    puts_static float_error_msg
    mov rdi, 1 ; set exit code to 1
    mov rax, sys_exit
    syscall

segment readable writeable ; data
    ; structures
    struc Sprite {
        .x dq ?
        .y dq ?
        .tex_id dq ?
    }
    virtual at 0
        Sprite Sprite
        sizeof.Sprite = $ - Sprite
    end virtual

    ; constants
    win_w = 1024
    win_h = 512
    view_w = win_w/2
    view_h = win_h
    frame_buffer_size = win_h*win_w
    ppm_buffer_size = frame_buffer_size*3

    ; variables
    monsters_count = 3
    monsters db sizeof.Sprite*monsters_count dup(?)
    monster_color = red

    frame_buffer rq frame_buffer_size ; 1024*512
    int_buf rb 64
    int_buf.size = $ - int_buf
    ppm_buffer rb ppm_buffer_size ; 1024*512*3
    
    map_w = 16
    map_h = 16
    map db "0000222222220000",\
           "1              0",\
           "1      11111   0",\
           "1     0        0",\
           "0     0  1110000",\
           "0     3        0",\
           "0   10000      0",\
           "0   3   11100  0",\
           "5   4   0      0",\
           "5   4   1  00000",\
           "0       1      0",\
           "2       1      0",\
           "0       0      0",\
           "0 0000000      0",\
           "0              0",\
           "0002222222200000"
    map.size = $ - map

    rect_w = win_w / (map_w*2)
    rect_h = view_h / map_h
    rect_color = cyan
    wall_colors dd light_beige, dark_purple, dark_blue, dark_red
    wall_colors.length = $ - wall_colors

    player_x dq 3.456
    player_y dq 2.345
    player_w = 5
    player_h = 5
    player_a dq 1.523
    player_fov = 1.0471975512 ; PI/3
    player_color = white

    clear_color = white
    ray_color = grey

    image_file_path db 'image_file.ppm', 0
    image_file_path.size = $ - image_file_path - 1
    animation_path db 'animation_file_000.ppm', 0
    animation_path.size = $ - animation_path - 1
    animation_path.idx_start = $ - animation_path - 6
    ppm_header db 'P6', 10, '1024 512', 10, '255', 10, 0
    ppm_header.size = $ - ppm_header - 1

    float_error_msg db '[ERROR]: floating point error, crashing\n', 0
    float_error_msg.size = $ - float_error_msg - 1

    wall_texture_file file 'walltext.ppm':0x0E
    texture_size  = 64
    texture_cnt   = 6
    texture_width = texture_size*texture_cnt
    textures rq texture_size*texture_width

    monster_sprite_file file 'monsters.pam':0x44
    sprite_size   = 64
    sprite_cnt    = 4
    sprite_width  = sprite_size*sprite_cnt
    sprites rq sprite_size*sprite_width

    debug_str db '[DEBUG]: ', 0
    debug_str.size = $ - debug_str - 1
    