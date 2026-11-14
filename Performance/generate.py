#!/usr/bin/env python3
"""Small RV32I assembler and independent sequential oracle for four benchmarks.
Only the listed subset is supported; unknown instructions and uninitialized
register reads fail rather than silently producing an expected result.
"""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parent
MASK = 0xffffffff


def reg(s):
    assert s.startswith('x') and 0 <= int(s[1:]) < 32
    return int(s[1:])


def parse(text):
    labels, code = {}, []
    for line in text.splitlines():
        line = line.split('#')[0].strip()
        if not line:
            continue
        if line.endswith(':'):
            labels[line[:-1]] = 4 * len(code)
        else:
            code.append(line.replace(',', ' ').replace('(', ' ').replace(')', ' ').split())
    return labels, code


def assemble(labels, code):
    words = []
    for i, p in enumerate(code):
        op = p[0]
        if op == 'addi':
            rd, rs, imm = reg(p[1]), reg(p[2]), int(p[3], 0)
            assert -2048 <= imm < 2048
            word = ((imm & 4095) << 20) | (rs << 15) | (rd << 7) | 0x13
        elif op == 'add':
            word = (reg(p[3]) << 20) | (reg(p[2]) << 15) | (reg(p[1]) << 7) | 0x33
        elif op in ('lw', 'jalr'):
            rd, imm, rs = reg(p[1]), int(p[2], 0), reg(p[3])
            assert -2048 <= imm < 2048
            word = ((imm & 4095) << 20) | (rs << 15) | (rd << 7) | (0x2003 if op == 'lw' else 0x67)
        elif op == 'sw':
            rs2, imm, rs1 = reg(p[1]), int(p[2], 0), reg(p[3])
            assert -2048 <= imm < 2048
            imm &= 4095
            word = ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | 0x2023 | ((imm & 31) << 7)
        elif op in ('beq', 'bne'):
            imm = labels[p[3]] - i * 4
            assert imm % 2 == 0 and -4096 <= imm < 4096
            imm &= 8191
            word = ((imm >> 12) << 31) | (((imm >> 5) & 63) << 25) | (reg(p[2]) << 20) | (reg(p[1]) << 15) | ((op == 'bne') << 12) | (((imm >> 1) & 15) << 8) | (((imm >> 11) & 1) << 7) | 0x63
        elif op == 'jal':
            imm = labels[p[2]] - i * 4
            assert imm % 2 == 0 and -(1 << 20) <= imm < (1 << 20)
            imm &= (1 << 21) - 1
            word = ((imm >> 20) << 31) | (((imm >> 1) & 1023) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 255) << 12) | (reg(p[1]) << 7) | 0x6f
        else:
            raise ValueError(op)
        words.append(word)
    return words


def sext(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def interpret(words, stop_pc):
    # Decode machine words, not assembler tokens; do not model pipeline timing.
    regs, memory, trace, stores = [0] + [None] * 31, [i + 10 for i in range(1024)], [], []
    pc = branches = taken = jumps = 0
    def read(r):
        assert regs[r] is not None, f'Uninitialized x{r} at {pc:#x}'
        return regs[r]
    while len(trace) < 1000:
        assert pc % 4 == 0 and 0 <= pc // 4 < len(words)
        w = words[pc // 4]
        op, rd, rs1, rs2, f3 = w & 127, (w >> 7) & 31, (w >> 15) & 31, (w >> 20) & 31, (w >> 12) & 7
        nxt, value, dest = pc + 4, 0, 0
        if op == 0x13 and f3 == 0:
            dest, value = rd, read(rs1) + sext(w >> 20, 12)
        elif op == 0x33 and f3 == 0 and w >> 25 == 0:
            dest, value = rd, read(rs1) + read(rs2)
        elif op == 3 and f3 == 2:
            addr = (read(rs1) + sext(w >> 20, 12)) & MASK
            assert addr % 4 == 0 and addr < 4096
            dest, value = rd, memory[addr // 4]
        elif op == 0x23 and f3 == 2:
            imm = sext(((w >> 25) << 5) | ((w >> 7) & 31), 12)
            addr = (read(rs1) + imm) & MASK
            assert addr % 4 == 0 and addr < 4096
            memory[addr // 4] = read(rs2)
            stores.append((addr, read(rs2)))
        elif op == 0x63 and f3 in (0, 1):
            branches += 1
            condition = (read(rs1) == read(rs2)) == (f3 == 0)
            imm = sext(((w >> 31) << 12) | (((w >> 7) & 1) << 11) | (((w >> 25) & 63) << 5) | (((w >> 8) & 15) << 1), 13)
            if condition:
                taken += 1
                nxt = pc + imm
        elif op == 0x6f:
            jumps += 1
            imm = sext(((w >> 31) << 20) | (((w >> 12) & 255) << 12) | (((w >> 20) & 1) << 11) | (((w >> 21) & 1023) << 1), 21)
            dest, value, nxt = rd, pc + 4, pc + imm
        elif op == 0x67 and f3 == 0:
            jumps += 1
            dest, value, nxt = rd, pc + 4, (read(rs1) + sext(w >> 20, 12)) & ~1
        else:
            raise ValueError(f'Unsupported instruction {w:08x}')
        value &= MASK
        if dest:
            regs[dest] = value
        trace.append((pc, w, dest, value if dest else 0))
        if pc == stop_pc:
            return trace, stores, memory, dict(branches=branches, taken=taken, jumps=jumps)
        pc = nxt & MASK
    raise AssertionError('Reference timeout')


def main():
    manifest = []
    for source in sorted((ROOT / 'programs').glob('*.S')):
        labels, code = parse(source.read_text())
        words = assemble(labels, code)
        trace, stores, memory, counts = interpret(words, labels['finish'])
        name = source.stem
        def write(suffix, values):
            (ROOT / 'programs' / (name + suffix)).write_text(''.join(f'{v:08x}\n' for v in values))
        write('.hex', words + [0x13] * (1024 - len(words)))
        for index, suffix in enumerate(('.pc.hex', '.instr.hex', '.rd.hex', '.value.hex')):
            write(suffix, [row[index] for row in trace])
        write('.store_addr.hex', [x[0] for x in stores] or [0])
        write('.store_value.hex', [x[1] for x in stores] or [0])
        write('.memory.hex', memory)
        manifest.append(dict(name=name, words=len(words), stop_pc=labels['finish'], retired=len(trace), stores=len(stores), **counts))
    (ROOT / 'programs' / 'data.hex').write_text(''.join(f'{i+10:08x}\n' for i in range(1024)))
    (ROOT / 'programs' / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')

if __name__ == '__main__':
    main()
