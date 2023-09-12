# Program takes a user inputted string and utilizes a secondary file with functions to filter out unnecessary characters to
# determine if the string is a palindrome. The secondary file's functions remove all non numbers and letters from the string
# and convert all lowercase letters to uppercase so the ascii values match. Then, the primary file determines if the now-filtered
# string is a palindrome by checking each element and outputting its findings accordingly
# Written by Evan Wright for CS2340.006, assignment 4, starting October 15th, 2022
# NetID: emw200004

.include "SysCalls.asm"

	.data
prompt1:	.asciiz	"Enter a string: "
prompt2:	.asciiz	"Palindrome. "
prompt3:	.asciiz	"Not a palindrome. "
buffer:	.space 	200
buffer2:	.space	200

	.text
main:
	add	$a2, $zero, $zero
	
	la	$a0, prompt1		# load the address of the prompt for "Enter a string: " into the argument register
	li	$v0, SysPrintString		# load SysPrintString into $v0 to print the argument register
	syscall				# outputs "Enter a string: " into the console
	
	la	$a0, buffer		# address of input buffer
	li	$a1, 200			# length of buffer
	li	$v0, SysReadString		# load SysReadString into $v0 to get string input from the console
	syscall				# once the user enters a string into the console, return it to $a0 (address of input buffer)
	
	lb	$t0, ($a0)		# get the first character
	beq	$t0, '\n', exit		# if the first character is a null terminator, then exit the program
	
	# else, assign second buffer space and clear registers for use in functions
	la	$a2, buffer2		# address of secondary input buffer for tracking palindrome-valid characters
	add	$t1, $zero, $zero		# clear $t1 to act as an iterator
	add	$t2, $zero, $zero		# clear $t2 to act as tracker for iterating thru valid characters
	add	$t3, $zero, $zero		# used for iterating through the string checking if the elements are equal for palindrome
	add	$t4, $zero, $zero		# used for storing the trailing element of the palindrom comparison loop
	add	$t5, $zero, $zero		# used to iterate through the block of memory to reset it
	
	# put address of string into $a0 and call a function that determines if the string is a palindrome
	# the primary function will be on this file, the subsequent called functions are on a separate file
	# that function will first call another function that removes non letters and numbers
	# at the end of the removal function, another function is called that converts lowercase --> uppercase
	# then jump back into the main function which determines if the string is a palindrome, see lecture notes for help
	
	# to reiterate, the first function that is called is in this file, the functions that the primary functions calls
	# are in a secondary file which is used through .globl or something, not sure
	
	jal	cleargarbage		# calls cleargarbage which is a global function in another file

palindrome:	
	# palindrome will loop through each character in the filtered string.
	# get the first element of the string stored in one register and the last element of the string in another register
	# $t2 stores the amount of elements in the filtered array (if out of bounds then need to sub 4), so get the last element
	# by adding $t2 to $a0 and then storing that byte and comparing it to the byte at the beginning of the array
	# if the elements are not equal, then go to exit and output "Not a palindrome", else move the pointer registers inward
	# i.e. add 4 to $t3 and subtract 4 from $t2, check if the elements have reversed positions or are equal (if so then output
	# "Palindrome", if they havent crossed yet then loop back and get the next two characters
	
	
	# get elements by moving the address using registers that operate as pointers to the leading and trailing characters
	add	$a0, $a0, $t3		# point to the next leading character of the string
	lb	$t0, ($a0)		# get the next leading character of the string
	sub	$a0, $a0, $t3		# point back to top of the string
	add	$a0, $a0, $t2		# point to the last character of the string
	lb	$t4, ($a0)		# get the next trailing character of the string
	sub	$a0, $a0, $t2		# move string pointer back to the first element
	
	# check if the elements are equal, not a palindrome if not equal, move pointers inwards if they are until pointers swap
	bne	$t0, $t4, notpalin		# if characters are not equal, then string is not a palindrome
	addi	$t3, $t3, 1		# move the leading character pointer the the next character
	subi	$t2, $t2, 1		# move the trailing character pointer to the next character
	
	bgt	$t2, $t3, palindrome	# if the pointers have flipped positions or point to same element, then stop looping

validpalin:
	sb	$zero, ($a0)		# store 0 into pointed to element in first block of memory
	addi	$a0, $a0, 1		# add one to pointer to point to next byte
	sb	$zero, ($a2)		# store 0 into pointed to element in second block of memory
	addi	$a2, $a2, 1		# add one to pointer to point to next byte
	add	$t5, $t5, 1		# add one to memory clear iterator		
	blt	$t5, 200, validpalin	# until all 200 bytes of each memory block have been reset, keep looping
	sub	$a0, $a0, $t5		# reset pointer for primary block of memory
	sub	$a2, $a0, $t5		# reset pointer for secondary block of memory
	add	$t5, $zero, $zero		# reset the clear memory iterator
	
	# if every element has been checked and is validated, then string is a palindrome
	la	$a0, prompt2		# load the address of the prompt for "Palindrome." into the argument register
	li	$v0, SysPrintString		# load SysPrintString into $v0 to print the argument register
	syscall				# outputs "Not a palindrome." into the console
	
	j main				# # jump back to get another string to check for palindrome
	
notpalin:
	sb	$zero, ($a0)		# store 0 into pointed to element in first block of memory
	addi	$a0, $a0, 1		# add one to pointer to point to next byte
	sb	$zero, ($a2)		# store 0 into pointed to element in second block of memory
	addi	$a2, $a2, 1		# add one to pointer to point to next byte
	add	$t5, $t5, 1		# add one to memory clear iterator		
	blt	$t5, 200, notpalin		# until all 200 bytes of each memory block have been reset, keep looping
	sub	$a0, $a0, $t5		# reset pointer for primary block of memory
	sub	$a2, $a0, $t5		# reset pointer for secondary block of memory
	add	$t5, $zero, $zero		# reset the clear memory iterator
	
	la	$a0, prompt3		# load the address of the prompt for "Not a palindrome." into the argument register
	li	$v0, SysPrintString		# load SysPrintString into $v0 to print the argument register
	syscall				# outputs "Not a palindrome." into the console
	
	j main				# jump back to get another string to check for palindrome

exit:
	# accessed if the user enters only a null terminator into the string input
	li	$v0, SysExit
	syscall
