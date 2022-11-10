TITLE String Converter 

; Author: Matt Trimner
; Description: This program will take 10 signed numbers from a user, convert them from strings into integers,
; sum the integers and find a truncated average. It will then convert the integers back into strings and 
; print the numbers entered, the sum, and the average to the screen. It does all of this only using the two macros and two functions.
INCLUDE Irvine32.inc 

; --------------------------------------------------------------------------------- 
; Name: mGetString 
; 
; Prompts and gets the input from a user.
; 
; Preconditions: can only use WriteString and ReadString
;
; Postconditions: updates the userInput global variable
; 
; Receives: 
; prompt = text prompt for the user to enter a number
; charCount = number of characters a user can enter 
; userInput = the pointer ot the array that the user input is stored
; bytes = the number of characters the user entered 
; 
; returns: none
; --------------------------------------------------------------------------------- 
mGetString MACRO prompt, charCount, userInput, bytes
	push	EDX
	push	ECX
	push	EAX
	mov		EDX, prompt
	call	WriteString
	mov		EDX, userInput
	mov		ECX, charCount
	call	ReadString
	mov		userInput, EDX
	mov		bytes, EAX
	pop		EAX
	pop		ECX
	pop		EDX
ENDM

; --------------------------------------------------------------------------------- 
; Name: mDispalyString 
; 
; Prints the strings that is passed into it.
; 
; Preconditions: Must receive a string to print as a parameter
;
; Postconditions: uses and modified EDX
; 
; Receives: 
; printString = the address of the string that should be printed
; punctuation = receives either a comma or just a space
; 
; returns: none
; --------------------------------------------------------------------------------- 
MDisplayString MACRO printString, punctuation
	mov		EDX, printString
	call	WriteString
	mov		EDX, punctuation
	call	WriteString
ENDM

MIN = -2147483648  ; Minimun number allowed to fit in 32 bit register
MAX = 2147483647   ; Maximun number allowed to fit in 32 bit register

.data

intro1		BYTE "Welcome to String Converter, written by Matt Trimner.",13,10,0
intro2		BYTE "Please provide 10 signed decimal integers.",13,10
			BYTE "Each number needs to be small enough to fit inside a 32 bit register.",13,10
			BYTE "After you've finished inputting the raw numbers I will display a list of the integers, their sum, and their average value.",13,10,0
prompt		BYTE "Please enter a signed number: ",0
invalid		BYTE "ERROR: You did not enter a signed number or your number was too big.",13,10,0
inputText	BYTE "You entered the following numbers:",0
sumText		BYTE "The sum of these numbers is: ",0
avgText		BYTE "The truncated average is: ",0
outro		BYTE "Thanks for using this string converter. Goodbye!",13,10,0
comma		BYTE ", ",0
space		BYTE " ",0
newString	BYTE 12 DUP(0)
userInput	BYTE 15 DUP(0)    ; can hold -2147483648 to 2147483647, 32 bit size limit
byteCount	DWORD ?
charCount	DWORD 15          ; allows enough characters to enter -2147483648
numArray	SDWORD 10 DUP(?)
sum			SDWORD ?
average		SDWORD ?

; (insert variable definitions here)

.code
main PROC
	push	OFFSET intro2
	push	OFFSET intro1
	call	introduction
	mov		ECX, 10		; makes the loop run 10 times to collect the 10 numbers
	mov		EAX, 0

; This is the beginning of the MAIN loop that is required by the instructions for readVal
; It will loop 10 times calling readVal each time to get and validate the user input and store converted numbers in numArray
_getNumber:
	mov		EDI, OFFSET numArray	
	add		EDI, EAX		; Increment the index of the array of numbers (numArray)
	push	EAX				; Preserve the number of bytes into the array the loop is currently on
	push	ECX				; Preserve the loops counter
	push	EDI				; Pointer to address of the numArray index
	push	OFFSET invalid
	push	OFFSET byteCount
	push	charCount
	push	OFFSET prompt
	push	OFFSET userInput
	call	readVal
	pop		ECX
	pop		EAX
	add		EAX, TYPE numArray
	loop	_getNumber		;using a loop in the main function to collect the 10 numbers as required by the project instructions
	call	CrLF
	
