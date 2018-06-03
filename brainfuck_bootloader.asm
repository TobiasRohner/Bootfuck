[map all brainfuck_bootloader.map]

	org 7C00h		; Offset the program to address 7C00


GetInput:
	mov bx, 000Fh		; Page 0, color 15 (white)
	mov cx, 1		; Write one character at the time
	xor dx, dx		; Start at the top left corner of the screen
	cld			; Clear the direction flag for stosb
	mov di, SectorEnd	; Set di to the first address after the bootloader for stosb
	mov ah, 02h		; Interrupt vector to update the cursor position
	int 10h			; Update the cursor position

.read_char:
	mov ah, 00h		; Interrupt vector to get keyboard input
	int 16h			; Interrupt 16h: Get keyboard input

	cmp al, 08h		; Test if backspace was pressed
	je .handle_backspace	; Go to code that deletes a character from memory and screen

	stosb			; Store the value read to memory

	cmp al, 0Dh		; Test if enter key has been pressed
	je AllocateWorkspace	; Prepare to run the program

	mov ah, 09h		; Prepare to write the character to screen
	int 10h			; Draw character to screen

	call IncrementCursor	; Increment the cursor position by one

	jmp .read_char		; Continue reading characters

.handle_backspace:
	dec di			; Move the end of the string one position back
	call DecrementCursor	; Move the cursor one position to the right
	mov al, ' '		; Overwrite the character at the current position of the cursor with a space
	mov ah, 09h		; Interrupt vector to write charater on the screen
	int 10h			; Write a space to the screen

	jmp .read_char		; Continue reading characters


AllocateWorkspace:		; Fill an array with 30000 zeros as a workspace for brainfuck
	mov word [ProgramCounter], SectorEnd	    ; Initialize the program counter
	mov [DataPointer], di	; Initialize the data pointer
	mov cx, 30000		; Store 30000 zeros
	mov al, 0		; Fill the space with zeros
.loop:
	stosb			; Store a zero at di
	dec cx			; Decrement the number of zeros that still have to be written
	jnz .loop		; Repeat until all zeros have been written


RunCode:			; Set up for writing on the screen
	mov bx, 000Fh		; Page 0, color 15 (white)
	mov cx, 1		; Write one character at the time
	mov dl, 0		; Reset the cursor to the start of the line
	inc dh			; Move the cursor down one line
	mov ah, 02h		; Interrupt vector to update cursor position
	int 10h			; Move the cursor down one line
	dec word [ProgramCounter]   ; Decrement the program counter to one character before the actual code

.next_instruction:
	inc word [ProgramCounter]	; Increment the program counter
	movzx eax, word [ProgramCounter]
	cmp byte [eax], '>'	; Test if the command was >
	je .inc_data_ptr	; Jump to the routine for handling data pointer increment
	cmp byte [eax], '<'	; Test if the command was <
	je .dec_data_ptr	; Jump to the routine for handling data pointer decrement
	cmp byte [eax], '+'	; Test if the command was +
	je .inc_cell		; Jump to the routine for handling cell increment
	cmp byte [eax], '-'	; Test if the command was -
	je .dec_cell		; Jump to the routine for handling cell decrement
	cmp byte [eax], '.'	; Test if the command was .
	je .out_cell		; Jump to the routine for handling output
	cmp byte [eax], ','	; Test if the command was ,
	je .in_cell		; Jump to the routine for handling input
	cmp byte [eax], '['	; Test if the command was [
	je .jump_forward	; Jump to the routine for handling forward jumping
	cmp byte [eax], ']'	; Test if the command was ]
	je .jump_backward	; Jump to the routine for handling backward jumping

.error:
	mov ah, 00h		; Interrupt vector to get keyboard input
	int 16h			; Wait for some random key to be pressed
	jmp GetInput		; Reset everything and wait for a new program

.inc_data_ptr:		; >
	inc word [DataPointer]	; Increment the data pointer
	jmp .next_instruction	; Execute the next instruction

.dec_data_ptr:		; <
	dec word [DataPointer]	; Decrement the data pointer
	jmp .next_instruction	; Execute the next instruction

.inc_cell:		; +
	movzx eax, word [DataPointer]	; Move the value of the data pointer to ax
	inc byte [eax]		; Increment the value of the current cell
	jmp .next_instruction	; Execute the next instruction

.dec_cell:		; -
	movzx eax, word [DataPointer]	; Move the value of the data pointer to ax
	dec byte [eax]		; Decrement the value of the current cell
	jmp .next_instruction	; Execute the next instruction

