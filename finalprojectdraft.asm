.data
boarding_list:      	.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding.txt"

boarding_locations: 	.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_locations.txt"
locations_master:		.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/locations_master.txt"
locations_bufferlist:	.space 1024



price_master: 			.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_price.txt"
price_buffer:	 		.space 4096

read_buffer:			.space 2048
name_buffer:			.space 1024
line_buffer:       		.space 1024           # One line from file
delimiter:         		.byte '|'            # Name delimiter
filtered_dorm1:			.space 2048
filtered_dorm2:			.space 2048
filtered_dorm3:			.space 2048
filtered_dorm4:			.space 1024

prompt_location:    	.asciiz "Enter location to search: "
prompt_maxbudget:		.asciiz "Enter max budget: "
no_match_msg:       	.asciiz "\nNo matching dormitories.\n"
error_open_locations:	.asciiz "Error openning the file where locations are placed"
error_open_price:		.asciiz "Error openning the file where prices are placed"
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

copy_location_loop:
    lb $t5, 0($t1)            # Load byte from source (at $t1)
    beq $t5, 10, end_copy      # Check if it's newline ('\n', ASCII 10)
    beqz $t5, end_copy         # Check if it's null terminator ('\0')
    sb $t5, 0($s1)             # Store byte at destination (at $t2)
    addi $s1, $s1, 1           # Move destination pointer forward
    addi $t1, $t1, 1           # Move source pointer forward
    j copy_location_loop        # Repeat the loop

skip_line:
	lb $t3, 0 ($t1)
	beqz $t3, end_copy
	beq $t3, 10, advance_location
	add $t1, $t1 1
	j skip_line
	
advance_location:
	addi $t1, $t1, 1
	j search_loop
	
end_copy:
    sb $zero, 0($s1)
	li $v0, 4
	la $a0, filtered_dorm1
	syscall
	
	li $v0, 10
	syscall	
#######################################################
#    Function : Filters the boarding house by price	  #
#######################################################
second_filter:
	li $v0, 4
	la $a0, prompt_maxbudget
	syscall
	
	li $v0,5
	syscall
	move $t0, $v0
	
	
	




close_file:
	li $v0, 16
	move $a0, $s0
	syscall
	
	jr $ra
	