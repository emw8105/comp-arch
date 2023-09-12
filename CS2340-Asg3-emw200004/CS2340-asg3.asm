# Program dynamically allocates a block of data sized by the user, then sets the block of data to all hex FF, i.e. all bits within the byte
# are turned on. Then program iterates through the block of data checking every numbers divisible by 2, 3, 4... until the program gets to numbers
# divisible by half of the array size, then prints out the bits representing them as prime numbers, so should print: 2, 3, 5, 7, 11, 13, up to
# the closest prime number to the user specified number
# Written by Evan Wright for CS2340.006, assignment 3, starting September 28th, 2022
# NetID: emw200004

# If you are reading this, I have worked on this every day since starting for multiple hours, and today, October 5th, I have spent 9+ hours on 
# this and this alone, nothing else but this. At long last, I have gotten to the end, and although the output is incorrect, I'm not 
# even sure where to begin debugging something of this complexity. I have written long blocks of comments to help myself understand what I wanted 
# each section to do before I wrote it, and I will leave what remains of those sections in so that I might at least get partial credit for 
# demonstrating an understanding of the topics we're working with, even if my program ultimately got the wrong answer.

	.include "SysCalls.asm"		# symbolic names instead of magic numbers for syscalls

	.data
prompt1:	.asciiz	"Enter a number: "
prompt2:	.asciiz	"Number is outside of range, please try again\n"
prompt3:	.ascii	", "
	.text
initial:
	move 	$a0, $zero		# reset registers
	move	$v0, $zero
	
	li	$v0, SysPrintString		# load number for reading a string
	la	$a0, prompt1		# load the address of the prompt for "Enter a number: " into $a0
	syscall				# prints the prompt to the console ("Enter a number: ")
	
	li	$v0 SysReadInt		# read int from user and return into $v0
	syscall
	
	blt	$v0, 3, error		# if entered value is less than min value (3), output error
	bgt	$v0, 160000, error		# if entered value exceeds max value (160000), output error
	
	# allocate array of bits of size given
	add	$t0, $zero, $v0		# store value of $v0 into $a0 as the validated size of the array
	andi	$t1, $t0, 7		# AND the size with 7 to isolate the last digits
	srl	$t0, $t0, 3		# get the size (# of bits) divided by 8 (# of bytes)
	beqz	$t1, allocate		# if the last digits are anything except 0, then add 1 to the size of bytes before allocating
	addi	$t0, $t0, 1		# increment the number of bytes by 1 to account for the rounding
	
	
allocate:
	move	$t3, $t0			# store the size of the array (in bits) into $t3
	move	$a0, $t0			# put the total number of bytes to allocate into $a0
	li	$v0, SysAlloc		# allocate number of bytes specified in $a0 to an array and return address in $v0
	syscall
	add	$t0, $zero, $v0		# move address of array from $v0 to $t0
	add	$t2, $zero, $zero		# initialize iterator to 0
	addi	$t5, $zero, 1		# initialize position increment (starts with multiples of 2, other 1 added in loop)
	srl	$t6, $t3, 1		# set $t6 to n/2, the termination point of the loop
	
	addi	$t1, $zero, 0xFF		# let $t1 be a byte containing 0xFF used to fill the array in the next section
	
	# $t0 is the address, $t1 is the current element, $t2 is the iterator, $t3 is the size, $t5 is position increment, $t6 is n/2 terminate point
fill:
	sb	$t1, ($t0)		# store 0xFF into the array at the currently pointed to index
	addi	$t0, $t0, 1		# point to the next element in the array
	addi	$t2, $t2, 1		# add one to the iterator
	blt	$t2, $t3, fill		# until the iterator = the array size, keep filling the array with 0xFF

	sub	$t0, $t0, $t2		# subtract iterations from array pointer to make it point to beginning of array again
	move	$t2, $zero		# reset iterator
	addi	$s0, $zero, 8		# this register will be used to divide the iterator by 8 to get the quotient and remainder
	
positionloop:
	add	$t0, $v0, $zero		# point to the first element in the array
	addi	$t5, $t5, 1		# add one to position counter
	add	$t2, $zero, $t5		# $t2 will iterate based on the position counter
	sll	$t2, $t2, 1		# multiply position by 2 (every num is divisible by itself so we want the second number)
	addi	$t2, $t2, 1		# add one to correspond to the numbers instead of the index
	
