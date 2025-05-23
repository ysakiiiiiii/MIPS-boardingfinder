###############################################################################
#                                                                             #
#                    SMART BOARDING HOUSE FINDER PROJECT                      #
#                                                                             #
# Description: This program helps users find boarding houses based on:        #
#              1. Location preference                                         #
#              2. Maximum budget                                              #
#              3. Nearby amenities/proximities                                #
#              4. Desired amenities                                           #
#                                                                             #
# File Structure:                                                             #
# - boarding_locations.txt: Maps dorm names to location IDs                   #
# - locations_master.txt: Lists available locations with IDs                  #
# - boarding_proximity.txt: Maps dorms to proximity IDs                       #
# - proximity_master.txt: Lists available proximities with IDs                #
# - boarding_price.txt: Maps dorms to their prices                            #
# - boarding_amenities.txt: Maps dorms to amenity IDs                         #
# - amenities_master.txt: Lists available amenities with IDs                  #
# - boarding_details.txt: Contains full details of each dormitory             #
#                                                                             #
# Filtering Process:                                                          #
# 1. Filter by location                                                       #
# 2. Filter by price (max budget)                                             #
# 3. Filter by proximity preferences                                          #
# 4. Filter by amenity preferences (optional)                                 #
#                                                                             #
# Data Format: All data files use '|' as delimiters between fields            #
#                                                                             #
###############################################################################

.data
# ============================= FILE PATHS ===================================
boarding_locations: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_locations.txt"
locations_master: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/locations_master.txt"
boarding_proximity: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_proximity.txt"
proximity_master: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/proximity_master.txt"
price_master: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_price.txt"
boarding_amenities: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_amenities.txt"
amenities_master: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/amenities_master.txt"
boarding_details: .asciiz "D:/MIPS-Assembly-Project-Smart Boarding/boarding_details.txt"

# ============================= DATA BUFFERS =================================
# Buffers for storing file contents
locations_bufferlist: .space 1024     # Stores locations master file
proximity_masterlist: .space 1024     # Stores proximity master file
amenities_masterlist: .space 1024     # Stores amenities master file

# Working buffers for processing
price_buffer: .space 1024             # Stores price data during filtering
amenities_buffer: .space 1024         # Stores amenities data during filtering
read_buffer: .space 4096              # General purpose read buffer (largest)
name_buffer1: .space 2048             # Primary name buffer for comparisons
name_buffer2: .space 1024             # Secondary name buffer for comparisons
line_buffer: .space 1024              # Buffer for reading individual lines
proximity_buffer: .space 32           # Stores proximity IDs during processing
amenities_temp_buffer: .space 32      # Temporary buffer for amenities processing
id_buffer: .space 32                  # Stores user input IDs
id_buffer_temp: .space 8              # Temporary buffer for single ID processing

# ========================== FILTERED RESULTS ================================
filtered_dorm1: .space 2048  # Results after location filter (format: name|name|...)
filtered_dorm2: .space 2048  # Results after price filter
filtered_dorm3: .space 2048  # Results after proximity filter
filtered_dorm4: .space 2048  # Results after amenities filter
final_results: .space 4096   # Final filtered results before printing

# ============================== POINTERS ====================================
current_filter_ptr: .word 0  # Pointer to track current position in filtered buffers

# ============================= MESSAGES =====================================
# User interface messages
welcome_msg: .asciiz "\n\nWELCOME TO SMART BOARDING HOUSE FINDER\n"
menu_prompt: .asciiz "\nPlease choose an option:\n1. Find available boarding house\n2. Exit\n"
prompt_instruction: .asciiz "\nPlease put a space every after entered id (e.g. 1 2 3 6)\n"
prompt_proximity: .asciiz "Enter ID of proximity to search: "
prompt_amenities: .asciiz "Enter ID of amenities to search: "
prompt_location: .asciiz "\nEnter location number to search: "
prompt_maxbudget: .asciiz "\nEnter max budget: "
prompt_amenities_choice: .asciiz "\nDo you want to filter by amenities? (1=Yes, 0=No): "

# Result and error messages
no_match_msg: .asciiz "\nNo matching dormitories found.\n"
results_header: .asciiz "\n\nFinal Filtered Results:\n"
location_choices: .asciiz "\nLocation Choices:\n"
proximity_choices: .asciiz "\nProximity Choices:\n"
amenities_choices: .asciiz "\nAmenities Choices:\n"
invalid_input_msg: .asciiz "\nInvalid input! Please try again.\n"
file_error_msg: .asciiz "\nError opening file!\n"
newLine: .asciiz "\n"
try_again_msg: .asciiz "\nDo you want to search again? (1=Yes, 0=No): "

