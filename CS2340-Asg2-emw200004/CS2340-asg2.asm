# Program takes a string from the user of ideally numbers, then does input validation and number conversion to 
# sum all valid numbers given, then outputs the sum as well as the number of both numbers and errors entered
# Written by Evan Wright for CS2340.006, assignment 2, starting September 16th, 2022
# NetID: emw200004

	.include "SysCalls.asm"		# symbolic names instead of magic numbers for syscalls
	.data

prompt:	.asciiz	"Enter a number: "
prompt1:.asciiz	"Error: Not a number\n"
prompt2:.asciiz "The sum of the numbers is: "
prompt3:.asciiz "\nThe total number of valid numbers entered is: "
prompt4:.asciiz "\nThe total number of errors was: "
buffer: .space 255

# Start of code
	.text
input:
### Prompt user to enter a number and store as a string

	add	$t0, $zero, $zero	# this register is the total accumulator for all valid numbers
	add	$t3, $zero, $zero	# this register will be used to count how many valid numbers are entered
	add	$t4, $zero, $zero	# this register will be used to count how many errors are entered
	add	$t2, $zero, $zero	# this register will be used to represent negative numbers
	add	$t5, $zero, $zero	# functions as a temporary accumulator before it's total is saved into $t0 for each num
	
	li	$v0, SysPrintString		# load number for reading a string
	la	$a0, prompt		# load the address of the prompt into $a0
	syscall				# prints the prompt to the console ("Enter a number: ")
	
	la	$a0, buffer		# address of input buffer
	li	$a1, 255			# length of buffer
	li	$v0, SysReadString		# load number for reading a string
	syscall				# read the number from the user as a string and store it into $v0
	
testfirst:		
### get the first character of the string entered
	lbu	$t1, 0($a0)		# loads next byte stored in $a0 into $t1
	beq	$t1, '\n', exit		# if newline is found, jump to exit and stop program
	beq	$t1, '-', negindicate	# if a neg sign is found, go to testneg to test if it's the first char
	b	binarify			# go to number conversion now that all exceptions are convered
	
negindicate:
### when the first char is the string is a negative indicator
	li	$t2, 1			# use $t2 as placeholder to represent negativity for later
	addi	$a0, $a0, 1		# move to next character to skip negative sign
	lbu	$t1, 0($a0)		# loads next byte stored in $a0 into $t1
# fall through to the conversion when done
	
binarify:
### converts the characters from the string into integers and does error checking to ensure the given digits are numbers
	beq	$t1, '\n', prevalidate	# if newline is found, go back to start to get a new number
	mulu 	$t5, $t5, 10		# multiply the accumulator by 10
# check that digit is between 1 - 9
	subi	$t1, $t1, '0'		# convert to digit
	blt	$t1, 0, error		# branch to error if value is less than 0, wouldn't be a number
	bgt	$t1, 9, error		# branch to error if value is greater than 9, wouldn't be a number
# add up the number after error checking and get the next char
	add	$t5, $t5, $t1		# add the value into the accumulator
	addi	$a0, $a0, 1		# move to next character
	lbu	$t1, 0($a0)		# loads next byte stored in $a0 into $t1
	b	binarify
	
error:
### adds one to the total number of errors entered, prints error message, and goes back to the top
	addi	$t4, $t4, 1		# increment the error counter by 1
	li	$v0, SysPrintString	# load number for reading a string
	la	$a0, prompt1		# load the address of the prompt into $a0
	syscall				# prints the prompt to the console ("Error: Not a number")
	b	input			# go back to input to get a new number

prevalidate:
### positive numbers will skip straight to validread, numbers indicated to be negative be evaluated here instead
	bne	$t2, 1, validread	# if the number is indicated to be positive, jump to validread to totalize it
# fall thru if negative number
	addi	$t3, $t3, 1		# increment the valid number counter by 1
	sub	$t0, $t0, $t5		# store total accumulator value but subtracting because negative
	b	input			# go back to input to get a new number

validread:
### store binary value of the number into total accumulator and add one to valid number counter before repeating program
	addi	$t3, $t3, 1		# increment the valid number counter by 1
	add	$t0, $t0, $t5		# store total accumulator value 
	b	input			# go back to input to get a new number

exit:	
### when a newline is the initial digit entered, perform exit sequence and display info
	
	li	$v0, SysPrintString	# load number for reading a string
	la	$a0, prompt2		# load the address of the prompt2 into $a0
	syscall				# prints the statement to the console ("The total number of valid numbers entered is: ")
	
	li 	$v0, SysPrintInt	# load number for printing an integer
	add 	$a0, $t0, $zero		# set argument to be the accumulator
	syscall				# print sum that was stored in $t0
	
	li	$v0, SysPrintString	# load number for reading a string
	la	$a0, prompt3		# load the address of the prompt3 into $a0
	syscall				# prints statement to the console ("The total number of valid numbers entered is: ")
	
	li 	$v0, SysPrintInt	# load number for printing an integer
	add 	$a0, $t3, $zero		# set argument to be number of valid numbers inputted
	syscall				# output stored counter from $t3
	
	li	$v0, SysPrintString	# load number for reading a string
	la	$a0, prompt4		# load the address of the prompt4 into $a0
	syscall				# prints statement to the console ("The total number of errors entered was: ")
	
	li 	$v0, SysPrintInt	# load number for printing an integer
	add 	$a0, $t4, $zero		# set argument to be number of valid numbers inputted
	syscall				# output stored counter from $t4
	
	li	$v0, SysExit		# System exit
	syscall
