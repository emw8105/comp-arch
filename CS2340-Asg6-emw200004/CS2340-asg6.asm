# Program is able to encrypt and decrypt files given by the user using a key specified by the user.
# First the user chooses to encrypt or decrypt, then the user provides the name of the file, which
# the program validates, then the user provides the key to encrypt or decrypt with, which the program
# also validates. Then, the inputted file's contents are iterated through and either added or subtracted
# depending on whether the program is encrypting or decrypting, and then stores the now encrypted
# or decrypted data into a correspondingly named output file.
# Written by Evan Wright for CS2340.006, assignment 6, starting November 10th, 2022
# NetID: emw200004

	.include "SysCalls.asm"
	
	.data
menu:	.asciiz "1 - Encrypt the file\n2 - Decrypt the file\n3 - Exit\n"
prompt1:	.asciiz "Please enter a file name: "
prompt2:	.asciiz "File does not exist, please try again\n"
prompt3:	.asciiz "Please enter a key: "
prompt4:	.asciiz "Key is length 0, please try again\n"
	.eqv nameSize, 255
	.eqv keySize, 60
	.eqv fileSize, 1024
	.eqv writeSize, 255
fileName:	.space nameSize		# creates a space to save the name of the input file
key:	.space keySize		# creates a space to save the key
inptSpce:	.space fileSize		# creates a space to save the input file contents
writeName:.space writeSize		# creates a space to store the name of the output file


	.text
main:
	la	$a0, menu			# load the address of the prompt for the menu list into the argument register
	li	$v0, SysPrintString		# load SysPrintString into $v0 to print the argument register
	syscall
	
	li	$v0, SysReadInt		# load SysReadInt to get the menu option from the user
	syscall
	
	bne	$v0, 1, notOne		# if the user choice is 1, go to the encrypt function
	jal  encrypt
notOne:
	bne	$v0, 2, notTwo		# if the user choice is 2, go to the decrypt function
	jal  decrypt
notTwo:
	bne	$v0, 3, notThree		# if the user choice is 3, exit
	li	$v0, SysExit
	syscall
notThree:	
	# if anything other than 3, will fall through eventually to reprint menu choices and iterate
	
	
	# AFTER CALLING FUNCTIONS, MUST CLEAR THE SPACE FOR KEY AND FILENAME SO LEFTOVER CHARACTERS DON'T MESS UP STUFF
	# THE BUFFER FOR THE FILE DOESN'T NEED TO BE CLEARED BECAUSE IT WILL LOAD ALL NULL TERMINATORS FOR EVERY FINAL LOAD
	j main


encrypt:

	la	$a0, prompt1		# prompt user for a file name input
	li	$v0, SysPrintString
	syscall
	
	li	$v0, SysReadString		# read the name of the file from the user
	la	$a0, fileName		# put the address for the space declared for the name of the file into the argument
	li	$a1, nameSize		# max number of characters to read is 255, the fileSize
	syscall
	
	move	$s0, $a0			# store the address of the file name in $s1
	addi	$sp, $sp, -4		# reserve space on the stack for 1 value
	sw	$ra, 0($sp)		# store the return address onto the stack
	
	jal fileClean			# jump to the function to clean the file
	move	$s3, $v0			# move the file descriptor for the input file into $s3
	move	$s1, $v1			# move the file name's length (the iterator) into $s1
	
	# at this point, file has been opened as is valid, now get the key from the user and validate it
	la	$a0, prompt3		# prompt user for a key
	li	$v0, SysPrintString
	syscall
	
	li	$v0, SysReadString		# read the key from the user
	la	$a0, key			# put the address for the space declared for the key into the argument
	li	$a1, keySize		# max number of characters to read is 60, the keySize
	syscall
	
	jal keyCheck			# jump to function 
	move	$s2, $a0			# the key is valid and its address is saved into $s2