# ============================= CONSTANTS ====================================
delimiter: .byte '|'         # Field delimiter used in data files

.text
.globl main

###############################################################################
# MAIN PROGRAM                                                                #
# Description: Controls the overall program flow                              #
# Registers used:                                                             #
#   $v0 - System call function selector                                       #
#   $a0 - Argument for system calls                                           #
#   $s0-$s7 - Saved registers for persistent data                             #
###############################################################################
main:
    # Display welcome message
    li $v0, 4
    la $a0, welcome_msg
    syscall
    
main_menu:
    # Display menu options
    li $v0, 4
    la $a0, menu_prompt
    syscall
    
    # Get user choice
    li $v0, 5
    syscall
    
    # Process menu choice
    beq $v0, 1, find_boarding
    beq $v0, 2, exit_program
    j invalid_menu_input

invalid_menu_input:
    li $v0, 4
    la $a0, invalid_input_msg
    syscall
    j main_menu

#############################################################################
# FIND_BOARDING                                                             #
# Description: Main function for searching boarding houses                  #
# Registers used:                                                           #
#   $s0 - File descriptor                                                   #
#   $s1 - Selected location ID                                              #
#   $s2 - Maximum budget                                                    #
#   $s3-$s6 - Filter result buffers                                        	#
#############################################################################
find_boarding:
    # Clear buffers for new search
    jal clear_buffers
    
 # ===================== LOCATION FILTER ==================== #
    # Display location choices
    li $v0, 4
    la $a0, location_choices
    syscall
    
    # Open and print locations master file
    li $v0, 13
    la $a0, locations_master
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0
    
    li $v0, 14
    move $a0, $s0
    la $a1, locations_bufferlist
    li $a2, 1024
    syscall
    
    li $v0, 16
    move $a0, $s0
    syscall
    
    li $v0, 4
    la $a0, locations_bufferlist
    syscall

    # Get location input from user with validation
get_location_input:
    li $v0, 4
    la $a0, prompt_location
    syscall
    
    li $v0, 5
    syscall
    blez $v0, invalid_location_input
    move $s1, $v0          # Store location choice in $s1
    j location_input_valid

invalid_location_input:
    li $v0, 4
    la $a0, invalid_input_msg
    syscall
    j get_location_input

location_input_valid:
    # Filter by location (first filter)
    jal filter_by_location
    
# ===================== PROXIMITY FILTER ===================== #

    # Display proximity choices
    li $v0, 4
    la $a0, proximity_choices
    syscall
    
    # Open and print proximity master file
    li $v0, 13
    la $a0, proximity_master
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0
    
    li $v0, 14
    move $a0, $s0
    la $a1, proximity_masterlist
    li $a2, 1024
    syscall
    
    li $v0, 16
    move $a0, $s0
    syscall
    
    li $v0, 4
    la $a0, proximity_masterlist
    syscall
    
    # Get proximity IDs from user
    li $v0, 4
    la $a0, prompt_instruction
    syscall
    
    li $v0, 4
    la $a0, prompt_proximity
    syscall
    
    li $v0, 8
    la $a0, id_buffer
    li $a1, 32 
    syscall

    # Filter by proximity (second filter)
    jal filter_by_proximity
    
# ===================== PRICE FILTER ===================== #

    # Get max budget from user with validation
get_budget_input:
    li $v0, 4
    la $a0, prompt_maxbudget
    syscall
    
    li $v0, 5
    syscall
    blez $v0, invalid_budget_input
    move $s2, $v0          # Store max budget in $s2
    j budget_input_valid

invalid_budget_input:
    li $v0, 4
    la $a0, invalid_input_msg
    syscall
    j get_budget_input

budget_input_valid:
    # Filter by price (second filter)
    jal filter_by_price

# ===================== AMENITIES FILTER ===================== #

    # Ask if user wants to filter by amenities
amenities_choice:
    li $v0, 4
    la $a0, prompt_amenities_choice
    syscall
    
    li $v0, 5
    syscall
    beq $v0, 0, print_results  # Skip amenities filter if 0
    beq $v0, 1, do_amenities_filter
    j invalid_amenities_choice

invalid_amenities_choice:
    li $v0, 4
    la $a0, invalid_input_msg
    syscall
    j amenities_choice

