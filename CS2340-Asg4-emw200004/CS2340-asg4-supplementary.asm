# This file is supplementary to CS2340-Asg4, it provides 2 functions which are necessary for 
# CS2340-Asg4 to properly determine if a given string is a palindrome
# Written by Evan Wright for CS2340.006, assignment 4, starting October 15th, 2022
# NetID: emw200004

.include "SysCalls.asm"

	.text
	.globl cleargarbage
cleargarbage:
	# filter out unwanted characters for determining if the string is a palindrome (non numbers and letters)
	# get element by element, if element is within specific usable ascii ranges, store it into a secondary string buffer
	# once the null terminator is encountered, stop looping and go to the letter conversion function
	
	# checks are not actually able to determine whether the ascii value is greater or not, 'a' muscles thru like every check somehow even jump
	
	lb	$t0, ($a0)		# get the element of the string being pointed to and put it in $t0
	beqz	$t0, convertfunc		# if character is null terminator, then go to convertfunc
	# check if value is between ascii 48-57 for numbers, 65-90 for capital letters, 97-122 for lowercase letters
	blt	$t0, '0', nextchar		# no ascii values below 48 that are palindrome-usable
	bgt	$t0, 'z', nextchar		# no ascii values above 122 that are palindrome-usable
	bgt	$t0, '9', check1		# make sure values aren't within the 57-65 unusable range
	# if values make it this far, they are between 48-57 inclusive, so element is a capital letter
	j storechar			# go store the palindrome usable element
	
check1:
	blt	$t0, 'A', nextchar		# skips unusable ascii values from 57-65
	bgt	$t0, 'Z', check2		# make sure values aren't within the 90-97 unusable range
	# if values make it this far, they are between 65-90, so element is a capital letter
	j storechar			# go store the palindrome usable element

check2:
	blt	$t0, 'a', nextchar		# skips unusable ascii values from 90-97
	# if values make it this far, they are between 97-122 inclusive, so element is a lowercase letter
	j storechar			# go store the palindrome usable element
	
nextchar:
	# iterate to move to next character
	addi	$a0, $a0, 1		# point to the next element
	addi	$t1, $t1, 1		# increment by 4 to track how far pointer has been moved
	j cleargarbage

storechar:
	# store the bytes of valid characters into a secondary buffer, move the $t2 secondary pointer for every character stored and 
	# leave $t1 as the primary pointer for iterating thru every character in the unfiltered string
	
	sb	$t0, ($a2)		# store the valid element into the valid palindrome string
	addi	$a2, $a2, 1		# set valid palindrome string to point to next element
	addi	$a0, $a0, 1		# set unfiltered string to point to next element
	addi	$t2, $t2, 1		# increment by 4 to track the pointer increment for the valid palindrome string
	addi	$t1, $t1, 1		# increment by 4 to track the pointer increment for the unfiltered string
	#add	$a0, $a0, $t0		# point to the next element
	j cleargarbage	
	
	
convertfunc:
	# if getting out of bounds here, try adding 4 to iterator because idk if null terminator should be included in size for palindrome
	sub	$a0, $a0, $t1		# set unfiltered pointer to be back at the first element using the iterator
	sub	$a2, $a2, $t2		# set filtered pointer to be back at first element using filtered iterator
	#subi	$t2, $t2, 1		# $t2 acts as a maximum value, so we subtract 4 so it won't compare the null terminator
convtloop:
	lb	$t0, ($a2)		# get element being pointed to in the filtered string
	beqz	$t0, finalize		# if element is null terminator then end of string has been reached, prep for return
	
	# lowercase ascii range is 97-122, if element's ascii value is in this range, then subtract 32 to convert to lowercase, 
	# then store the new byte back into the string at the same index thru the pointer, then shift the pointer to next element
	bgt	$t0, 122, iterate		# if ascii value of element is above the lowercase range, then reiterate
	blt	$t0, 97, iterate		# if ascii value of element is below the lowercase range, then reiterate
	sub	$t0, $t0, 32		# convert the lowercase letter to a capital letter by changing ascii value
	sb	$t0, ($a2)		# store the converted letter back into the string at the same index
	# fall into iterate to continue looping

iterate:
	addi	$a2, $a2, 1		# point to next element in string
	j	convtloop			# continue looping to get next element

finalize:
	# might need to do looping here to clear the original string in $a0 and put the filtered string from $a2 into $a0 before returning
	sub	$a2, $a2, $t2		# set pointer for filtered array back to first element
	add	$a0, $a2, $zero		# set $a0 to be address of filtered string?
	subi	$t2, $t2, 1		#### TEMP TEMP TEMP TEMP
exit:

	# if returning from the end of this file, will go back to the linked address in $ra from the jal and continue program

	jr $ra