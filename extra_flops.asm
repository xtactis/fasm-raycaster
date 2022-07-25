
macro cast_float_to_int dst*, src* {
    push src
    fld qword [rsp]
    fistp qword [rsp]
    pop dst
}

macro fstp_reg reg* {
    sub rsp, 8
    fstp qword [rsp]
    pop reg
}

macro fistp_reg reg* {
    sub rsp, 8
    fistp qword [rsp]
    pop reg
}

macro fld_imm value* {
    push rax
    mov rax, value
    push rax
    fld qword [rsp]
    add rsp, 8
    pop rax
}

macro fild_imm value* {
    push rax
    mov rax, value
    push rax
    fild qword [rsp]
    add rsp, 8
    pop rax
}

macro fmul_imm value* {
    push qword value
    fmul qword [rsp]
    add rsp, 8
}

macro fimul_imm value* {
    push qword value
    fild qword [rsp]
    fmulp
    add rsp, 8
}