; This is the second loop will loop through the array to get the sum, average, and print each number
	CLD
	mov		ECX, LENGTHOF numArray
	mov		ESI, OFFSET numArray
	mov		EDX, OFFSET inputText
	call	WriteString
	call	CrLF

; This piece of the loop will call the WriteVal procedure to print the values
_writeInt:	
	LODSD
	Add		sum, EAX
	cmp		ECX, 1
	je		_passSpace
	jmp		_passComma
; Will pass a comma as a parameter to the WriteVal procedure
_passComma:
	push	OFFSET comma
	jmp		_print
; Will pass a blank space as a parameter to the WriteVal procedure
_passSpace:
	push	OFFSET space
; Calls the WriteVal procedure which contains the MDisplayString macro and prints out the numbers
_print:
	push	EAX
	call	WriteVal
	LOOP	_WriteInt

; Prints the sum of the numbers
	call	CrLF
	call	CrLF
	mov		EDX, OFFSET sumText
	call	WriteString
	push	OFFSET space
	push	sum
	call	WriteVal
	call	CrLF

; Calculates and prints the truncated average of the numbers
	mov		EBX, 10
	mov		EAX, sum
	CDQ
	idiv	EBX
	mov		average, EAX
	call	CrLF
	mov		EDX, OFFSET avgText
	call	WriteString
	push	OFFSET space
	push	average
	call	WriteVal
	call	CrLF
	call	CrLF
	mov		EDX, OFFSET outro	
	call	WriteString			; prints goodbye message
	
	Invoke ExitProcess,0	; exit to operating system
main ENDP

; --------------------------------------------------------------------------------- 
; Name: introduction
;  
; Prints the introduction to the overall program.
; 
; Preconditions: Must have an introduction string passed to it
; 
; Postconditions: EDX is changed
; 
; Receives:  
; [ebp+12] = intro2 text
; [ebp+8] = intro1 text
; 
; returns: none
; ---------------------------------------------------------------------------------
introduction PROC
	push	EBP
	mov		EBP, ESP
	mov		EDX, [EBP+8]
	call	WriteString
	call	CrLF
	mov		EDX, [EBP+12]
	call	WriteString
	call	CrLF
	pop		EBP
	ret		8
introduction ENDP

; --------------------------------------------------------------------------------- 
; Name: readVal
;  
; Invokes the mGetString macro to get user input and then converts the string into numbers and stores the numbers in an array.
; 
; Preconditions: Must have the mGetString macro along with an array address to store the numbers.
; 
; Postconditions: ECI, DI, EAX, EDX, and ECX will be modified but returned at the end of the procedure
; 
; Receives:  
; [EBP+28] = pointer to array address that stores the 10 signed numbers
; [EBP+24] = invalid text to be displayed if invalid entry happens
; [EBP+20] = stores number of bytes entered
; [ebp+16] = number of characters allowed to be entered	
; [ebp+12] = the text prompt asking for the number
; [ebp+8] = starting address of the string array to store user input
; 
; returns: none
; ---------------------------------------------------------------------------------
readVal PROC
	LOCAL	NegBool:DWORD
	LOCAL	TenMultiple:DWORD
	mov		NegBool, 0
	mov		TenMultiple, 10
	mov		EDI, [EBP+28]
	push	ECX
	push	EDX
	push	EAX
	push	EDI
	mov		EDI, [EBP+8]

; Calls the initial mGetString macro to prompt the user to enter a number
_requestInput:
    mGetString [EBP+12], [EBP+16], EDI, [EBP+20]
	mov		ECX, [EBP+20]
	mov		EAX, 0
	mov		ESI, EDI
	mov		DWORD PTR [EBP-24], 10
	mov		EBX, 0     ; Setting "numInt" to 0 like in exploration 1

; Beginning of the loop that will look through the string and convert each character to a number
_convertStringToNumber:
	mov		EAX, 0
	LODSB
	cmp		EAX, 48
	jl		_checkSign
	cmp		EAX, 57
	jg		_invalid
	sub		EAX, 48
	cmp		NegBool, 1
	jne		_notNegative
	neg		EAX		; converts positive into negative number
	jmp		_multiply

