.model tiny
.186
.data

VIDEOSEG = 0b800h

CONSOLE_WIDTH  = 25d
CONSOLE_LENGTH = 80d

X = 68d
Y = 4d
START_POINT = (Y * 80d + X) * 2d

FRAME_WIDTH  = 6d
FRAME_LENGTH = 9d

Elems db 2bh, 2dh, 2bh, 0b3h, 20h, 0b3h, 2bh, 2dh, 2bh
					; + - +
					; |   |
					; + - +

LINE_COLOR = 70h

FrameStatus db 0d

VideoBufferBegin    db FRAME_WIDTH * FRAME_LENGTH * 2d dup (0d)
VideoBufferPrevious db FRAME_WIDTH * FRAME_LENGTH * 2d dup (0d)

StrNum db '$'

;------------------------------------------------
; Draw a line in a frame
;
; Entry:	AH - color (attr) of line
;		CX - lenght of string
;		SI - addr of 3-byte array containing line elements
;		DI - adress of start of line
; Note:		ES - videoseg addr (0b800h)
; Exit:		None
; Destr:	AX, CX, DI, SI
;------------------------------------------------

DrawLine	proc			; cld (Clear Dest Flag) (++)
					; std (Set Dest Flag) (--)

		mov al, cs:[si]		; lodcb (Load String of )
		inc si

		mov es:[di], ax		; stosw (Store String of Words)
		add di, 2d			

		mov al, cs:[si]		; lodcb
		inc si

		sub cx, 2d
		jbe @@stop_line

@@next_sym:
		mov es:[di], ax		; rep stosw
		add di, 2d
		loop @@next_sym

		mov al, cs:[si]		; lodsb

		mov es:[di], ax		; stosw
		add di, 2d

@@stop_line:
		ret
DrawLine	endp

;------------------------------------------------
; Draw frame
;
; Entry:	None
; Note:		ES - videoseg addr (0b800h)
; Exit:		None
; Destr:	AX, BX, CX, DX, DI, SI, ES
;------------------------------------------------

DrawFrame	proc
        	pusha

		mov ax, VIDEOSEG
		mov es, ax
	
		;================================================
		; Draw first line of frame
		;------------------------------------------------
		mov ah, LINE_COLOR
		mov cx, FRAME_LENGTH
		mov si, offset Elems
		mov di, START_POINT
		call DrawLine
		;================================================

		;================================================
		; Draw the main part of frame
		;------------------------------------------------
		mov dx, 1d	

		mov cx, FRAME_WIDTH
		sub cx, 2d

lp1:
		mov di, START_POINT		
		mov ah, dl
		mov al, CONSOLE_LENGTH * 2d
		mul ah
		add di, ax
		
		mov ah, LINE_COLOR
		mov bx, cx
		mov cx, FRAME_LENGTH
		mov si, offset Elems
		add si, 3d
		call DrawLine

		inc dx
		mov cx, bx
		loop lp1
		;================================================	
		
		;================================================
		; Draw last line of frame
		;------------------------------------------------
		mov cx, FRAME_LENGTH
        
        	mov si, offset Elems
		add si, 6d

		mov di, START_POINT
		mov ah, dl
		mov al, CONSOLE_LENGTH * 2d
		mul ah
		add di, ax
	
        	mov ah, LINE_COLOR
		call DrawLine
		;================================================
		
		popa
		ret
DrawFrame	endp

;------------------------------------------------
; String length counting function (the string must
; end with the character $)
;
; Entry:	addr of the beginning of the string (SI)
; Note:		- parametr and result are passed through
;		the stack (in one position)
;		- $ - 24h (ASCI code)
; Exit:		string length (CX)
; Destr:	AX, CX, SI
;------------------------------------------------

StrLen	proc
	
	mov al, 24h
	mov cx, 0000h			; cx - length of the string	

next_len:
	cmp [si], al
	je stop_len

	inc cx
	inc si
	jmp next_len

stop_len:
	ret
StrLen 	endp

;------------------------------------------------
; Converting a number to a string (the string must
; end with the character $)
;
; Entry:	- addr of string for output answer (SI)
;           	- the number (AX)
;               - the base of the number system (BX)
;
; Note:		- parameter (addr str) and result
;             	  are passed through the register (SI)
;		- $ - 24h (ASCI code)
;       	- a number cannot start with 0
;
; Exit:		- addr of str
; Destr:	AX, BX, CX, DX, SI, SP
;------------------------------------------------