do_amenities_filter:
    # Display amenities choices
    li $v0, 4
    la $a0, amenities_choices
    syscall
    
    # Open and print amenities master file
    li $v0, 13
    la $a0, amenities_master
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0
    
    li $v0, 14
    move $a0, $s0
    la $a1, amenities_masterlist
    li $a2, 1024
    syscall
    
    li $v0, 16
    move $a0, $s0
    syscall
    
    li $v0, 4
    la $a0, amenities_masterlist
    syscall
    
    # Get amenities IDs from user
    li $v0, 4
    la $a0, prompt_instruction
    syscall
    
    li $v0, 4
    la $a0, prompt_amenities
    syscall
    
    li $v0, 8
    la $a0, id_buffer
    li $a1, 32 
    syscall

    # Filter by amenities (fourth filter)
    jal filter_by_amenities

###############################################################################
# PRINT_RESULTS                                                               #
# Description: Displays the final filtered results                            #
###############################################################################

print_results:
    # Print final results
    jal print_final_results

    # Ask if user wants to search again
try_again:
    li $v0, 4
    la $a0, try_again_msg
    syscall
    
    li $v0, 5
    syscall
    
    beq $v0, 1, find_boarding
    beq $v0, 0, exit_program
    j invalid_try_again_input

invalid_try_again_input:
    li $v0, 4
    la $a0, invalid_input_msg
    syscall
    j try_again

exit_program:
    # Exit program
    li $v0, 10
    syscall

###############################################################################
# FILE_ERROR                                                                  #
# Description: Handles file operation errors                                  #
###############################################################################

file_error:
    li $v0, 4
    la $a0, file_error_msg
    syscall
    j try_again

###############################################################################
# CLEAR_BUFFERS                                                               #
# Description: Clears all data buffers before a new search                    #
# Registers used:                                                             #
#   $t0 - Buffer pointer                                                      #
#   $t1 - Counter                                                             #
###############################################################################
clear_buffers:
    # Clear filtered_dorm1
    la $t0, filtered_dorm1
    li $t1, 2048
clear_loop1:
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    subiu $t1, $t1, 1
    bnez $t1, clear_loop1
    
    # Clear filtered_dorm2
    la $t0, filtered_dorm2
    li $t1, 2048
clear_loop2:
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    subiu $t1, $t1, 1
    bnez $t1, clear_loop2
    
    # Clear filtered_dorm3
    la $t0, filtered_dorm3
    li $t1, 2048
clear_loop3:
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    subiu $t1, $t1, 1
    bnez $t1, clear_loop3
    
    # Clear filtered_dorm4
    la $t0, filtered_dorm4
    li $t1, 2048
clear_loop4:
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    subiu $t1, $t1, 1
    bnez $t1, clear_loop4
    
    # Clear final_results
    la $t0, final_results
    li $t1, 4096
clear_loop5:
    sb $zero, 0($t0)
    addiu $t0, $t0, 1
    subiu $t1, $t1, 1
    bnez $t1, clear_loop5
    
    jr $ra

###############################################################################
# FILTER_BY_LOCATION                                                          #
# Description: Filters dorms by selected location                             #
# Input: $s1 - Selected location ID                                           #
# Output: filtered_dorm1 - List of dorms in selected location                 #
# Registers used:                                                             #
#   $s0 - File descriptor                                                     #
#   $t1 - File data pointer                                                   #
#   $s3 - Filtered dorms buffer pointer                                       #
#   $t2-$t6 - Temporary registers                                             #
###############################################################################
filter_by_location:
    # Open boarding locations file
    li $v0, 13
    la $a0, boarding_locations
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0

    # Read file content
    li $v0, 14
    move $a0, $s0
    la $a1, read_buffer
    li $a2, 2048
    syscall

    # Close file
    li $v0, 16
    move $a0, $s0
    syscall
    
    la $t1, read_buffer       # File data pointer
    la $s3, filtered_dorm1    # Filtered dorms buffer

location_search_loop:
    lb $t3, 0($t1)
    beqz $t3, location_filter_done
    
    # Check if first character matches location choice
    subi $t4, $t3, 48         # Convert ASCII to integer
    bne $t4, $s1, location_skip_line
    
    # Found matching location, copy dorm name
    addiu $t1, $t1, 2         # Skip location number and space
    la $t2, name_buffer1