byteloop:
	# $t0 = the array, $t2 is the iterator, $s1 = array / 8 (the byte index), $s2 = array % 8 (the bit index)
	srl	$s1, $t2, 3		# effectively divide by 8 cutting off rounding, stores index of byte to go to
	andi	$s2, $t2, 7		# mask the remainder to determine the bit index within the byte
	beqz	$s2, noremainder		# if there is is no remainder, skip the increment
	addi	$s1, $s1, 1		# else if there is a remainder, increment the byte to travel to by one
noremainder:
	# just realized we can't use normal division
	#div	$t2, $s0			# divide the iterator by 8 to find the byte to go to and the bit within the byte
	#mflo	$s1			# store the index of the byte to go to
	#mfhi	$s2			# store the index of the bit within the byte to go to
	
	add	$t0, $t0, $s1		# add the index of the byte to the address of the array so it points to that byte
	lbu	$t1, ($t0)		# load byte from the array element, now do bit manipulation on byte
	
	beq	$s2, 0, maskone		# if the index of the byte is 1, branch to label to mask first bit
	beq	$s2, 1, masktwo		# if the index of the byte is 2, branch to label to mask second bit
	beq	$s2, 2, maskthree		# if the index of the byte is 3, branch to label to mask third bit
	beq	$s2, 3, maskfour		# if the index of the byte is 4, branch to label to mask fourth bit
	beq	$s2, 4, maskfive		# if the index of the byte is 5, branch to label to mask fifth bit
	beq	$s2, 5, masksix		# if the index of the byte is 6, branch to label to mask sixth bit
	beq	$s2, 6, maskseven		# if the index of the byte is 7, branch to label to mask seven bit
	beq	$s2, 7, maskeight		# if the index of the byte is 0, branch to label to mask eight bit (divisible by 8 is remainder 0)
postmask: ## after getting appropriate mask based on bit position, use mask on byte to change bit to 0 with logical and
	and	$t1, $t1, $s3		# use logical AND with the mask to change bit to 0
	sb	$t1, ($t0)		# store byte back into array
	
	add	$t2, $t2, $t5		# increment the iterator based on the position index to get the next prime bit number
	blt	$t2, $t3, byteloop		# if the iterator is less than the size of the array, keep looping
	ble	$t5, $t6, positionloop	# if the position increment hasn't reached halfway in the array, get next position increment
	# if the last element of the last divisible number (n/2) has been divided, these branches will finally fall out of the nested loops
	
	move	$t0, $v0			# reset pointer to array back to first element
	addi	$t2, $zero, 2		# reset iterator to 2 (won't be printing 0 or 1, so start at 2)
	j	print			# jump to print to display the result of the bit manipulation

maskone:
	li	$s3, 254			# number corresponding to the byte amount for 1111 1110, trying to find bit in first position
	j	postmask
masktwo:
	li	$s3, 253			# number corresponding to the byte amount for 1111 1101, trying to find bit in second position
	j	postmask
maskthree:
	li	$s3, 251			# number corresponding to the byte amount for 1111 1011, trying to find bit in third position
	j	postmask
maskfour:
	li	$s3, 247			# number corresponding to the byte amount for 1111 0111, trying to find bit in fourth position
	j	postmask
maskfive:
	li	$s3, 239			# number corresponding to the byte amount for 1110 1111, trying to find bit in fifth position
	j	postmask
masksix:
	li	$s3, 223			# number corresponding to the byte amount for 1101 1111, trying to find bit in sixth position
	j	postmask
maskseven:
	li	$s3, 191			# number corresponding to the byte amount for 1011 1111, trying to find bit in seventh position
	j	postmask
maskeight:
	li	$s3, 127			# number corresponding to the byte amount for 0111 1111, trying to find bit in eigth position
	j	postmask