Itoa	proc

	push ax bx cx dx
    
	mov cx, 0000h
next_itoa:
	mov dx, 0000h
        div bx
        push dx
        inc cx
	cmp ax, 0000h
	jne next_itoa
	    	
reverse_itoa:
	cmp cx, 0000h
        je stop_itoa

        pop ax
        dec cl
        mov bl, 0ah
        cmp al, bl
        jl num

        add al, 07h
                        
num:
	add al, 30h
        mov [si], al
        inc si
        jmp reverse_itoa
    
    
stop_itoa:
	mov bl, 24h
        mov [si], bl
    
        pop dx cx bx ax
    
        ret
Itoa    endp

;------------------------------------------------
; Displaying the values of the register
;
; Entry: - register value (AX)
;      	 - addr of video memory (DI)
;        - case designation (two characters) (BX)
; Exit:	 None
; Destr: BX, CX, DX, DI, SI
;------------------------------------------------

PrintOneReg	proc

                push bx
                
                mov si, offset StrNum
                mov bx, 0016d
                call Itoa

                pop bx
                mov si, offset StrNum
                call StrLen
                mov si, offset StrNum
                
                push bx
                mov bl, bh
                mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                
                pop bx
                mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                
                mov bl, ' '
                mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                
                mov bl, 30h
                mov dx, 4d
                cmp cx, dx
                jne first_zero

                mov bl, [si]
                inc si
                inc dx
                    
first_zero:     
		mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                dec cx
                
                mov bl, 30h
                sub dx, 2d
                cmp cx, dx
                jne second_zero

                mov bl, [si]
                inc si
                inc dx
                    
second_zero:
		mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                dec cx
                
                mov bl, 30h
                sub dx, 2d
                cmp cx, dx
                jne third_zero

                mov bl, [si]
                inc si
                inc dx
                    
third_zero:
		mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                dec cx
                
                mov bl, 30h
                sub dx, 2d
                cmp cx, dx
                jne fourth_zero

                mov bl, [si]
                inc si
                    
fourth_zero:
		mov bh, LINE_COLOR
                mov es:[di], bx
                add di, 2d
                dec cx
                
                ret
PrintOneReg     endp

;------------------------------------------------
; Displaying the values of the registers
; (AX, BX, CX, DX)
;
; Entry: AX, BX, CX, DX
; Exit:	 None
; Destr: DI, SI
;------------------------------------------------

PrintRegs   proc
            
            push dx cx bx ax
            
            mov ax, VIDEOSEG
            mov es, ax
            
            pop ax
            mov di, START_POINT
            add di, 2d * CONSOLE_LENGTH
            add di, 2d
            mov bh, 'a'
            mov bl, 'x'
            call PrintOneReg
            
            pop ax
            add di, 2d * CONSOLE_LENGTH
            sub di, (FRAME_LENGTH - 2d) * 2d
            mov bh, 'b'
            mov bl, 'x'
            call PrintOneReg
            
            pop ax
            add di, 2d * CONSOLE_LENGTH
            sub di, (FRAME_LENGTH - 2d) * 2d
            mov bh, 'c'
            mov bl, 'x'
            call PrintOneReg
            
            pop ax
            add di, 2d * CONSOLE_LENGTH
            sub di, (FRAME_LENGTH - 2d) * 2d
            mov bh, 'd'
            mov bl, 'x'
            call PrintOneReg
            
            ret
PrintRegs   endp

;------------------------------------------------
; The function saves the video
;
; Entry: SI - address saving video
; Exit:	 changing the byte array
; Destr: AX, BX, CX, DX, DI, SI, ES
;------------------------------------------------

SaveVideoBuffer     proc

                    push ax bx cx dx di es

                    mov ax, VIDEOSEG
                    mov es, ax
                    
                    mov dx, 0d	
                    mov cx, FRAME_WIDTH
save_line:
                    mov di, START_POINT		
                    mov ah, dl
                    mov al, CONSOLE_LENGTH * 2d
                    mul ah
                    add di, ax

                    mov bx, cx
                    mov cx, FRAME_LENGTH * 2d
save_column:
                    mov al, es:[di]
                    mov cs:[si], al
                    inc di
                    inc si
                    loop save_column

                    inc dx
                    mov cx, bx
                    loop save_line

                    pop es di dx cx bx ax
                    ret