copy_dorm_name:
    lb $t5, 0($t1)            # Load byte from source
    beq $t5, 10, location_store_dorm  # Newline
    beqz $t5, location_store_dorm     # Null terminator
    sb $t5, 0($t2)            # Store byte in name buffer
    sb $t5, 0($s3)            # Also store in filtered_dorm1
    addiu $t1, $t1, 1
    addiu $t2, $t2, 1
    addiu $s3, $s3, 1
    j copy_dorm_name

location_store_dorm:
    li $t6, '|'               # Add delimiter
    sb $t6, 0($s3)
    addiu $s3, $s3, 1
    sb $zero, 0($t2)          # Null-terminate name buffer
    j location_advance_line

location_skip_line:
    lb $t3, 0($t1)
    beqz $t3, location_filter_done
    beq $t3, 10, location_advance_line
    addiu $t1, $t1, 1
    j location_skip_line

location_advance_line:
    addiu $t1, $t1, 1
    j location_search_loop

location_filter_done:
    sb $zero, 0($s3)          # Null-terminate filtered_dorm1
    
    li $v0, 4
    la $a0, newLine
    syscall
    la $a0, filtered_dorm1
    syscall
    
    jr $ra

# --------------------------------------------------
# Filter by proximity (third filter)
# --------------------------------------------------
filter_by_proximity:
    # Initialize filtered_dorm3 pointer
    la $s4, filtered_dorm3
    sw $s4, current_filter_ptr

    # Open boarding proximity file
    li $v0, 13
    la $a0, boarding_proximity
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0
    
    # Read file content
    li $v0, 14
    move $a0, $s0
    la $a1, line_buffer
    li $a2, 1024
    syscall
    
    # Close file
    li $v0, 16
    move $a0, $s0
    syscall
    
    la $t1, line_buffer       # File data pointer
    la $s3, filtered_dorm1    # Dorms from location filter

proximity_process_dorms:
    # Copy dorm name from filtered_dorm1 to name_buffer1
    la $t3, name_buffer1 

proximity_copy_dorm_loop:
    lb $t5, 0($s3)
    beq $t5, '|', proximity_end_dorm_copy
    beqz $t5, proximity_filter_done
    sb $t5, 0($t3)
    addiu $s3, $s3, 1
    addiu $t3, $t3, 1
    j proximity_copy_dorm_loop

proximity_end_dorm_copy:
    sb $zero, 0($t3)          # Null-terminate dorm name
    addiu $s3, $s3, 1         # Move past '|'

    # Find matching dorm in proximity file
    la $t1, line_buffer       # Reset file pointer
    j proximity_find_dorm_in_file

proximity_find_dorm_in_file:
    la $t4, name_buffer2      # Destination buffer

proximity_copy_name_loop:
    lb $t6, 0($t1)
    beq $t6, '|', proximity_end_name_copy
    beq $t6, 10, proximity_end_name_copy
    beqz $t6, proximity_end_name_copy
    sb $t6, 0($t4)
    addiu $t1, $t1, 1
    addiu $t4, $t4, 1
    j proximity_copy_name_loop

proximity_end_name_copy:
    sb $zero, 0($t4)          # Null-terminate dorm name

    # Compare dorm names
    la $t3, name_buffer1
    la $t4, name_buffer2

proximity_compare_names:
    lb $t5, 0($t3)
    lb $t6, 0($t4)
    bne $t5, $t6, proximity_not_match
    beqz $t5, proximity_extract_ids  # Full match
    addiu $t3, $t3, 1
    addiu $t4, $t4, 1
    j proximity_compare_names

proximity_extract_ids:
    # Found matching dorm, extract proximity IDs
    la $t7, proximity_buffer
    addiu $t1, $t1, 1         # Move past '|'
    
proximity_extract_ids_loop:
    lb $t6, 0($t1)
    beq $t6, 10, proximity_compare_ids
    beqz $t6, proximity_compare_ids
    sb $t6, 0($t7)
    addiu $t1, $t1, 1
    addiu $t7, $t7, 1
    j proximity_extract_ids_loop

proximity_compare_ids:
    sb $zero, 0($t7)          # Null-terminate proximity IDs
    
    # Process user input IDs
    la $t0, id_buffer         # User input buffer
    li $t9, 0                 # Match counter
    
proximity_process_input:
    # Skip leading spaces
    lb $t2, 0($t0)
    beqz $t2, proximity_check_count
    beq $t2, 10, proximity_check_count
    beq $t2, ' ', proximity_skip_space
    j proximity_start_compare

proximity_skip_space:
    addiu $t0, $t0, 1
    j proximity_process_input

proximity_start_compare:
    # Extract one ID from user input
    li $t3, 0
    la $t4, id_buffer_temp

