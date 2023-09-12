# Program prompts the user to enter a password and then performs a series of checks on the
# password's characters using ascii values to determine whether the password was valid. The password
# must be at least 12 characters and requires a number, a lowercase letter, an uppercase letter, and
# one of a few validated special characters. If the password has a character not among these or if
# the password has more than 50 characters, then the password is invalid. The program loops until
# the user enters only a newline, in which case it exits.
# Written by Evan Wright for CS2340.006, assignment 7, starting December 1st, 2022
# NetID: emw200004

	.include "SysCalls.asm"
	
	.data
prompt1:	.asciiz "Please enter a password: "
vldpas:	.asciiz "Valid Password.\n"
invldpas:	.asciiz "Invalid Password.\n"
	.eqv passSize, 255		# 255 is probably overkill, but program is simplistic enough to create a comfort zone without sacrificing speed
passBuff:	.space passSize 		# creates a space to save the string of the password entered by the user

	.text
main:
	# zero out registers used for checking if the password contains certain characters
	li	$s0, 0			# represents T/F for containing an uppercase letter
	li	$s1, 0			# represents T/F for containing a lowercase letter
	li	$s2, 0			# represents T/F for containing a number
	li	$s3, 0			# represents T/F for containing something from !@#$%^&()[],.:;
	li	$t0, 0			# zero out the iterator used for looping through the string
	
	# prompt user for password and receive input
	li	$v0, SysPrintString		
	la	$a0, prompt1
	syscall				# print "Please enter a password: "
	
	li	$v0, SysReadString
	la	$a0, passBuff
	li	$a1, passSize		# read in 51 characters at most, if last character isn't a null terminator then pass has invalid length
	syscall				# read in string from the user representing the password into buffer
	
	lb	$t1, 0($a0)		# load character from the password at currently pointed to address
	beq	$t1, '\n', exit		# if no characters were entered, exit program
	jal passCheck			# loop character by character and validate whole password
	blt	$t0, 12, invalidPass	# if the password length is below 12, then pass is invalid
	bne	$s0, 1, invalidPass		# if the password doesn't have an uppercase letter, then pass is invalid
	bne	$s1, 1, invalidPass		# if the password doesn't have a lowercase letter, then pass is invalid
	bne	$s2, 1, invalidPass		# if the password doesn't have a number, then pass is invalid
	bne	$s3, 1, invalidPass		# if the password doesn't have a valid special character, then pass is invalid
	j validPass			# program isn't rerouted to invalidPass at any point, then password is valid
	

passCheck:
	# get next char and check for end of password
	lb	$t1, 0($a0)		# load character from the password at currently pointed to address
	bne	$t1, '\n', charTest		# check for endline to detect end of password, else test the character
	bgt	$t0, 50, invalidPass	# if password entered has an invalid length
	jr	$ra			# if the character is a null terminator, it will fall through and return
charTest:
	# if element is within the ascii range for uppercase letter, then set $s0 to 1
	# if element is within the ascii range for lowercase letter, then set $s1 to 1
	# if element is within the ascii range for a number, then set $s2 to 1
	# if element is any special character within the space between these ranges, then set $s3 to 1
	
	blt	$t1, 48, belowNum		# handles 0-47, various special chars
	blt	$t1, 65, checkNum		# handles 48-64, numbers and : ; @
	blt	$t1, 97, checkUpper		# handles 65-97, uppercase letters and ^ [ ]
	blt	$t1, 123, lowerFlag		# handles 91-123, only lowercase letters
	j  invalidPass			# any character equal to or greater than 123 is invalid
	
passInc:
	addi	$a0, $a0, 1		# move pointer to next character in password buffer
	addi	$t0, $t0, 1		# increase the iterator correspondingly
	j passCheck

belowNum:
	# value is below ascii 48, this range contains a few valid special characters:
	blt $t1, 33, invalidPass		# anything below ascii 33 is invalid
	
	# 33(!), 35(#), 36($), 37(%), 38(&), 40((), 41()), 44(,), 46(.)
	beq $t1, 34, invalidPass 		# intervals for invalid characters are frequent and sporatic
	beq $t1, 39, invalidPass		# easier weed out bad chars than to check for every 2 number good char interval
	beq $t1, 42, invalidPass
	beq $t1, 43, invalidPass
	beq $t1, 45, invalidPass
	j specialFlag			# if character makes it to here, it is a valid special character

checkNum:
	# value is between 48-64
	blt	$t1, 58, numFlag		# ascii value is between 48-58 and is a number
	
	# 58(:), 59(;), 64(@)
	beq	$t1, 58, specialFlag	# check for valid special characters between ascii 58-64 (:, ;, @)
	beq	$t1, 59, specialFlag
	beq	$t1, 64, specialFlag
	j invalidPass			# if character makes it to here, it is an invalid special character between 58-64

checkUpper:
	# value is between 65-96
	blt	$t1, 91, upperFlag		# ascii value is between 65-90, uppercase letters
	
	# 91([), 93(]), 94(^)
	beq	$t1, 91, specialFlag	# check for valid special characters between ascii 90-96
	beq	$t1, 93, specialFlag
	beq	$t1, 94, specialFlag
	j invalidPass			# if character makes it to here, it is an invalid special character

upperFlag:
	li	$s0, 1			# set the register for the uppercase letter flag to be "true"
	j passInc				# iterate to get next number
lowerFlag:
	li	$s1, 1			# set the register for the lowercase latter flag to be "true"
	j passInc				# iterate to get next number
numFlag:
	li	$s2, 1			# set the register for the number flag to be "true"
	j passInc				# iterate to get next number
specialFlag:
	li	$s3, 1			# set the register for the special character flag to be "true"
	j passInc				# iterate to get next number
	# 33(!), 35(#), 36($), 37(%), 38(&), 40((), 41()), 44(,), 46(.)
	# 58(:), 59(;), 64(@)
	# 91([), 93(]), 94(^)
	

invalidPass:
	li	$v0, SysPrintString		
	la	$a0, invldpas
	syscall				# print "Invalid Password."

	j main
	
validPass:
	li	$v0, SysPrintString		
	la	$a0, vldpas
	syscall				# print "Valid Password."

	j main

exit:
	li	$v0, SysExit
	syscall
	