SaveVideoBuffer     endp

;------------------------------------------------
; The function saves the begin video
;
; Entry: None
; Exit:	 None
; Destr: AX, CX, DI, SI, ES
;------------------------------------------------

SetVideoBufferBegin     proc

                        push ax bx cx dx di si es

                        mov ax, VIDEOSEG
                        mov es, ax
                    
                        mov si, offset VideoBufferPrevious
                    
                        mov dx, 0d	
                        mov cx, FRAME_WIDTH
set_line:
                        mov di, START_POINT		
                        mov ah, dl
                        mov al, CONSOLE_LENGTH * 2d
                        mul ah
                        add di, ax

                        mov bx, cx
                        mov cx, FRAME_LENGTH * 2d
set_column:
                        mov al, es:[di]
                        cmp cs:[si], al
                        je skip_end
                        
                        push si
                        mov si, offset VideoBufferBegin
                        call SaveVideoBuffer
                        pop si
                        jmp stop_set
skip_end:                       
                        inc di
                        inc si
                        loop set_column

                        inc dx
                        mov cx, bx
                        loop set_line

stop_set:
                        pop es si di dx cx bx ax
                    
                        ret
SetVideoBufferBegin     endp

;------------------------------------------------
; The function outputs the saved screen value
;
; Entry: None
; Exit:  None
; Destr: AX, CX, DI, SI, ES
;------------------------------------------------

OutVideoBuffer      proc

                    push ax bx cx dx di si es

                    mov ax, VIDEOSEG
                    mov es, ax
                    
                    mov si, offset VideoBufferBegin
                    
                    mov dx, 0d	
                    mov cx, FRAME_WIDTH
out_line:
                    mov di, START_POINT		
                    mov ah, dl
                    mov al, CONSOLE_LENGTH * 2d
                    mul ah
                    add di, ax

                    mov bx, cx
                    mov cx, FRAME_LENGTH * 2d
out_column:
                    mov al, cs:[si]
                    mov es:[di], al
                    inc di
                    inc si
                    loop out_column

                    inc dx
                    mov cx, bx
                    loop out_line

                    pop es si di dx cx bx ax
                    ret
OutVideoBuffer      endp

DataEnd:

.code
org 100h

locals @@ ; (lb - global label, @@lb - local label)

Start:  cli

        xor bx, bx
        mov es, bx
        mov bx, 08h * 4
        
        mov ax, es:[bx]
        mov word ptr old08, ax
        mov ax, es:[bx+2]
        mov word ptr old08+2, ax
        
        mov word ptr es:[bx], offset New08
        push cs
        pop ax
        mov word ptr es:[bx+2], ax

        add bx, 4       ; ES:BX -> Int09h
        
        mov ax, es:[bx]
        mov word ptr old09, ax
        mov ax, es:[bx+2]
        mov word ptr old09+2, ax

        mov word ptr es:[bx], offset New09
        push cs
        pop ax
        mov word ptr es:[bx+2], ax

        sti

        mov ax, 3100h
        mov dx, offset DataEnd
        shr dx, 4
        inc dx
        int 21h

New08   proc
        push ax bx cx dx si di sp es

        cmp cs:[FrameStatus], 1d
        jne skip_New08

        call SetVideoBufferBegin
        call DrawFrame
        call PrintRegs
        push si
        mov si, offset VideoBufferPrevious
        call SaveVideoBuffer
        pop si
        
skip_New08:
        pop es sp di si dx cx bx ax
        db 0EAh
old08   dd 0
New08   endp

New09   proc

        push ax

        in al, 60h
        
        cmp al, 3bh
        jne skip_New09
        
        push si
        mov si, offset VideoBufferBegin
        call SaveVideoBuffer
        pop si
        mov cs:[FrameStatus], 1d
        jmp close_New09_1

close_New09_0:
        mov cs:[FrameStatus], 0d
        call OutVideoBuffer
close_New09_1:
        in al, 61h
        mov ah, al
        or al, 80h
        out 61h, al
        mov al, ah
        out 61h, al

        mov al, 20h
        out 20h, al
        
        pop ax
        iret
        
skip_New09:
        cmp al, 3ch
        je close_New09_0
        
        pop ax
        db 0EAh
old09   dd 0
New09   endp

        mov ax, 4c00h
        int 21h        
        
end Start
