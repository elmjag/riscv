    .global _start
    .section .text.bios

_start:
    la sp, _stack      # set-up stack pointer

    mv a0, a1
    call dump_dtb

loopy:
    j loopy


#
# dump_dtb()
#
# print device tree blob (DTB) to serial console
#
# a0 - pointer to DTB
#

dump_dtb:
    addi sp, sp, -16    # push ra, s0 to the stack
    sd ra, 0(sp)
    sd s0, 8(sp)

    mv s0, a0           # s0 - pointer to DTB

    #
    # print DTB magic
    #

    la a0, _dump_dtb_magic
    call print

    lw a0, (s0)
    call ntohl

    li a1, 4
    call print_hex

    ld ra, 0(sp)        # pop ra, s0 from the stack
    ld s0, 8(sp)
    addi sp, sp, 16

    ret

_dump_dtb_magic:
    .hword 7
    .ascii "magic: ?"  # without the ? wierd code is generated(!?)

#
# uint32_t ntohl(uint32_t netlong);
#
#
ntohl:
    mv t0, a0   # t0 - value t convert
    li t1, 4    # t1 - conversions steps
    mv a0, zero # a0 - result

_ntohl_loop:

    andi t2, t0, 0xff
    add a0, a0, t2

    addi t1, t1, -1
    beqz t1, _ntohl_done

    srli t0, t0, 8
    slli a0, a0, 8

    j _ntohl_loop

_ntohl_done:

    ret

#
# nibble_to_ascii()
#
# a0 - value
#
# return
#
# a0 - ascii code for lowest nibble
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

    addi sp, sp, -24      # push registers to the stack
    sd ra, (sp)
    sd s1, 8(sp)
    sd s2, 16(sp)

    mv s1, a0             # s1 - value to print
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

    ld ra, (sp)           # pop registers from the stack
    ld s1, 8(sp)
    ld s2, 16(sp)
    addi sp, sp, 24

	ret

_print_hex_buf:
    .hword 4
    .ascii "0x????????????????"

#
# print()
#

print:
    addi t0, a0, 2     # t0 - string start address
    lhu t1, (a0)       # read string length
    add t1, t0, t1     # t1 - string end address

    li a0, 0x10000000  # UART THR register

_print_loop:
    lb t2, (t0)
    sb t2, (a0)

    addi t0, t0, 1
    beq t0, t1, _print_done
    j _print_loop

_print_done:
    ret

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