; Jump to this block if the entered number is not negative and check size off entered string
_notNegative:
	cmp		DWORD PTR [EBP+20], 10
	jg		_invalid

; Multiplys by 10 and adds the next string index to the current number
_multiply:
	push	EAX				; preserves the EAX register to use for the mul instruction
	mov		EAX, EBX
	mul		TenMultiple   
	mov		EDX, EAX
	pop		EAX				; pops the old EAX value so the index that was converted in this loop number can be appended to the end 
	add		EAX, EDX
	jo		_invalid
	mov		EBX, EAX
	jmp		_continue

; Checks to see if there is a sign entered by the user (- or +)
_checkSign:
	cmp		[EBP+20], ECX   ; Checks if a + or - sign is at the beginning of the entry only
	jne		_invalid
	cmp		EAX, 45
	je		_negative
	cmp		DWORD PTR [EBP+20], 10
	jg		_invalid
	cmp		EAX, 43
	je		_continue

; Prints an error message if an invalid input was entered
_invalid:
	mov		EDX, [EBP+24]
	call	WriteString
	jmp		_requestInput

; If a negative sign was input by the user, it switches this boolean to 1 marking a negative number
_negative:
	mov		NegBool, 1
	cmp		DWORD PTR [EBP+20], 11
	jg		_invalid

; Continues to the next loop iteration and decrements the counter
_continue:
	dec		ECX
	cmp		ECX, 0
	ja		_convertStringToNumber

; Pops off important registers and moves converted int into the correct variable31
_end:
	mov		EDI, [EBP+28]
	mov		[EDI], EAX
	pop		EDI
	pop		EAX
	pop		EDX
	pop		ECX
	ret		24
readVal ENDP

; --------------------------------------------------------------------------------- 
; Name: writeVal
;  
; Invokes the mDisplayString macro to print out ASCII representations of SDWORD as well as converts the numbers into ASCII representations.
; 
; Preconditions: Must have mDisplayString macro to print characters as well as a valid number to convert into a string
; 
; Postconditions: ECI and EDI will be modified
; 
; Receives:  
; [ebp+12] = string represented by ", " or " " to add commas or space between a list of numbers between printed numbers
; [ebp+8] = the number that is being converted into a string
; 
; returns: none
; ---------------------------------------------------------------------------------
writeVal	PROC
	LOCAL	RevString[11]:BYTE		; local variable to hold a reversed string
	LOCAL	NegBool:DWORD			; bool to notify future code block if number is negative
	LOCAL	OutputString[11]:BYTE	; string array in the correct order and sent to macro for printing
	LOCAL	SLength:DWORD			; variable to hold length of array indexes
	push	ECX
	push	ESI
	mov		SLength, 1
	mov		NegBool, 0
	mov		RevString[0], 0
	mov		EBX, 10
	lea		EDI, RevString[1]
	mov		EAX, [EBP+8]
	test	EAX, EAX
	jns		_convert
	mov		NegBool, 1
	neg		EAX
; Divides by 10, and adds the remainder to the NewText array
_convert:
	mov		EDX, 0
	idiv	EBX
	mov		EBX, EAX
	mov		EAX, EDX
	add		EAX, 48
	STOSB
	inc		SLength
	mov		EAX, EBX
	cmp		EAX, 0
	je		_checkSign
	mov		EBX, 10
	jmp		_convert
_checkSign:
	cmp		NegBool, 1
	jne		_subPtr
	mov		EAX, 45
	inc		SLength
	mov		[EDI], EAX
	jmp		_flipString

; If the number is not negative, this will subtract one BYTE from EDI
_subPtr:
	dec		EDI

; This block will flip the backwards string to the correct direction for printing
_flipString:
	mov		ECX, SLength	
	mov		ESI, EDI
	lea		EDI, OutputString

; Moves on to the next index of the reversed string array
_nextNum:
	STD
	LODSB
	CLD
	STOSB
	LOOP	_nextNum
	lea		EDX,  OutputString
	MDisplayString EDX, [EBP+12]	; Macro to print out the string 
	pop		ESI
	pop		ECX
	ret		4
writeVal	ENDP
END main
