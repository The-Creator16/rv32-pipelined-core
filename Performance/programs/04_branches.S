# Always-taken prediction: backward loop, forward taken branches,
# four forward not-taken branches, and JAL/JALR redirects
    addi x1, x0, 8
    addi x2, x0, 0
loop:
    addi x2, x2, 1
    addi x1, x1, -1
    bne x1, x0, loop
    beq x2, x0, poison
    beq x2, x0, poison
    beq x2, x0, poison
    beq x2, x0, poison
    beq x0, x0, taken1
    sw x2, 512(x0)
taken1:
    beq x0, x0, taken2
    sw x2, 516(x0)
taken2:
    jal x6, after_jal
    sw x2, 520(x0)
    sw x2, 524(x0)
after_jal:
    addi x7, x0, 80
    jalr x8, 0(x7)
    sw x2, 528(x0)
    sw x2, 532(x0)
after_jalr:
    sw x2, 256(x0)
finish:
    addi x31, x0, 123

# Padding is outside the measured stream; prevents tail side effects
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
    addi x0, x0, 0
poison:
    sw x2, 536(x0)
    addi x2, x0, -1