proximity_extract_user_id:
    lb $t2, 0($t0)
    beqz $t2, proximity_compare_single
    beq $t2, 10, proximity_compare_single
    beq $t2, ' ', proximity_compare_single
    sb $t2, 0($t4)
    addiu $t0, $t0, 1
    addiu $t4, $t4, 1
    addiu $t3, $t3, 1
    j proximity_extract_user_id

proximity_compare_single:
    sb $zero, 0($t4)          # Null-terminate single ID
    beqz $t3, proximity_process_input
    
    # Compare this ID with all proximity IDs
    la $t4, id_buffer_temp
    la $t7, proximity_buffer

proximity_compare_loop:
    lb $t5, 0($t4)            # User ID char
    lb $t6, 0($t7)            # Proximity ID char
    
    beq $t6, ' ', proximity_check_full
    beqz $t6, proximity_check_full
    bne $t5, $t6, proximity_next_id
    
    addiu $t4, $t4, 1
    addiu $t7, $t7, 1
    j proximity_compare_loop

proximity_check_full:
    lb $t5, 0($t4)
    beqz $t5, proximity_found_match
    j proximity_next_id

proximity_found_match:
    addiu $t9, $t9, 1         # Increment match count
    li $t8, 2
    bge $t9, $t8, proximity_store_qualified
    
proximity_next_id:
    # Skip to next ID in proximity buffer
    lb $t6, 0($t7)
    beqz $t6, proximity_process_input
    beq $t6, ' ', proximity_skip_prox_space
    addiu $t7, $t7, 1
    j proximity_next_id

proximity_skip_prox_space:
    addiu $t7, $t7, 1         # Skip space
    la $t4, id_buffer_temp    # Reset user ID pointer
    j proximity_compare_loop

proximity_check_count:
    li $t8, 2
    bge $t9, $t8, proximity_store_qualified
    j proximity_not_match

proximity_store_qualified:
    # Store qualified dorm in filtered_dorm3
    lw $s4, current_filter_ptr
    la $t3, name_buffer1
    
proximity_copy_qualified:
    lb $t5, 0($t3)
    beqz $t5, proximity_done_copy
    sb $t5, 0($s4)
    addiu $t3, $t3, 1
    addiu $s4, $s4, 1
    j proximity_copy_qualified

proximity_done_copy:
    li $t5, '|'               # Add delimiter
    sb $t5, 0($s4)
    addiu $s4, $s4, 1
    sb $zero, 0($s4)          # Null-terminate
    sw $s4, current_filter_ptr

proximity_not_match:
proximity_skip_to_next:
    lb $t5, 0($t1)
    beqz $t5, proximity_next_dorm
    beq $t5, 10, proximity_prepare_next
    addiu $t1, $t1, 1
    j proximity_skip_to_next

proximity_prepare_next:
    addiu $t1, $t1, 1
    j proximity_find_dorm_in_file

proximity_next_dorm:
    # Move to next dorm in filtered_dorm1
    lb $t5, 0($s3)
    beqz $t5, proximity_filter_done
    j proximity_process_dorms

proximity_filter_done:
	li $v0, 4
    la $a0, newLine
    syscall
    la $a0, filtered_dorm3
    jr $ra

# --------------------------------------------------
# Filter by price (second filter)
# --------------------------------------------------
filter_by_price:
    # Open price file
    li $v0, 13
    la $a0, price_master
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0

    # Read file content
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
    la $t1, line_buffer       # File data
    la $s3, filtered_dorm3    # Dorms from proximity filter
    la $s5, final_results     # Final results buffer

price_process_dorms:
    # Copy dorm name from filtered_dorm3 to name_buffer1
    la $t3, name_buffer1

price_copy_dorm_loop:
    lb $t5, 0($s3)
    beq $t5, '|', price_end_dorm_copy
    beqz $t5, price_filter_done
    sb $t5, 0($t3)
    addiu $s3, $s3, 1
    addiu $t3, $t3, 1
    j price_copy_dorm_loop

price_end_dorm_copy:
    sb $zero, 0($t3)          # Null-terminate dorm name
    addiu $s3, $s3, 1         # Move past '|'

    # Find matching dorm in price file
    la $t1, line_buffer       # Reset file pointer
    j price_find_dorm_in_file

price_find_dorm_in_file:
    la $t4, name_buffer2      # Destination buffer

