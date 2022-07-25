macro puts_static string* {
    push rdx
    push rsi
    push rdi
    push rax
    push rcx ; rcx and r11 get clobbered by syscall
    push r11
    mov rdx, string#.size
    lea rsi, [string]
    mov rdi, 1          ; stdout
    mov rax, sys_write  ; sys_write
    syscall
    pop r11
    pop rcx
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

macro debug_freg st* {
    push rax
    sub rsp, 8
    fld st
    fstp qword [rsp]
    mov rax, qword [rsp]
    debug_reg rax
    add rsp, 8
    pop rax
}