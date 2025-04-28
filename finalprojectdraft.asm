.data
welcomeMsg:         .asciiz "\nWelcome to Smart Boarding House!\n"
menu:               .asciiz "\n1. Find Boarding House\n2. Exit\nChoose an option: "
invalidMsg:         .asciiz "\nInvalid option! Please try again.\n"
promptBudget:      .asciiz "\nEnter your budget: "
promptProximity:   .asciiz "Enter preferred proximity (1. School 2. Grocery 4. Gym): "
match_found_msg:    .asciiz "\nMatching Boarding Houses:\n"
no_match_msg:       .asciiz "\nNo boarding houses matched.\n"
newline:            .asciiz "\n"

#boarding house data
prices:             .word 2500, 3000, 2000
proximity:          .word 3, 4, 7     # 3 = school and grocery, 4 = gym, 7 = all
count:              .word 3

.text
.globl main
main:
    li $v0, 4
    la $a0, welcomeMsg
    syscall

menu_loop:
    li $v0, 4
    la $a0, menu
    syscall

    li $v0, 5
    syscall
    move $t9, $v0     # store user choice

    li $t8, 1
    beq $t9, $t8, start_search

    li $t8, 2
    beq $t9, $t8, end

    # Invalid choice
    li $v0, 4
    la $a0, invalidMsg
    syscall
    j menu_loop

start_search:
    # Promp the budget
    li $v0, 4
    la $a0, promptBudget
    syscall
    li $v0, 5
    syscall
    move $t0, $v0     # $t0 = max budget

    # Prompt the proximityy
    li $v0, 4
    la $a0, promptProximity
    syscall
    li $v0, 5
    syscall
    move $t1, $v0     # $t1 = preferred proximity

    # Prepare to search
    li $t2, 0          # index = 0
    li $t3, 0          # match_found = 0
    la $s0, prices
    la $s1, proximity

    li $v0, 4
    la $a0, match_found_msg
    syscall

search_loop:
    lw $t4, count
    bge $t2, $t4, end_search

    lw $t5, 0($s0)     # price
    lw $t6, 0($s1)     # proximity

    ble $t5, $t0, check_proximity   # price <= budget
    j next

check_proximity:
    and $t7, $t6, $t1
    bne $t7, $t1, next           # if proximity not matching, skip

    li $v0, 1
    move $a0, $t5     # display price
    syscall

    li $v0, 4
    la $a0, newline
    syscall

    li $t3, 1         # match_found = true

next:
    addi $t2, $t2, 1
    addi $s0, $s0, 4
    addi $s1, $s1, 4
    j search_loop

end_search:
    beq $t3, $zero, no_matches
    j return_menu

no_matches:
    li $v0, 4
    la $a0, no_match_msg
    syscall

return_menu:
    j menu_loop

end:
    li $v0, 10
    syscall
