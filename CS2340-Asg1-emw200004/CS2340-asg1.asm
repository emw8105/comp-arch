# Program prompts user and receives integer inputs until 0 is given by the user, then return the sum of all numbers entered
# Written by Evan Wright for CS2340.006, assignment 1, starting September 5th, 2022
# NetID: emw200004

	.include "SysCalls.asm"
	.data
prompt:	.asciiz	"Enter an integer: "
prompt1: .asciiz "The sum is: "
prompt2: .asciiz "\nThe number of integers entered was: "

# Start of code
	.text
compute:
### Prompt user to enter an integer
	li	$v0, SysPrintString	# load number for reading a string
	la	$a0, prompt	# load the address of the prompt into $a0
	syscall			# prints the prompt to the console ("Enter an integer: ")
	
	li	$v0, SysReadInt		# load number for reading an integer
	syscall			# read the integer from the user and return it into $v0
	
	add 	$t0, $v0, $zero	# stores returned integer into $t0
	add 	$t1, $t0, $t1	# store the sum into $t1, effectively sum +=
	addi 	$t3, $t3, 1	# $t3 is a counter, every entered integer will increment 1
	bne 	$t0, 0, compute	# if integer is not 0, jump back to compute


### Begin outputting stored information
	li	$v0, SysPrintString		# load number for reading a string
	la	$a0, prompt1	# load the address of the prompt1 into $a0
	syscall			# prints the statement to the console ("The sum is: ")
	
	li 	$v0, SysPrintInt		# load number for printing an integer
	add 	$a0, $t1, $zero	# set argument to be current sum value
	syscall			# print sum that was stored in $t1
	
	li	$v0, SysPrintString		# load number for reading a string
	la	$a0, prompt2	# load the address of the prompt1 into $a0
	syscall			# prints statement to the console ("\nThe number of integers entered was: ")
	
	li 	$v0, SysPrintInt		# load number for printing an integer
	add 	$a0, $t3, -1	# set argument to be number of numbers inputted, subtract 1 to compensate for exiting 0 entered
	syscall			# output stored counter from $t3
	
	li	$v0, SysExit		# System exit
	syscall
