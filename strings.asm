.arm
.ifndef STRINGS_ASM
.set STRINGS_ASM, 1

.equ	STRINGS_NUM, 		0x30	// '0'
.equ	STRINGS_NULL_TERM,	0x00	// '\0'

.global strings_strcpy
.global strings_strcat
.global strings_strlen
.global strings_convert_int_to_cstring

.text

/* int strlen(char *s1)
 * @char *s1: cstring to count the length of
 * @returns -> int: the length of the cstring
 * */
strings_strlen:
	mov r1, r0
strings_strlen_loop:
	ldrb r2, [r0], #1
	cmp r2, #0
	bne strings_strlen_loop
	sub r0, r0, r1
	sub r0, #1
	bx lr
	
/* void my_strcpy(char *dest, char *src)
 * @char *dest: destination cstring to copy to
 * @char *src: source to copy from
 * */
strings_strcpy:
	ldrb r2, [r1], #1 
	strb r2, [r0], #1
	cmp r2, #0 
	bne strings_strcpy
	bx lr

/* Concetanates the s2 to s1, we expect that s1 has enough space for s2. */
/* void strcat(char *s1, char *s2)
 * @char *s1: string to attach the other string to
 * @char *s2: the other string to attach to the first string
 * */
strings_strcat:	
	push {fp, lr}
/* we first need to get to the end of the first string */
strings_strcat_get_to_end:
	ldrb r2, [r0], #1	// r4 = *(s1++)
	cmp r2, #0		// r4 == /0 ?
	bne strings_strcat_get_to_end	// if not at the end then repeat	
	sub r0, #1
strings_strcat_end:
	bl strings_strcpy
	pop {fp, lr}
	bx lr

/* Same as c standard lib.
 * int strcmp(char *s1, char *s2)
 * @char *s1: first string to compare
 * @char *s2: second string to compare
 * @returns -> int: difference of last character
 * */
strings_strcmp:
	ldrb r2, [r0], #1	// we need to store both values in registers
	ldrb r3, [r1], #1
	sub r3, r2, r3		// we do s[i] - t[i]
	cmp r2, #0		// first we check if we are at the end of the first string
	beq strings_strcmp_end	// if so, then we end it and return the last difference
	cmp r3, #0		// we check the difference against zero
	beq strings_strcmp	// if its equal then we continue looping
strings_strcmp_end:
	mov r0, r3
	bx lr

// NOTE theres probably a smarter way
/* I32 strings_convert_int_to_cstring(I32 val, char *buffer)
 * @I32 val: value to convert
 * @char *buffer: buffer to write the result to (expected to be able to hold the string)
 * */
strings_convert_int_to_cstring:
	push {r4, r5, r6}

	mov r2, r1        	// r2 = buffer
	mov r3, #10
	mov r6, #0		// length counter 

strings_convert_int_to_cstring_loop:
	add r6, r6, #1
	sdiv r4, r0, r3       	// r4 = quotient
	add r5, r4, r4, lsl #3
	add r5, r4
	sub r5, r0, r5       	// r5 = remainder
	add r5, r5, #'0'     	// digit

	strb r5, [r2], #1     	// store and increment

	mov r0, r4
	cmp r0, #0
	bne strings_convert_int_to_cstring_loop

	// now reverse the string
	mov r0, r1        // start
	sub r2, r2, #1    // end = last char

strings_convert_int_to_cstring_reverse:
	cmp r0, r2
	bge done

	ldrb r3, [r0]
	ldrb r4, [r2]
	strb r4, [r0]
	strb r3, [r2]

	add r0, r0, #1
	sub r2, r2, #1
   	b strings_convert_int_to_cstring_reverse

done:
	mov r3, #0
	strb r3, [r1,r6]
	mov r0, r6
    	pop {r4, r5, r6}
	bx lr
	
.endif /* STRINGS_ASM */