validEnc:
	# address for file name is in $s0, length of file is in $s1, key is in $s2
	
	# get the output file name address into a register
	la	$a0, writeName		# puts the address for the space allocated for the output file name into $a0
	add	$t1, $zero, $zero		# zero out the iterator
	jal copyName			# jump to function, will copy the name of the file up to the '.'
	
	li	$t0, 'e'
	sb	$t0, 0($a0)
	li	$t0, 'n'
	sb	$t0, 1($a0)
	li	$t0, 'c'
	sb	$t0, 2($a0)
	li	$t0, '\0'
	sb	$t0, 3($a0)
	
	la	$a0, writeName		# point the address back to the beginning of the file name
	li	$a1, 1			# set mode to be for writing to a file
	
	jal	fileOpen			# $a0 has output file name, $a1 has write-to flag, use function to open
	move	$s4, $v0			# move the output file descriptor into $s4
	
	la	$s1, writeName		# store address of now-opened output file name into $s1
	
	# at this point, address of input file name is in $s0, address of output file name is in $s1, address of key is in $s2
	# file descriptor for input file is in $s3, file descriptor for output file is in $s4
	
encRead:
	# call a function to read 1024 bytes (fileSize) from the input file into the inptSpce buffer
	# if zero characters are read, then end of file is reached so exit loop?
	# else then parse through the elements in the buffer and the key at the same time and add (unsigned) indexes correspondingly
	# call a function to write the encrypted 1024 bytes in the buffer to the output file
	# reloop
	jal readInputFile
	beqz 	$v0, finishEnc 		# if number of characters read returned is 0 then end of file is reached
	move	$t3, $v0			# num characters read moved into $t3 so read/write using $v0 not overwriting counter
	add	$t2, $zero, $zero		# zero out iterator (also resets iterator if new file input is read)
encKeyParse:
	lb 	$t0, 0($s2)		# load byte from the key and store it in $t0
	bne	$t0, '\n', keyEncCont	# if the value is a null terminator, execute the following instead of continuing
	la	$s2, key			# reset the pointer to the address of the key
	lb	$t0, 0($s2)		# get the next byte after the address was reset
keyEncCont:
	lb	$t1, 0($a1)		# load byte from the input file buffer
	addu	$t1, $t1, $t0		# add the bytes together with overflow to encrypt it
	sb	$t1, 0($a1)		# add the encrypted byte into the buffer
	addi	$s2, $s2, 1		# increment the address of the key to point to the next value
	addi	$a1, $a1, 1		# increment the address of the file buffer
	addi	$t2, $t2, 1		# increment the iterator
	bne	$t2, $t3, encKeyParse	# loop until all values in the file buffer have been encrypted
	# if iterator = num bytes read, fall through to output encrypted contents to file and then read in more bytes
	jal writeOutputFile			# write the encrypted file buffer to the output file
	beq	$t3, 1024, encRead		# if characters read are less than max buffer size, then file reading is done
	
finishEnc:
	# once loop is done, close both files and return to main
	move	$a0, $s3			# put the input file descriptor into $a0
	li	$v0, SysCloseFile		# load value to close the given file into $v0
	syscall				# close the input file
	
	move	$a0, $s4			# put the output file descriptor into $a0
	# value to close file already loaded into $v0
	syscall				# close the output file

	lw	$ra, 0($sp)		# restore the return address saved on the stack to return to main
	addi	$sp, $sp, 4		# move pointer in the stack accordingly
	
	jr $ra

decrypt:
	la	$a0, prompt1		# prompt user for a file name input
	li	$v0, SysPrintString
	syscall
	
	li	$v0, SysReadString		# read the name of the file from the user
	la	$a0, fileName		# put the address for the space declared for the name of the file into the argument
	li	$a1, nameSize		# max number of characters to read is 255, the fileSize
	syscall
	
	move	$s0, $a0			# store the address of the file name in $s1
	addi	$sp, $sp, -4		# reserve space on the stack for 1 value
	sw	$ra, 0($sp)		# store the return address onto the stack
	
	jal fileClean			# jump to the function to clean the file
	move	$s3, $v0			# move the file descriptor for the input file into $s3
	move	$s1, $v1			# move the file name's length (the iterator) into $s1
	
	# at this point, file has been opened as is valid, now get the key from the user and validate it
	la	$a0, prompt3		# prompt user for a key
	li	$v0, SysPrintString
	syscall
	
	li	$v0, SysReadString		# read the key from the user
	la	$a0, key			# put the address for the space declared for the key into the argument
	li	$a1, keySize		# max number of characters to read is 60, the keySize
	syscall
	
	jal keyCheck			# jump to function 
	move	$s2, $a0			# the key is valid and its address is saved into $s2
