# CS2340-asg5.asm, program asks the user for double precision floating point numbers until they enter 0.
# The numbers are stored in a buffer space functioning as an array. The program then calls a function
# to use bubble sort on the array, swapping the elements until they are organized from least to greatest
# the numbers are then printed one by one for the user, it also prints out the sum and average of the set of numbers
# Written by Evan Wright for CS2340.006, assignment 5, starting October 25th, 2022
# NetID: emw200004
	
	.include "SysCalls.asm"
	
	.data
	.eqv bufsize, 800
buffer:	.space bufsize

prompt1:	.asciiz "Enter a double-precision number: "
promptS:	.asciiz "\n"
promptSm:	.asciiz "Sum: "
promptAg:	.asciiz "\nAverage: "

	.text

main:
	# ask user for a double precision number
	# if the value is 0, then call 2 functions
	# else keep looping until value is 0, storing nums in the buffer

	la	$a1, buffer		# address of input buffer
	add	$a2, $a1, $zero		# copy of the input buffer address, used for resetting back to the starting position
	add	$s0, $zero, $zero		# zero out the register to store number of elements
	la	$a0, prompt1		# load the address of the prompt for "Please enter a double-precision number: " into the argument register
loop:
	li	$v0, SysPrintString		# load SysPrintString into $v0 to print the argument register
	syscall				# outputs "Please enter a double-precision number: " into the console

	li	$v0, SysReadDouble		# load SysReadDouble into $v0 to get double input from the console
	syscall					
	
	mfc1.d	$t1, $f0			# move the top half of the double-pres float value inputted by the user into $t1
	
	bnez	$t1, iterate		# if the top half of the double-precision is not 0, then iterate to store value and get next
	mfc1.d	$t1, $f1			# move the bottom half of the double-pres float value inputted by the user into $t1
	bnez	$t1, iterate		# if the bottom half of the double-precision is not 0, then iterate to store value and get next
	
	# if both registers are 0, then prepare to call the sort function
	
	move	$a0, $s0			# $a0 must contain the size as a parameter of the function
	move	$a1, $a2			# make $a1 point back to beginning of array
	li	$t4,  0			# set $t4 to 0, if value remains 1 after an iteration or bubble sort then no swaps were made
	
	# call functions to sort and print the given float values
	jal sortFunc			# sort the contents of the array
	jal printFunc			# print the contents of the sorted array
	j exit				# exit the program once completed
	
iterate:
	s.d	$f0, ($a1)		# if the value is not zero, then store it as a double-precision float in the "array"
	sb	$t1, ($a1)		# store the first element into the "array"
	addi	$s0, $s0, 1		# increment the size tracking register
	addi	$a1, $a1, 8		# move the pointer to the next double-sized space in the "array"
	j loop				# continue looping until the user inputs 0




sortFunc:
	# bubble sort: inner loop until size-1, get element and element+1, compare w/ <,
	# if element > element+1, then use a temp register to swap them (sb back into array)
	# once the size-1 is reached, if any swaps have been made then loop again
	# loop until there have been no swaps (array is fully sorted), then return to main with jr $ra

	# $t0 and $t1 will be element at index and index+1 respectively, $t3 will track the indexes
	# $t4 is a flag for checking if swaps were done, $a0 is the size, $a1 is the address of the "array"
	
	beq	$t4, 1, sortReturn		# if value is still 1, then no swaps were made, go back to main
	
	li	$t4, 1			# reset value to 1 and check after iterations
	addi	$t3, $zero, 1		# acts as an iterator for indexes, reset to 1 so that iteration only goes to size-1 (because looping to index+1)
	move	$a1, $a2			# reset pointer to top of the array for next run of sort
sortLoop:
	beq	$t3, $a0, sortFunc		# if iterator gets to size amount, then go back to top of the array and evaluate
	l.d	$f0, ($a1)		# get first float value from memory into float register
	l.d	$f10, 8($a1)		# get first float value from memory into float register
	c.lt.d 	$f10, $f0			# if values are out of order (should be $f0 < $f10, they are swapped in this case), then need to swap

	# check result of c.lt.d by checking whether coprocessor condition flag is 1 0r 0, if 1 then values need to be swapped
	bc1t	swap			# check value of coprocessor flag, if the floats are out of order, then swap them
		
	j	sortIterate		# update values to loop next iteration
swap:
	s.d	$f10, ($a1)		# load double float from index+1 into index
	s.d	$f0, 8($a1)		# load double float from index into index+1
	li	$t4, 0			# switch flag for determining that swaps were made during this iteration

sortIterate:
	addi	$a1, $a1, 8		# make $a1 point to next index in the array
	addi	$t3, $t3, 1		# add one to the iterator to correlate with pointer movement
	
	j sortLoop			# jump back to reloop

sortReturn:
	jr	$ra			# jump back to main



printFunc:
	# first reset pointer to top of the array
	# then in printLoop, first check if end of array has been reached
	# loop thru array indexes, load element into float register
	# use syscall to print float register contents to console
	# move array pointer to next element, jump back to printLoop and check if end of array has been reached
	# once end has been reached, move the sum into the print float register and print it,
	# then use the number of elements converted to a float value to divide the sum and print the average
	# exit
	
	move	$a1, $a2			# make $a1 point back to beginning of array
	add	$t3, $zero, $zero		# reset iterator to 0
	mtc1	$a0, $f4			# put the count into a float register so float operations can be performed
	cvt.d.w	$f4, $f4			# convert the count to a float value to be divded for average later
	
	add	$s0, $a0, $zero		# copy the count into $s0 so prompts can be used with $a0 simultaniously
	# i know this step is innecessary and makes the code cluttered changing the values of $a0, but
	# without it, the console is too clutered. If it were up to me, I just wouldn't store the element
	# count in $a0 but it's required in the problem, so this is my solution to organizing the output
	
printLoop:
	beq	$t3, $a0, finalPrint	# if the iterator reaches the number of elements, do final prints
	l.d	$f12, ($a1)		# load the first index float into the print float register - $f12	
	add.d	$f2, $f2, $f12		# add up floats into float register storing the sum
	cvt.w.d	$f12, $f12		# convert value to an integer so it looks nice when we print it
	
	
	li	$v0, SysPrintDouble		# load command to print double stored in $f12 to the console
	syscall				# printing a double because integer conversion combines both float registers into one
	
	la	$a0, promptS		# this just functions as a newline so values aren't all packed together
	li	$v0, SysPrintString
	syscall
	
	addi	$a1, $a1, 8		# make $a1 point to next index in the array
	addi	$t3, $t3, 1		# add one to the iterator to correlate with pointer movement
	move	$a0, $s0			# reset $a0 to be the size
	j printLoop			# jump back to reloop
finalPrint:
	la	$a0, promptSm		# prints out "Sum: " to indicate that the next value is not just another one in the list
	li	$v0, SysPrintString
	syscall
	
	li	$v0, SysPrintDouble		# load command to print double stored in $f12 to the console
	mov.d	$f12, $f2			# move the sum into the print float register
	cvt.w.d	$f12, $f12		# convert the sum float value into an integer to print
	syscall
	
	la	$a0, promptAg		# prints out "Average: " to indicate that the next value is not just another one in the list
	li	$v0, SysPrintString
	syscall
	
	li	$v0, SysPrintDouble		# load command to print double stored in $f12 to the console
	div.d	$f12, $f12, $f4		# divide the average by the count converted to a float value
	cvt.w.d	$f12, $f12		# convert the average float value into an integer to print
	syscall

	jr	$ra			# jump back to the return address in main



exit:
	li	$v0, SysExit
	syscall
