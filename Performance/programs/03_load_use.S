# Eight immediate load-use pairs, eight scheduled loads, eight forwarded stores
    lw x1, 0(x0)
    addi x2, x1, 1
    lw x3, 0(x0)
    addi x4, x0, 0
    add x5, x3, x4
    sw x5, 128(x0)
    lw x1, 4(x0)
    addi x2, x1, 1
    lw x3, 4(x0)
    addi x4, x0, 1
    add x5, x3, x4
    sw x5, 132(x0)
    lw x1, 8(x0)
    addi x2, x1, 1
    lw x3, 8(x0)
    addi x4, x0, 2
    add x5, x3, x4
    sw x5, 136(x0)
    lw x1, 12(x0)
    addi x2, x1, 1
    lw x3, 12(x0)
    addi x4, x0, 3
    add x5, x3, x4
    sw x5, 140(x0)
    lw x1, 16(x0)
    addi x2, x1, 1
    lw x3, 16(x0)
    addi x4, x0, 4
    add x5, x3, x4
    sw x5, 144(x0)
    lw x1, 20(x0)
    addi x2, x1, 1
    lw x3, 20(x0)
    addi x4, x0, 5
    add x5, x3, x4
    sw x5, 148(x0)
    lw x1, 24(x0)
    addi x2, x1, 1
    lw x3, 24(x0)
    addi x4, x0, 6
    add x5, x3, x4
    sw x5, 152(x0)
    lw x1, 28(x0)
    addi x2, x1, 1
    lw x3, 28(x0)
    addi x4, x0, 7
    add x5, x3, x4
    sw x5, 156(x0)
finish:
    addi x31, x0, 123