validDec:
	# address for file name is in $s0, length of file is in $s1, key is in $s2
	
	# get the output file name address into a register
	la	$a0, writeName		# puts the address for the space allocated for the output file name into $a0
	add	$t1, $zero, $zero		# zero out the iterator
	jal copyName			# jump to function, will copy the name of the file up to the '.'
	
	li	$t0, 't'
	sb	$t0, 0($a0)
	li	$t0, 'x'
	sb	$t0, 1($a0)
	li	$t0, 't'
	sb	$t0, 2($a0)
	li	$t0, '\0'
	sb	$t0, 3($a0)
	
	la	$a0, writeName		# point the address back to the beginning of the file name
	li	$a1, 1			# set mode to be for writing to a file
	
	jal	fileOpen			# $a0 has output file name, $a1 has write-to flag, use function to open
	move	$s4, $v0			# move the output file descriptor into $s4
	
	la	$s1, writeName		# store address of now-opened output file name into $s1
	
	# at this point, address of input file name is in $s0, address of output file name is in $s1, address of key is in $s2
	# file descriptor for input file is in $s3, file descriptor for output file is in $s4
decRead:
	# call a function to read 1024 bytes (fileSize) from the input file into the inptSpce buffer
	# if zero characters are read, then end of file is reached so exit loop
	# else then parse through the elements in the buffer and the key at the same time and subtract (unsigned) indexes correspondingly
	# call a function to write the decrypted 1024 bytes in the buffer to the output file
	# reloop
	jal readInputFile
	beqz 	$v0, finishDec 		# if number of characters read returned is 0 then end of file is reached
	move	$t3, $v0			# num characters read moved into $t3 so read/write using $v0 not overwriting counter
	add	$t2, $zero, $zero		# zero out iterator (also resets iterator if new file input is read)
	
decKeyParse:
	lb 	$t0, 0($s2)		# load byte from the key and store it in $t0
	bne	$t0, '\n', keyDecCont	# if the value is a null terminator, execute the following instead of continuing
	la	$s2, key			# reset the pointer to the address of the key
	lb	$t0, 0($s2)		# get the next byte from the key after the address was reset
keyDecCont:
	lb	$t1, 0($a1)		# load byte from the input file buffer
	subu	$t1, $t1, $t0		# subtract the input byte by the key byte with overflow to decrypt it
	sb	$t1, 0($a1)		# add the decrypted byte into the buffer
	addi	$s2, $s2, 1		# increment the address of the key to point to the next value
	addi	$a1, $a1, 1		# increment the address of the file buffer
	addi	$t2, $t2, 1		# increment the iterator
	bne	$t2, $t3, decKeyParse	# loop until all values in the file buffer have been decrypted, i.e. iterator = num bytes read
	# if iterator = num bytes read, fall through to output decrypted contents to file and then read in more bytes
	jal writeOutputFile			# write the now-decrypted file buffer to the output file
	beq	$t3, 1024, decRead		# if characters read are less than max buffer size, then file reading is done
	# else reloop and read in a new block of data from the input file	
	
finishDec:
	# once loop is done, close both files and return to main
	move	$a0, $s3			# put the input file descriptor into $a0
	li	$v0, SysCloseFile		# load value to close the given file into $v0
	syscall				# close the input file
	
	move	$a0, $s4			# put the output file descriptor into $a0
	# value to close file already loaded into $v0
	syscall				# close the output file

	lw	$ra, 0($sp)		# restore the return address saved on the stack to return to main
	addi	$sp, $sp, 4		# move pointer in the stack accordingly
	
	jr $ra