.out_cell:		; .
	movzx eax, word [DataPointer]    ; Move the value of the data pointer into eax
	mov al, [eax]		; Move the character to write to al
	mov ah, 09h		; Prepare to write the character on screen
	int 10h			; Draw the character on screen
	call IncrementCursor	; Increment the cursor position by one
	jmp .next_instruction	; Execute the next instruction

.in_cell:		; ,
	mov ah, 00h		; Interrupt vector for reading keyboard input
	int 16h			; Interrupt to wait for a keyboard input
	mov ah, 09h		; Interrupt vector for writing character
	int 10h			; Write the read character to the terminal
	mov cl, al		; Store the read key in a temporary location
	call IncrementCursor	; Increment the cursor position by one
	movzx eax, word [DataPointer]	; Move the address of the current cell to eax
	mov [eax], cl		; Store the key read to the current cell
	mov cx, 1		; Reset cx to 1
	jmp .next_instruction	; Execute the next instruction

.jump_forward:		; [
	movzx eax, word [DataPointer]	; Move the address of the current cell to eax
	mov al, [eax]		; Move the value of the current cell to al
	test al, 0FFh		; Test whether al is zero
	jnz .next_instruction	; If the byte was not zero, continue with the program flow
	mov cx, 1		; The amount of opening brackets seen is stored in cx
.jump_forward_loop:
	inc word [ProgramCounter]	; Move the program counter one position to the right
	movzx eax, word [ProgramCounter]; Get the address the program counter is pointing to
	cmp byte [eax], '['	; Check if another bracket is opened
	jne .jump_forward_loop_no_open	; Just continue normally if the character is no opening bracket
	inc cx			; Increment the number of opening brackets seen
.jump_forward_loop_no_open:
	cmp byte [eax], ']'	; Check if the current command is ']'
	jne .jump_forward_loop_no_close	; Just continue normally if the character is no closing bracket
	dec cx
.jump_forward_loop_no_close:
	test cx, 0FFh		; Test whether cx is zero
	jnz .jump_forward_loop	; Continue looping until the matching closing bracket
	mov cx, 1		; Reset cx
	jmp .next_instruction	; Execute the next instruction

.jump_backward:		; ]
	movzx eax, word [DataPointer]	; Move the address of the current cell to eax
	mov al, [eax]		; Move the value of the current cell to al
	test al, 0FFh		; Test whether al is zero
	jz .next_instruction	; If the byte was not zero, continue with the program flow
	mov cx, 1		; The amount of closing brackets seen is stored in cx
.jump_backward_loop:
	dec word [ProgramCounter]	; Move the program counter one position to the left
	movzx eax, word [ProgramCounter]; Get the address the program counter is pointing to
	cmp byte [eax], ']'	; Check if another bracket is closed
	jne .jump_backward_loop_no_close    ; Just continue normally if the character is no closing bracket
	inc cx			; Increment the number of closing brackets seen
.jump_backward_loop_no_close:
	cmp byte [eax], '['	; Check if another bracket is opened
	jne .jump_backward_loop_no_open	; Just continue normally if the character is no opening bracket
	dec cx			; Decrement the number of closing brackets seen
.jump_backward_loop_no_open:
	test cx, 0FFh		; Test whether cx is zero
	jnz .jump_backward_loop	; Continue until the matching opening bracket is found
	mov cx, 1		; Reset cx
	jmp .next_instruction	; Execute the next instruction
	


IncrementCursor:
	inc dl		    ; Move cursor one position to the right
	cmp dl, 80	    ; Check if a newline has to be inserted
	jne .no_newline	    ; Print a newline if needed
	xor dl, dl	    ; Reset the cursor position to the start of the line
	inc dh		    ; Move the cursor one line down
.no_newline:
	mov ah, 02h	    ; Interrupt vector to update the cursor position
	int 10h		    ; Update the cursor position
	ret		    ; Return from subroutine


DecrementCursor:
	test dl, 0FFh	    ; Test whether the cursor is at the beginning of a line
	jnz .no_newline	    ; If the cursor is not at the start of the line, jump over the code to handle that
	dec dh		    ; Move the cursor one line up
	mov dl, 80	    ; Move the cursor to the end of the line
.no_newline:
	dec dl		    ; Move the cursor one character to the left
	mov ah, 02h	    ; Interrupt vector to update cursor position
	int 10h		    ; Update the cursor position
	ret		    ; Return from subroutine


ProgramCounter:
	dw 0		    ; The program counter describing the position in the brainfuck code
DataPointer:
	dw 0		    ; The data pointer pointing to the current cell of the tape


	times 0200h - 2 - ($ - $$) db 0	    ; Fill with zeros up to 510 bytes
	dw 0AA55h   ; Boot sector signature

SectorEnd:
