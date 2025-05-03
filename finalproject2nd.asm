.data
boarding_locations: 	.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_locations.txt"
locations_master:		.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/locations_master.txt"
locations_bufferlist:	.space 1024

price_master: 			.asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_price.txt"
price_buffer:			.space 1024

read_buffer:			.space 2048
name_buffer1:			.space 2048
name_buffer2:			.space 1024
line_buffer:       		.space 1024 

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
    lb $t5, 0($t1)             # Load byte from source (at $t1)
    beq $t5, 10, end_copy      # Check if it's newline ('\n', ASCII 10)
    beqz $t5, end_copy         # Check if it's null terminator ('\0')
    sb $t5, 0($s1)             # Store byte at destination (at $t2)
    addi $s1, $s1, 1           # Move destination pointer forward
    addi $t1, $t1, 1           # Move source pointer forward
    j copy_location_loop       # Repeat the loop

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
	
    # Open the price file
    li $v0, 13
    la $a0, price_master
    li $a1, 0
    li $a2, 0
    syscall
    move $s0, $v0  # File descriptor

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
    la $t1, line_buffer     # File data
    la $t2, filtered_dorm1  # Filtered dorms list

# Extract name from filtered_dorm1 into name_buffer1

copy_dorm1:
    la $t3, name_buffer1  # Initialize buffer pointer  
    
copy_dorm1_loop:
    lb $t5, 0($t2)
    beq $t5, 124, end_dorm1  # Stop at '|' delimiter
    beqz $t5, end_dorm1      # Stop at null terminator
    sb $t5, 0($t3)
    addiu $t2, $t2, 1
    addiu $t3, $t3, 1
    j copy_dorm1_loop  # Corrected jump back to loop

end_dorm1:
    sb $zero, 0($t3)  # Null-terminate extracted name


# Extract name from line_buffer into name_buffer2
copy_price:
    la $t4, name_buffer2  # Destination buffer

copy_price_loop:
    lb $t6, 0($t1)
    beq $t6, 124, end_price  # Stop at '|'
    beq $t6, 10, end_price   # Stop at newline
    beqz $t6, end_price      # Stop at null terminator
    sb $t6, 0($t4)
    addiu $t1, $t1, 1
    addiu $t4, $t4, 1
    j copy_price_loop

end_price:
    sb $zero, 0($t4)  # Null-terminate extracted name

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
    la $t7, price_buffer  # Destination buffer
    addiu $t1, $t1, 1      # Move past '|'

extract_price:
    lb $t6, 0($t1)
    beq $t6, 10, convert_atoi
    beqz $t6, convert_atoi
    sb $t6, 0($t7)
    addiu $t1, $t1, 1
    addiu $t7, $t7, 1
    j extract_price

convert_atoi:
    sb $zero, 0($t7)  # Null-terminate extracted price
    la $t7, price_buffer
    li $t9, 0  # Initialize accumulator

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
    ble $t9, $t0, store_filter_dorm2
    j next_item

store_filter_dorm2:
    # Locate the end of filtered_dorm2
    la $s0, filtered_dorm2  
find_end:
    lb $t6, 0($s0)
    beqz $t6, store_name_filter2  # Found end, proceed to store
    addiu $s0, $s0, 1  # Move forward
    j find_end  # Continue searching for the last stored position

store_name_filter2:
    la $t3, name_buffer1  # Source dorm name
    
store_loop:
    lb $t5, 0($t3)
    beqz $t5, terminate_store  # Stop at null terminator
    sb $t5, 0($s0)  # Append character to filtered_dorm2
    addiu $s0, $s0, 1
    addiu $t3, $t3, 1
    j store_loop  # Continue copying

terminate_store:    
    li $t6, '|'   # Add newline to separate entries
    sb $t6, 0($s0)
    addiu $s0, $s0, 1
    j next_item  # Proceed to next dorm

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

next_item:
    lb $t5, 0($t2)
    beqz $t5, print_result  # If end of dorm list, print result
    beq $t5, 124, move_to_next_name  # If '|', move to next dorm name
    
    addiu $t2, $t2, 1  # Move pointer forward
    j next_item

move_to_next_name:
    addiu $t2, $t2, 1  # Move past '|'
    j copy_dorm1       # Restart extraction

print_result:
	li $v0, 4
	la $a0, filtered_dorm2
	syscall	
	
    li $v0, 10
    syscall







close_file:
	li $v0, 16
	move $a0, $s0
	syscall
	
	jr $ra
	