price_copy_name_loop:
    lb $t6, 0($t1)
    beq $t6, '|', price_end_name_copy
    beq $t6, 10, price_end_name_copy
    beqz $t6, price_end_name_copy
    sb $t6, 0($t4)
    addiu $t1, $t1, 1
    addiu $t4, $t4, 1
    j price_copy_name_loop

price_end_name_copy:
    sb $zero, 0($t4)          # Null-terminate dorm name

    # Compare dorm names
    la $t3, name_buffer1
    la $t4, name_buffer2

price_compare_names:
    lb $t5, 0($t3)
    lb $t6, 0($t4)
    bne $t5, $t6, price_not_match
    beqz $t5, price_extract_price
    addiu $t3, $t3, 1
    addiu $t4, $t4, 1
    j price_compare_names

price_extract_price:
    # Found matching dorm, extract price
    la $t7, price_buffer
    addiu $t1, $t1, 1         # Move past '|'
    
price_extract_price_loop:
    lb $t6, 0($t1)
    beq $t6, 10, price_convert
    beqz $t6, price_convert
    sb $t6, 0($t7)
    addiu $t1, $t1, 1
    addiu $t7, $t7, 1
    j price_extract_price_loop

price_convert:
    sb $zero, 0($t7)          # Null-terminate price string
    la $t7, price_buffer
    li $t9, 0                 # Initialize price accumulator

price_str2int:
    lb $t6, 0($t7)
    beqz $t6, price_compare
    li $t3, '0'
    li $t4, '9'
    blt $t6, $t3, price_compare
    bgt $t6, $t4, price_compare
    sub $t6, $t6, $t3
    mul $t9, $t9, 10
    add $t9, $t9, $t6
    addiu $t7, $t7, 1
    j price_str2int

price_compare:
    ble $t9, $s2, price_store_final  # If price <= max budget
    j price_not_match

price_store_final:
    # Store dorm in final results
    la $t3, name_buffer1
    
price_copy_final:
    lb $t5, 0($t3)
    beqz $t5, price_done_copy
    sb $t5, 0($s5)
    addiu $t3, $t3, 1
    addiu $s5, $s5, 1
    j price_copy_final

price_done_copy:
    li $t5, '|'               # Add delimiter
    sb $t5, 0($s5)
    addiu $s5, $s5, 1
    sb $zero, 0($s5)          # Null-terminate

price_not_match:
price_skip_to_next:
    lb $t5, 0($t1)
    beqz $t5, price_next_dorm
    beq $t5, 10, price_prepare_next
    addiu $t1, $t1, 1
    j price_skip_to_next

price_prepare_next:
    addiu $t1, $t1, 1
    j price_find_dorm_in_file

price_next_dorm:
    # Move to next dorm in filtered_dorm3
    lb $t5, 0($s3)
    beqz $t5, price_filter_done
    j price_process_dorms

price_filter_done:
	li $v0, 4
    la $a0, newLine
    syscall
    la $a0, filtered_dorm2
    syscall
    jr $ra

# --------------------------------------------------
# Filter by amenities (fourth filter)
# --------------------------------------------------
filter_by_amenities:
    # Initialize filtered_dorm4 pointer
    la $s6, filtered_dorm4
    sw $s6, current_filter_ptr

    # Open boarding amenities file
    li $v0, 13
    la $a0, boarding_amenities
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0
    
    # Read file content
    li $v0, 14
    move $a0, $s0
    la $a1, line_buffer
    li $a2, 1024
    syscall
    
    # Close file
    li $v0, 16
    move $a0, $s0
    syscall
    
    la $t1, line_buffer       # File data pointer
    la $s3, final_results     # Dorms from price filter

amenities_process_dorms:
    # Copy dorm name from final_results to name_buffer1
    la $t3, name_buffer1 

amenities_copy_dorm_loop:
    lb $t5, 0($s3)
    beq $t5, '|', amenities_end_dorm_copy
    beqz $t5, amenities_filter_done
    sb $t5, 0($t3)
    addiu $s3, $s3, 1
    addiu $t3, $t3, 1
    j amenities_copy_dorm_loop

amenities_end_dorm_copy:
    sb $zero, 0($t3)          # Null-terminate dorm name
    addiu $s3, $s3, 1         # Move past '|'

    # Find matching dorm in amenities file
    la $t1, line_buffer       # Reset file pointer
    j amenities_find_dorm_in_file

amenities_find_dorm_in_file:
    la $t4, name_buffer2      # Destination buffer

