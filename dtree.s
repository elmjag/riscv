    .global _start
    .section .text.bios

_start:
    la sp, _stack      # set-up stack pointer

    li a0, 0xff12abcd
    li a1, 8
    call print_hex

    li a0, 0xff121234
    li a1, 4
    call print_hex

    j loopy

    li a0, 0xab
    call print_hex

    la a0, foo
    call println

    la a0, bar
    call println


loopy:
    j loopy


foo:
    .hword 11
    .ascii "hello there"

bar:
    .hword 22
    .ascii "don't push the horses"

#
# nibble_to_ascii()
#
nibble_to_ascii:
    and a0, a0, 0x0f  # mask higher bits
    li t0, 0x9
    bgt a0, t0, _big_nibble_to_ascii
    addi a0, a0, '0'
    ret
_big_nibble_to_ascii:
    addi a0, a0, 87
    ret


#
# print_hex()
#
# a0 - value to print
# a1 - bytes to print
#
print_hex:

    addi sp, sp, -8       # push ra to the stack
    sd ra, (sp)

    mv s1, a0             # s1 - value to print_hex
    slli s2, a1, 1        # s2 - number of nibbles to print
    la s3, _print_hex_buf # s3 - string buffer pointer
    add t0, s2, 2         # set string length
    sh t0, (s3)

_print_hex_loop:
    mv a0, s1
    call nibble_to_ascii

    la t0, _print_hex_buf
	add t0, t0, s2
    sb a0, 3(t0)

    addi s2, s2, -1
    beq s2, zero, _print_hex_done

    srli s1, s1, 4
    j _print_hex_loop

_print_hex_done:

    la a0, _print_hex_buf
    call println

    ld ra, (sp)           # pop ra from the stack
    addi sp, sp, 8

	ret

_print_hex_buf:
    .hword 4
    .ascii "0x????????????????"

#
# println()
#

println:
    addi t0, a0, 2     # t0 - string start address
    lhu t1, (a0)       # read string length
    add t1, t0, t1     # t1 - string end address

    li a0, 0x10000000  # UART THR register

_println_loop:
    lb t2, (t0)
    sb t2, (a0)

    addi t0, t0, 1
    beq t0, t1, _println_done
    j _println_loop

_println_done:
    li t2, '\n'
    sb t2, (a0)

    ret

_stack_end:
    .zero 1024
_stack:
    .byte 0xaa, 0xbb, 0xcc, 0xdd  # marker, for debugging