fileClean:
	# loop through the buffer containing the name of the file
	# once the null terminator is found, replace it with a 0
	# use an iterator to track the size of the name
	# save the value of the iterator into $v0, return
	
	addi	$t0, $zero, '\n'		# stores null terminator into $t0
	add	$v1, $zero, $zero		# use $v1 as an iterator because its value will be returned
findNullTerm:
	lb	$t1, 0($a0)		# load character from the string into $t1
	beq 	$t1, $t0, cleanReplace	# if the character is a null terminator, replace it with a 0
	addi	$v1, $v1, 1		# otherwise, add one to the iterator
	addi	$a0, $a0, 1		# shift to the next character in the string correspondingly
	b findNullTerm			# continue iterating until the null terminator is found
cleanReplace:
	sb	$zero, 0($a0)		# replace the null terminator with a 0 so file can be opened
	la	$a0, fileName		# point the address back to the beginning of the file name
	li   	$a1, 0        		# Open for reading (flags are 0: read, 1: write)
fileOpen:
	# these elements are common to both input and output file openings because the both use this function call
	li	$a2, 0			# mode is ignored in mips but can't hurt to zero the register out at least
	li	$v0, SysOpenFile		# file descriptor/name is already in $a0
	syscall
	
	blt	$v0, $zero, errorFile	# if the file is not found, $v0 will be negative
	jr $ra				# file had no errors and is valid, return to caller function
errorFile:
	la	$a0, prompt2		
	li	$v0, SysPrintString		# print prompt2 displaying error for file not found
	syscall
	j main				# return to main to redisplay the menu and get new user input
	
	
keyCheck:
	addi	$t0, $zero, '\n'		# stores null terminator into $t0
	lb	$t1, 0($a0)		# load character from the string into $t1
	beq 	$t1, $t0, invalidKey	# if first character is a null terminator, then length is 0, so key is invalid
	jr $ra				# else, key is valid, so return to main
invalidKey:
	la	$a0, prompt4		
	li	$v0, SysPrintString		# print prompt4 displaying error for file not found
	syscall
	j main				# return to main to redisplay the menu and get new user input
	

copyName:
	# output file is in $a0, copy input file name from address in $s0 until the '.'
	lb	$t0, 0($s0)		# get element from file name at given address
	beq	$t0, '.', finalCopy		# if a period is found, do one last copy
	sb	$t0, 0($a0)		# copy element to output file name
	addi	$s0, $s0, 1		# move to next byte
	addi	$a0, $a0, 1		# move to next byte
	b	copyName			# keep looping until the period is found
finalCopy:
	# do the last sb into $a0, reset input file address so it reads from the start later
	sb	$t0, 0($a0)		# copy element to output file name
	la	$s0, fileName		# reset input file address
	addi	$a0, $a0, 1		# move to next byte for output file
	# we don't reset the output file address because we want to add the new extension first
	jr $ra				# return to caller function
	# the caller functions will add whichever extension is required (either .enc for encrypt or .txt for decrypt)

readInputFile:
	move	$a0, $s3			# put file descriptor for input file in $a0
	la	$a1, inptSpce		# address of buffer for 1024 characters in $a1
	la	$a2, fileSize		# max number of characters to write (1024) in $a2
	li	$v0, SysReadFile		# load syscall for reading the given file into $v0
	syscall				# will execute command to read 1024 characters from the input file into the buffer
	jr $ra

writeOutputFile:
	#  $s4 is file descriptor for the output file, $t3 is the num bytes read
	move	$a0, $s4			# put file descriptor for output file in $a0
	la	$a1, inptSpce		# address of buffer for 1024 characters in $a1
	add	$a2, $t3, $zero		# number of bytes to write should be the number of bytes read into the buffer
	li	$v0, SysWriteFile		# load syscall for reading the given file into $v0
	syscall				# will execute command to write 1024 characters from the buffer into the output file
	jr $ra