amenities_copy_name_loop:
    lb $t6, 0($t1)
    beq $t6, '|', amenities_end_name_copy
    beq $t6, 10, amenities_end_name_copy
    beqz $t6, amenities_end_name_copy
    sb $t6, 0($t4)
    addiu $t1, $t1, 1
    addiu $t4, $t4, 1
    j amenities_copy_name_loop

amenities_end_name_copy:
    sb $zero, 0($t4)          # Null-terminate dorm name

    # Compare dorm names
    la $t3, name_buffer1
    la $t4, name_buffer2

amenities_compare_names:
    lb $t5, 0($t3)
    lb $t6, 0($t4)
    bne $t5, $t6, amenities_not_match
    beqz $t5, amenities_extract_amenities  # Full match
    addiu $t3, $t3, 1
    addiu $t4, $t4, 1
    j amenities_compare_names

amenities_extract_amenities:
    # Found matching dorm, extract amenities IDs
    la $t7, amenities_buffer
    addiu $t1, $t1, 1         # Move past '|'
    
amenities_extract_amenities_loop:
    lb $t6, 0($t1)
    beq $t6, 10, amenities_compare_amenities
    beqz $t6, amenities_compare_amenities
    sb $t6, 0($t7)
    addiu $t1, $t1, 1
    addiu $t7, $t7, 1
    j amenities_extract_amenities_loop

amenities_compare_amenities:
    sb $zero, 0($t7)          # Null-terminate amenities IDs
    
    # Process user input IDs
    la $t0, id_buffer         # User input buffer
    li $t9, 0                 # Match counter
    
amenities_process_input:
    # Skip leading spaces
    lb $t2, 0($t0)
    beqz $t2, amenities_check_count
    beq $t2, 10, amenities_check_count
    beq $t2, ' ', amenities_skip_space
    j amenities_start_compare

amenities_skip_space:
    addiu $t0, $t0, 1
    j amenities_process_input

amenities_start_compare:
    # Extract one ID from user input
    li $t3, 0
    la $t4, id_buffer_temp

amenities_extract_user_id:
    lb $t2, 0($t0)
    beqz $t2, amenities_compare_single
    beq $t2, 10, amenities_compare_single
    beq $t2, ' ', amenities_compare_single
    sb $t2, 0($t4)
    addiu $t0, $t0, 1
    addiu $t4, $t4, 1
    addiu $t3, $t3, 1
    j amenities_extract_user_id

amenities_compare_single:
    sb $zero, 0($t4)          # Null-terminate single ID
    beqz $t3, amenities_process_input
    
    # Compare this ID with all amenities IDs
    la $t4, id_buffer_temp
    la $t7, amenities_buffer

amenities_compare_loop:
    lb $t5, 0($t4)            # User ID char
    lb $t6, 0($t7)            # Amenities ID char
    
    beq $t6, ' ', amenities_check_full
    beqz $t6, amenities_check_full
    bne $t5, $t6, amenities_next_id
    
    addiu $t4, $t4, 1
    addiu $t7, $t7, 1
    j amenities_compare_loop

amenities_check_full:
    lb $t5, 0($t4)
    beqz $t5, amenities_found_match
    j amenities_next_id

amenities_found_match:
    addiu $t9, $t9, 1         # Increment match count
    li $t8, 1                 # At least 1 match required
    bge $t9, $t8, amenities_store_qualified
    
amenities_next_id:
    # Skip to next ID in amenities buffer
    lb $t6, 0($t7)
    beqz $t6, amenities_process_input
    beq $t6, ' ', amenities_skip_amenities_space
    addiu $t7, $t7, 1
    j amenities_next_id

amenities_skip_amenities_space:
    addiu $t7, $t7, 1         # Skip space
    la $t4, id_buffer_temp    # Reset user ID pointer
    j amenities_compare_loop

amenities_check_count:
    li $t8, 1
    bge $t9, $t8, amenities_store_qualified
    j amenities_not_match

amenities_store_qualified:
    # Store qualified dorm in filtered_dorm4
    lw $s6, current_filter_ptr
    la $t3, name_buffer1
    
amenities_copy_qualified:
    lb $t5, 0($t3)
    beqz $t5, amenities_done_copy
    sb $t5, 0($s6)
    addiu $t3, $t3, 1
    addiu $s6, $s6, 1
    j amenities_copy_qualified

amenities_done_copy:
    li $t5, '|'               # Add delimiter
    sb $t5, 0($s6)
    addiu $s6, $s6, 1
    sb $zero, 0($s6)          # Null-terminate
    sw $s6, current_filter_ptr