print: 
	# $t0 is the address, $t1 is the current element, $t2 is the iterator, $t3 is the size, $t5 is position increment, $t6 is n/2 terminate point
	# $s1 is the quotient of the iterator i.e. the byte to travel to, $s2 is the remainder of the iterator, i.e. the bit to travel to
	addi	$t2, $t2, 1		# increment the iterator by 1 to look for the next bit
	bgt	$t2, $t3, exit		# if the increment amount is equal to the size, then exit the program

	#do remainder based devision, add to array for whole num, use mask of remainder num, subtract whole num at the end
	srl	$s1, $t2, 3		# effectively divide by 8 cutting off rounding, stores index of byte to go to
	andi	$s2, $t2, 7		# mask the remainder to determine the bit index within the byte
	#beqz	$s2, noremainder		# if there is is no remainder, skip the increment
	#addi	$s1, $s1, 1		# else if there is a remainder, increment the byte to travel to by one
	
	add	$t0, $t0, $s1		# make array point to the current byte we want to travel to
	lbu	$t1, ($t0)		# load the byte that we want to travel to from the array
	sub	$t0, $t0, $s1		# have array point back to beggining so iterator doesn't mess up
	
	beq	$s2, 0, smaskone		# if the index of the byte is 1, branch to label to mask first bit
	beq	$s2, 1, smasktwo		# if the index of the byte is 2, branch to label to mask second bit
	beq	$s2, 2, smaskthree		# if the index of the byte is 3, branch to label to mask third bit
	beq	$s2, 3, smaskfour		# if the index of the byte is 4, branch to label to mask fourth bit
	beq	$s2, 4, smaskfive		# if the index of the byte is 5, branch to label to mask fifth bit
	beq	$s2, 5, smasksix		# if the index of the byte is 6, branch to label to mask sixth bit
	beq	$s2, 6, smaskseven		# if the index of the byte is 7, branch to label to mask seven bit
	beq	$s2, 7, smaskeight		# if the index of the byte is 0, branch to label to mask eight bit (divisible by 8 is remainder 0)
maskprint:
	and	$t1, $t1, $s3		# use logical AND with the mask to change all values to 0 except the indexed bit
	beqz	$t1, print		# if the number was a 0 then the bit was a 0, reloop print and look for a prime number
	# syscall print int for the iterator, then syscall print string for prompt3
	li	$v0, SysPrintInt
	move	$a0, $t2
	syscall
	
	li	$v0, SysPrintString
	la	$a0, prompt3
	syscall
	j print
		
smaskone:
	li	$s3, 1			# number corresponding to the byte amount for 0000 0001, trying to isolate bit in first position
	j	maskprint
smasktwo:
	li	$s3, 2			# number corresponding to the byte amount for 0000 0010, trying to isolate bit in second position
	j	maskprint
smaskthree:
	li	$s3, 4			# number corresponding to the byte amount for 0000 0100, trying to isolate bit in third position
	j	maskprint
smaskfour:
	li	$s3, 8			# number corresponding to the byte amount for 0000 1000, trying to isolate bit in fourth position
	j	maskprint
smaskfive:
	li	$s3, 16			# number corresponding to the byte amount for 0001 0000 trying to isolate bit in fifth position
	j	maskprint
smasksix:
	li	$s3, 32			# number corresponding to the byte amount for 0010 0000, trying to isolate bit in sixth position
	j	maskprint
smaskseven:
	li	$s3, 64			# number corresponding to the byte amount for 0100 0000 trying to isolate bit in seventh position
	j	maskprint
smaskeight:
	li	$s3, 128			# number corresponding to the byte amount for 1000 0000, trying to isolate bit in eigth position
	j	maskprint
	
	### reset array pointer to 0, iterator to 0
	### load the byte of the wherever the array is pointing (the 0th byte if first iteration)
	### do iterator % 8 to determine which mask to use, then have 8 different jumps for 8 different new masks
	### masks should be 0000 0001 for first and 1000 0000 for the 8th?, logical AND it with the loaded byte
	### mask would be all 0's if the bit being tested was already 0
	### bne 0 to a printstring and then load the iterator and then syscall
	
exit:
	li	$v0, SysExit		# System exit
	syscall
	
error:
	li	$v0, SysPrintString		# load number for reading a string
	la	$a0, prompt2		# load the address of the prompt for "Number is outside of range, please try again" into $a0
	syscall	
	j	initial			# loop back to the beginning and try for another number


### positionloop plan:
	### will take nested loops, one tracks the position increment being iterated by, the other tracks the bit manipulation based on that position increment
	### calculate position index
	### to find bit position, divide position increment by 8, the lo is the byte to load, the hi is the bit within the byte
	### add position increment to iterator for each byte accessed, then do the same as above with the position increment + iterator
	### at each bit, use logical operators (AND) and a mask (1111 1110, 1111 1101, 1111 1011, etc.) based on the position of the bit found above
	### after masking, the bit should be isolated, check if eq to values based on its position, i.e. if using 1111 1011, check eq to 0000 0100 or 4
	### set bit at given position to 0 using branches to different masks based on the index
	### then loop back and add increment to iterator again, repeat until end of array is reached
	### then increment position increment and loop again until position increment = array size / 2