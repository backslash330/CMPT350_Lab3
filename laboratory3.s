.data
initial_message: .asciiz "This program will approximate the cubed root of a number using Newton's method."
y_prompt: .asciiz "Enter a number (y) to approximate the cubed root of: "
x0_prompt: .asciiz "Enter an initial guess (x0) for the cubed root: "
result_message: .asciiz "The approximate cubed root of y is: "
nl: .asciiz "\n"
.text

cuberoot:
	# This function does the approximation of the cubed root of y using Newton's method.
	# error tolerance is 3 mantissa bits.
	# this means that the difference between the last two approximations must be less than 0.125
	# do arithmetic in floating point coprocessor
	# return the value in $f31 (the last floating point register)
	
	# put the numbers from the a registers into the floating point registers
	# convert the integer to a float
	mtc1 $a0, $f0
	mtc1 $a1, $f1
	cvt.s.w $f0, $f0
	cvt.s.w $f1, $f1
	# put 3 and 0 into the coprocessor
	li $t0, 3
	mtc1 $t0, $f2
	mtc1 $zero, $f7
	cvt.s.w $f2, $f2
	# put 0.125 into the coprocessor


	# do the approximation ( do not overwrite the initial guess )
newton:
	# xn^3 - y
	mul.s $f3, $f1, $f1
	mul.s $f3, $f3, $f1
	sub.s $f3, $f3, $f0

	# 3xn^2
	mul.s $f4, $f1, $f1
	mul.s $f4, $f4, $f2

	# xn - xn^3/y * 3xn^2
	div.s $f5, $f3, $f4
	sub.s $f6, $f1, $f5

	# compare the difference between the last two approximations
	# pull the approximations out of the coprocessor
	mfc1 $t0, $f1
	mfc1 $t1, $f6

	# make sure that the mantissa bits are the same except for the last 3
	# if they are, then the difference is less than 0.125
	# if they are not, then the difference is greater than 0.125


	# I am only concerned about the first 20 bits of the mantissa
	# so I isolate them by shifting left 9, then right 9
	sll $t0, $t0, 9
	sll $t1, $t1, 9
	srl $t0, $t0, 9
	srl $t1, $t1, 9

	# if the difference is less than 0.125, then we are done
	xor $t2, $t0, $t1
	# put 7 in $t3
	li $t3, 8

	# if the difference is 0, we are done
	blt $t2, $t3, newton_done

	# put the latest approximation into f1
	add.s $f1, $f6, $f7
	j newton

newton_done:
	# otherwise, put the latest approximation from f6 into f31 and return
	add.s $f31, $f6, $f7
	jr $ra

main:
	# display initial message
	li $v0, 4
	la $a0, initial_message
	syscall

	# nl 
	li $v0, 4
	la $a0, nl
	syscall

	# prompt for y
	li $v0, 4
	la $a0, y_prompt
	syscall

	# read y
	li $v0, 5
	syscall

	# put y into $s0
	move $s0, $v0

	# prompt for x0
	li $v0, 4
	la $a0, x0_prompt
	syscall

	# put x0 in $t1
	li $v0, 5
	syscall

	# put x0 into $s1
	move $s1, $v0

	# put the variables into arugment registers
	move $a0, $s0
	move $a1, $s1

	# call cuberoot
	jal cuberoot

	# display result message
	li $v0, 4
	la $a0, result_message
	syscall

	# move the result into f12 and print it
	mov.s $f12, $f31
	li $v0, 2
	syscall


	# display newline
	li $v0, 4
	la $a0, nl


	li $v0, 10
	syscall