amenities_not_match:
amenities_skip_to_next:
    lb $t5, 0($t1)
    beqz $t5, amenities_next_dorm
    beq $t5, 10, amenities_prepare_next
    addiu $t1, $t1, 1
    j amenities_skip_to_next

amenities_prepare_next:
    addiu $t1, $t1, 1
    j amenities_find_dorm_in_file

amenities_next_dorm:
    # Move to next dorm in final_results
    lb $t5, 0($s3)
    beqz $t5, amenities_filter_done
    j amenities_process_dorms

amenities_filter_done:
    # Copy filtered_dorm4 to final_results
    la $s5, final_results
    la $s6, filtered_dorm4
    
copy_to_final:
    lb $t5, 0($s6)
    beqz $t5, copy_done
    sb $t5, 0($s5)
    addiu $s5, $s5, 1
    addiu $s6, $s6, 1
    j copy_to_final

copy_done:
    sb $zero, 0($s5)          # Null-terminate final results
    jr $ra

# ----------------------------------------------------------------------#
# Print final results from boarding_details.txt (using ! as delimiter)	#
# ----------------------------------------------------------------------#
print_final_results:
    li $v0, 4
    la $a0, results_header
    syscall
    
    # Check if there are any results
    la $t0, final_results
    lb $t1, 0($t0)
    beqz $t1, print_no_results
    
    # Open boarding_details file
    li $v0, 13
    la $a0, boarding_details
    li $a1, 0
    syscall
    bltz $v0, file_error
    move $s0, $v0
    
    # Read entire file content
    li $v0, 14
    move $a0, $s0
    la $a1, read_buffer
    li $a2, 4096
    syscall
    
    # Close file
    li $v0, 16
    move $a0, $s0
    syscall
    
    # Process each dorm in final_results
    la $s1, final_results
    
print_next_dorm:
    # Extract next dorm name
    la $t0, name_buffer1
    li $t1, 0
    
copy_dorm_name_loop:
    lb $t2, 0($s1)
    beq $t2, '|', end_copy_name
    beqz $t2, print_done
    sb $t2, 0($t0)
    addiu $s1, $s1, 1
    addiu $t0, $t0, 1
    addiu $t1, $t1, 1
    j copy_dorm_name_loop
    
end_copy_name:
    sb $zero, 0($t0)         # Null-terminate name
    addiu $s1, $s1, 1        # Skip '|'
    
    # Search for dorm in details file
    la $s2, read_buffer
    
search_loop:
    # Look for "Name: " pattern
    lb $t3, 0($s2)
    beqz $t3, next_dorm      # End of file
    
    bne $t3, 'N', next_char
    lb $t3, 1($s2)
    bne $t3, 'a', next_char
    lb $t3, 2($s2)
    bne $t3, 'm', next_char
    lb $t3, 3($s2)
    bne $t3, 'e', next_char
    lb $t3, 4($s2)
    bne $t3, ':', next_char
    lb $t3, 5($s2)
    bne $t3, ' ', next_char
    
    # Found "Name: ", now compare names
    addiu $s2, $s2, 6       # Skip "Name: "
    la $t0, name_buffer1
    
compare_names:
    lb $t3, 0($s2)
    lb $t4, 0($t0)
    beqz $t4, found_match   # End of our name
    bne $t3, $t4, next_char
    addiu $s2, $s2, 1
    addiu $t0, $t0, 1
    j compare_names
    
found_match:
    # Print from start of record (previous '!') to next '!'
    li $v0, 4
    la $a0, newLine
    syscall
    
    # Find start of record
    la $t5, read_buffer
    move $t6, $s2
    subiu $t6, $t6, 6       # Back to start of "Name: "
    
find_record_start:
    ble $t6, $t5, print_record  # At start of buffer
    lb $t7, -1($t6)
    beq $t7, '!', found_record_start
    subiu $t6, $t6, 1
    j find_record_start
    
found_record_start:
    addiu $t6, $t6, 1       # Skip the '!'
    
print_record:
    li $v0, 11
    
print_char:
    lb $a0, 0($t6)
    beqz $a0, next_dorm
    beq $a0, '!', end_record
    syscall
    addiu $t6, $t6, 1
    j print_char
    
end_record:
    li $v0, 4
    la $a0, newLine
    syscall
    j next_dorm
       
next_char:
    addiu $s2, $s2, 1
    j search_loop
    
next_dorm:
    j print_next_dorm
    
print_no_results:
    li $v0, 4
    la $a0, no_match_msg
    syscall

print_done:
    jr $ra