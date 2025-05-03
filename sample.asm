.data
filtered_dorm1: .asciiz "Sunny Board|Cozy Stay|Morning Dew Lodge|Urban Haven|Serene Nights"
price_master: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_price.txt"
filtered_dorm2: .space 1024
name_buffer1: .space 1024
name_buffer2: .space 1024
line_buffer: .space 1024
price_buffer: .space 256

match: .asciiz "Match"
no_match: .asciiz "No match"
newline: .asciiz "\n"
label1: .asciiz "First char of filtered_dorm1: "
label2: .asciiz "First char of price file: "
moveOn: .asciiz "Move to the next filtered dorm"
stored: .asciiz "Stored"
notStored: .asciiz "Not Stored"

.text
.globl main
main:
    # Open the price file
    li $v0, 13
    la $a0, price_master
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0

    # Read file line
    li $v0, 14
    move $a0, $s0
    la $a1, line_buffer
    li $a2, 1024
    syscall

    # Close file
    li $v0, 16
    move $a0, $s0
    syscall

    # Set up pointers
    la $t1, line_buffer      # file
    la $t2, filtered_dorm1   # string
    la $t3, name_buffer1     # filtered_dorm1 buffer

# Extract from filtered_dorm1 to name_buffer1
copy_dorm1:
    lb $t5, 0($t2)
    beq $t5, 124, end_dorm1
    sb $t5, 0($t3)
    addiu $t2, $t2, 1
    addiu $t3, $t3, 1
    j copy_dorm1

end_dorm1:
    sb $zero, 0($t3)

# Extract from line_buffer to name_buffer2
copy_price:
    la $t4, name_buffer2

copy_price_loop:
    lb $t6, 0($t1)
    beq $t6, 124, end_price
    beq $t6, 10, end_price
    beqz $t6, end_price
    sb $t6, 0($t4)
    addiu $t1, $t1, 1
    addiu $t4, $t4, 1
    j copy_price_loop

end_price:
    sb $zero, 0($t4)

# Compare name_buffer1 and name_buffer2
compare_loop:
    la $t3, name_buffer1
    la $t4, name_buffer2

compare_names:
    lb $t5, 0($t3)
    lb $t6, 0($t4)
    bne $t5, $t6, not_match
    beqz $t5, match_label
    addiu $t3, $t3, 1
    addiu $t4, $t4, 1
    j compare_names

match_label:
    la $t7, price_buffer
    addiu $t1, $t1, 1

extract_price:
    lb $t6, 0($t1)
    beq $t6, 10, convert_atoi
    beqz $t6, convert_atoi
    sb $t6, 0($t7)
    addiu $t1, $t1, 1
    addiu $t7, $t7, 1
    j extract_price

convert_atoi:
    sb $zero, 0($t7)
    la $t7, price_buffer
    li $t9, 0

str2int:
    lb $t6, 0($t7)
    beqz $t6, compare_price
    li $t3, '0'
    li $t4, '9'
    blt $t6, $t3, compare_price
    bgt $t6, $t4, compare_price
    sub $t6, $t6, $t3
    mul $t9, $t9, 10
    add $t9, $t9, $t6
    addiu $t7, $t7, 1
    j str2int

compare_price:
    li $t8, 3000
    ble $t9, $t8, store_filter_dorm2
    j next_item

store_filter_dorm2:
    la $s0, filtered_dorm2
    la $t3, name_buffer1

store_name_filter2:
    lb $t5, 0($t3)
    beqz $t5, next_item
    sb $t5, 0($s0)
    addi $s0, $s0, 1
    addi $t3, $t3, 1
    j store_name_filter2

not_match:
skip_to_next_line:
    lb $t5, 0($t1)
    beqz $t5, next_item
    beq $t5, 10, prepare_next_line
    addiu $t1, $t1, 1
    j skip_to_next_line

prepare_next_line:
    addiu $t1, $t1, 1
    j copy_price
    j compare_loop

next_item:
	li $v0, 4
	la $a0, filtered_dorm2
	syscall
	
	li $v0, 10
	syscall