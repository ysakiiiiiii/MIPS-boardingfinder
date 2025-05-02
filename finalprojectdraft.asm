.data
boarding_list:      	.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding.txt"

boarding_locations: 	.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_locations.txt"
locations_master:		.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/locations_master.txt"
locations_bufferlist:	.space 1024

name_token:				.space 1024

price_master: 			.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_price.txt"
price_buffer:	 		.space 4096

read_buffer:			.space 2048

filtered_dorm1:			.space 2048
filtered_dorm2:			.space 2048
filtered_dorm3:			.space 2048
filtered_dorm4:			.space 1024

prompt_location:    	.asciiz "Enter location to search: "
prompt_maxbudget:		.asciiz "Enter max budget: "
no_match_msg:       	.asciiz "\nNo matching dormitories.\n"
error_open_locations:	.asciiz "Error openning the file where locations are placed"
error_open_price:	.asciiz "Error openning the file where prices are placed"
newLine:            	.asciiz "\n"

.text
.globl main

main:
	#Open and print locations choice
	li $v0, 13
	la $a0, locations_master
	li $a1, 0
	syscall
	move $s0, $v0
	
	li $v0, 14
	move $a0, $s0
	la $a1, locations_bufferlist
	li $a2, 1024
	syscall
	
	li $v0, 4
	la $a0, locations_bufferlist
	syscall
	
	jal close_file
	
    # Prompt user for location
    li $v0, 4
    la $a0, prompt_location
    syscall
	
	#Get user input
    li $v0, 5
    syscall
    move $t0, $v0


#######################################################
#  Function : Filters the boarding house by location  #
#######################################################
open_extract_file:
    # Open the file
    li $v0, 13
    la $a0, boarding_locations
    li $a1, 0
    syscall
    move $s0, $v0        # file descriptor

read_next_line:
    # Read next line
    li $v0, 14
    move $a0, $s0
    la $a1, read_buffer
    li $a2, 2048
    syscall
    move $t9, $v0        # store read result size
    
    jal close_file
	
	la $t1, read_buffer
	la $s1, filtered_dorm1
	
search_loop:
    lb $t3, 0($t1)
    beqz $t3, end_copy
    
    subi $t4, $t3, 48
    
    bne $t4, $t0, skip_line
	addi $t1, $t1, 2

copy_loop:
    lb $t5, 0($t1)            # Load byte from source (at $t1)
    beq $t5, 10, end_copy      # Check if it's newline ('\n', ASCII 10)
    beqz $t5, end_copy         # Check if it's null terminator ('\0')
    sb $t5, 0($s1)             # Store byte at destination (at $t2)
    addi $s1, $s1, 1           # Move destination pointer forward
    addi $t1, $t1, 1           # Move source pointer forward
    j copy_loop                # Repeat the loop

skip_line:
	lb $t3, 0 ($t1)
	beqz $t3, second_filter
	beq $t3, 10, advance_location
	add $t1, $t1 1
	j skip_line
	
advance_location:
	addi $t1, $t1, 1
	j search_loop
	
end_copy:
    li $t5, 0
    sb $t5, 0($s1)
	
#######################################################
#    Function : Filters the boarding house by price	  #
#######################################################
second_filter:

	li $v0, 4
	la $a0, filtered_dorm1
	syscall  # Print dorm list before filtering

	jal load_file_price
	
	li $v0, 4
	la $a0, prompt_maxbudget
	syscall
	
	li $v0, 5
	syscall
	move $t0,$v0
	
	la $s1, filtered_dorm1
	la $s2, filtered_dorm2

next_name:
	la $t1, name_token
	li $t2, 0
	
extract_price_loop:
    lb $t4, 0($s1)
    beqz $t4, end_filter
    li $t5, '|'
    beq $t4, $t5, check_price
    sb $t4, 0($t1)
    addi $s1, $s1, 1
    addi $t1, $t1, 1
    j extract_price_loop


check_price:
    li $t3, 0
    sb $t3, 0($t1)  # Null-terminate extracted dorm name
    addi $s1, $s1, 1

    li $v0, 4
    la $a0, name_token
    syscall  # Debug print: Check extracted dorm name

    jal find_price  # Retrieve price

    bgt $v0, $t0, next_name  # If price exceeds budget, skip storing
    j store_name  # If within budget, store the dorm name

store_name:
	la $t1, name_token

copy_back:
	lb $t3, 0($t1)
	beqz $t3, add_delim
sb $t3, 0($s2)
addi $t1, $t1, 1
addi $s2, $s2, 1
j copy_back

add_delim:
    li $t3, '|'
    sb $t3, 0($s2)
    addi $s2, $s2, 1
    li $t3, 0  # Ensure NULL terminator
    sb $t3, 0($s2)

	
end_filter:
	li $t3, 0
	sb $t3, 0 ($s2)
	
	li $v0, 4
	la $a0, filtered_dorm2
	syscall
	
	li $v0, 10
	syscall

no_match:
	li $v0, 4
	la $a0,no_match_msg
	syscall
	
	li $v0, 10
	syscall
	
load_file_price:
	li $v0, 13
	la $a0, price_master
	li $a1, 0
	syscall
	bltz $v0, open_fail
	move $s0,  $v0
	
	li $v0, 14
	move $a0, $s0
	la $a1, price_buffer
	li $a2, 4096
	syscall
	
	li $v0 16
	move $a0, $s0
	syscall
	
	jr $ra

open_fail:
	li $v0, 4
	la $a0, error_open_price
	syscall
	
	li $v0, 10
	syscall

close_file:
	#Close the file
	li $v0, 16
	move $a0, $s0
	syscall
	
	jr $ra
	
#########################################################
# 	FUNCTION : FIND PRICE								#
#	INPUT: NAME_TOKEN									#
#########################################################
find_price:
	la $t5, price_buffer
	

find_line:
	la $t6, name_token

match_loop:
	lb $t7, 0($t6)
	lb $t8, 0 ($t5)
	beqz $t7, match_found
	beqz $t8, not_found
	bne $t7, $t8, skip_to_next_line
	addi $t5, $t5, 1
	addi $t6, $t6, 1
	j match_loop

match_found:
	lb $t9, 0($t5)
	li $t1, '|'

find_bar:
    bne $t9, $t1, continue_search
    j read_price
continue_search:
    addi $t5, $t5, 1
    lb $t9, 0($t5)
    j find_bar

read_price:
    li $v0, 0
read_digits:
    addi $t5, $t5, 1
    lb $t9, 0($t5)
    beqz $t9, done_price
    blt $t9, '0', done_price
    bgt $t9, '9', done_price
    li $t2, 10
    mul $v0, $v0, $t2
    subi $t9, $t9, 48
    add $v0, $v0, $t9
    j read_digits

done_price:
    jr $ra

skip_to_next_line:
    lb $t9, 0($t5)
    beqz $t9, not_found
    bne $t9, 10, advance_price
    addi $t5, $t5, 1
    j find_line
    
advance_price:
    addi $t5, $t5, 1
    j skip_to_next_line

not_found:
    li $v0, -1
    jr $ra

