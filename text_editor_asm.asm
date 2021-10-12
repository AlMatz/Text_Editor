;.286
jumps
.model tiny
	assume ds:code,cs:code
code segment
;.code
	org 100h

start:
jmp realstart

clearscrn:
	mov bx,0720h
	mov cx,25*80
	sub di,di
clr:mov es:[di],bx
	add di,2
	loop clr
	ret
	
;writes to file
writetofile:
	push ax
	push dx
	push cx
	push bx
	mov ah,40h
	mov bx,inh
	mov cx,sizee
	mov dx,offset printhis
	int 21h
	pop bx
	pop cx
	pop dx
	pop ax
	ret
	
closefile:
	push ax
	push dx
	push cx
	push bx

	mov ah, 3Eh
    mov bx, inh
    int 21h

	pop bx
	pop cx
	pop dx
	pop ax
	ret

openreadfile:
	push ax
	push dx
	push cx
	push bx
	
	mov ah,3dh ;opens file
	mov al,2
	mov dx,offset inname
	int 21h
	mov inh,ax
	
	mov ah,3fh ;reads file
	mov bx,inh
	mov cx,sizee
	mov dx,offset printhis
	int 21h
	
	pop bx
	pop cx
	pop dx
	pop ax
	ret

realstart:
	mov ax,0B800h
	mov es,ax
	
    call clearscrn
	
open:
	;opens file
	mov ah,3dh
	mov al,0
	mov dx,offset inname
	int 21h
	mov inh,ax
	
	mov ah,42h
	mov bx,inh
	mov al,2
	mov cx,0
	mov dx,0
	int 21h
	
	mov sizee,ax

	mov ah,42h ;rewinds
	mov bx,inh
	mov cx,0
	mov dx,0
	mov al,0
	int 21h

	;reads file
	mov ah,3fh
	mov bx,inh
	mov cx,sizee
	mov dx,offset printhis
	int 21h
	
	;closes file
    mov ah, 3Eh
    mov bx, inh
    int 21h
	
	push bx
	mov bx,sizee
	mov printhis[bx],0dh
	inc sizee
	pop bx
	
	;to print contents of file
	mov di,0
	mov bx,0
	mov cx,sizee
	cmp sizee,1
	je setcur
print1:	
	mov al,printhis[bx]
	
	cmp count,80
	je timetocheck
printit:
	cmp al,0Dh
	je changedi
	
	mov es:[di],al
	inc count
	add di,2
	inc bx
	loop print1
	jmp setcur

timetocheck:
	mov al,printhis[bx]
	cmp al,0Dh
	je changedi
	inc bx
	loop timetocheck
	jmp setcur
	
changedi: ;algo for printing at the beginning of a new line every time we finish one
	push ax
	add di,160 
	mov ax,count
	add ax,ax
	sub di,ax
	add bx,2
	sub ax,ax
	mov count,ax ;resets count to 0
	inc rows ;means we have a new row
	inc resetcount ;same as rows...
	pop ax
	jmp print1	
	
setcur:
	push si
	push di
	push cx
	push ax
	push bx
	push dx
	mov si,0
	mov di,3840
	mov cx,48
barloop1:
	mov bl,barfortext[si]
	mov bh,74
	mov es:[di],bx
	inc si
	add di,2
	loop barloop1
	pop dx
	pop bx
	pop ax
	pop cx
	pop di
	pop si
	
	mov ah,02 ;sets the cursor top left, 0,0
	mov bh,0
	mov dh,0
	mov dl,0
	int 10h
	push dx
	
	push dx
	mov ah,3dh
	mov al,2
	mov dx,offset inname
	int 21h
	mov inh,ax
	pop dx
	
	;jmp stopprinting
	
change_array:
	push si
	push di
	push cx
	push ax
	push bx
	push dx
	mov dx,offset printhis
	mov ax,offset auxilarray
	mov cx,sizee
	mov new_sizee,cx
	mov di,0
	mov si,0
L:
	mov bl,printhis[di]
	cmp bl,0ah
	je skip
	mov auxilarray[si],bl
	inc si
	jmp cont_loop
skip:
	dec new_sizee
cont_loop:
	inc di
	loop L
	pop dx
	pop bx
	pop ax
	pop cx
	pop di
	pop si
	jmp stopprinting

	
repushdx:
	push dx

stopprinting:	
	push ax
	push bx
	push cx
	push dx
	push di
	mov cx,new_sizee
	add cl,'0'
	mov es:[560],cl
	
	mov cx,sizee
	add cl,'0'
	mov es:[564],cl
	
	mov cx,new_sizee
	mov di,1500
	mov bx,0
testloop:
	mov al,auxilarray[bx]
	mov es:[di],al
	inc bx
	add di,2
	
	loop testloop
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	
	push ax
	push bx
	push cx
	push dx
	push di
	mov cx,sizee
	mov di,1660
	mov bx,0
testloop2:
	mov al,printhis[bx]
	mov es:[di],al
	inc bx
	add di,2
	
	loop testloop2
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	
	
	mov bh,0 ;waits for key
	mov ah,00h
	int 16h
	
	cmp al,1Bh
	je quitnandsave
	
	cmp al,20h
	jge printchar

	cmp ah,048h
	je moveup
	
	cmp ah,04Bh
	je moveleft
	
	cmp ah,04Dh
	je moveright
	
	cmp ah,050h
	je movedown
	
	cmp ah,1ch ;enter
	je new_skipchar
	
	cmp ah,53h ;delete
	je deletechar
	
	cmp ah,52h ;insert mode
	je ins_mode
	
	jmp stopprinting
	
printchar:

	
	cmp al,7Fh
	jg stopprinting
	
	mov ah,09 ;displays char in al on screen
	mov cx,1
	mov bl,07
	mov bh,0
	int 10h

	mov si,arraypos
	cmp auxilarray[si],0dh
	je end_of_line_add_char_then_copy
	mov auxilarray[si],al ;overtype not @ endline char
	jmp stopprinting ;it is overtype if it gets here
	
end_of_line_add_char_then_copy:
	push si
	mov cx,new_sizee
	sub cx,si
	mov di,0
thisloop:
	mov bl,auxilarray[si]
	mov extra_array[di],bl
	inc si
	inc di
	loop thisloop
	pop si
	mov auxilarray[si],al
	;inc new_sizee
	
	push ax
	push bx
	push cx
	push dx
	push di
	mov cx,new_sizee
	mov di,1820
	mov bx,0
testloop5:
	mov al,extra_array[bx]
	mov es:[di],al
	inc bx
	add di,2
	
	loop testloop5
	pop di
	pop dx
	pop cx
	pop bx
	pop ax
	
	
	mov cx,new_sizee
	sub cx,si
	inc si
	mov di,0
loop_it_all_in:
	mov bl,extra_array[di]
	mov auxilarray[si],bl ;copies it all back in
	mov extra_array[di],00h
	inc si
	inc di
	loop loop_it_all_in
	
	inc new_sizee
	jmp stopprinting
	
	
;-START OF PRESSING ENTER!-----	
	
new_skipchar:
	;when they press enter, what do we want to do? Add in 0Dh and reprint screen
	mov si,arraypos
	push si
	mov cx,new_sizee
	sub cx,si
	mov di,0
thisloop2: ;copies it all into extra array starting from the positon si
	mov bl,auxilarray[si]
	mov extra_array[di],bl
	inc si
	inc di
	loop thisloop2
	pop si
	mov auxilarray[si],0Dh
	
	
	mov cx,new_sizee
	sub cx,si
	inc si
	mov di,0
loop_it_all_in2:
	mov bl,extra_array[di]
	mov auxilarray[si],bl ;copies it all back in
	mov extra_array[di],00h
	inc si
	inc di
	loop loop_it_all_in2
	inc new_sizee
	
	
	call clearscrn
	push di
	push bx
	push cx
	push ax
	push dx
	mov count,0
	mov di,0
	mov bx,0
	mov cx,new_sizee

print2:	
	mov al,auxilarray[bx]
	
	cmp count,80
	je timetocheck
printit2:
	cmp al,0Dh
	je changedi2
	
	mov es:[di],al
	inc count
	add di,2
	inc bx
	loop print2
	jmp stopit

timetocheck2:
	mov al,auxilarray[bx]
	cmp al,0Dh
	je changedi2
	inc bx
	loop timetocheck
	
	;inc new_sizee
	jmp stopit
	
changedi2: ;algo for printing at the beginning of a new line every time we finish one
	push ax
	add di,160 
	mov ax,count
	add ax,ax
	sub di,ax
	add bx,1
	sub ax,ax
	mov count,ax ;resets count to 0
	inc rows ;means we have a new row
	inc resetcount ;same as rows...
	pop ax
	jmp print2	
	
stopit:

	mov si,0
	mov di,3840
	mov cx,48
barloop:
	mov bl,barfortext[si]
	mov bh,74
	mov es:[di],bx
	inc si
	add di,2
	loop barloop
	
	
	pop dx
	pop ax
	pop cx
	pop bx
	pop di
	
	jmp stopprinting
	
	
ins_mode:
	mov al,'2'
	mov es:[2200],al
	jmp stopprinting	
	
deletechar:
	mov al,'9'
	mov es:[2200],al
	jmp stopprinting

	
moveup:
	pop dx
	cmp dh,0
	je repushdx	
	
	mov ah,02
	mov bh,0
	dec dh
	int 10h
	push dx
	
	dec currrow
	
	jmp stopprinting

movedown:
	pop dx
	cmp dh,24
	je repushdx
	;pop dx
	mov ax,'2'
	mov es:[2200],al
	push si
	push bx
	push ax
	mov bx,currcol
	inc bx
	mov si,bx
	mov cx,new_sizee
	mov ax,0
find_new_line:
	cmp auxilarray[si],0dh
	je new_row_found
	inc si
	loop find_new_line
	jmp no_more_rows_to_find
	
new_row_found:
	;now we need to see if we can add the cols without going into new line
	mov cx,currcol
	inc si
new_loop:
	cmp auxilarray[si],0dh
	je cant_add_go_to_beggining_of_line
	inc si
	inc ax
	loop new_loop
	mov arraypos,si
	mov ah,02 
	mov bh,0
	inc dh
	int 10h
	jmp end_down
	
cant_add_go_to_beggining_of_line:
	inc dh
	mov dl,0
	mov ah,02
	mov bh,0
	int 10h
	mov currcol,1
	sub si,ax
	mov arraypos,si
	
end_down:
	inc currrow
no_more_rows_to_find:
	pop ax
	pop bx
	pop si
	push dx

	jmp stopprinting

moveright:
	pop dx	
	
	push si
	mov si,arraypos ;to check if we at end of file
	cmp auxilarray[si+1],00h
	je dont_go
	
	cmp auxilarray[si],0dh
	je set_col_0
	
	cmp currcol,80
	je set_col_0__change_arraypos

	
	mov ah,02 
	mov bh,0
	inc dl
	int 10h
	push dx
	inc currcol
	jmp inc_arraypos
	
set_col_0__change_arraypos:
	mov dl,0 ;sets col to 0
	inc dh
	mov bh,0
	mov ah,02
	int 10h
	inc currrow
	mov currcol,1
	
change_new_array_pos:
	mov cx,new_sizee
	sub cx,si
	push si
	;inc si
next_row_looking:
	cmp auxilarray[si],0Dh
	je before_leaving
	inc arraypos
	inc si
	loop next_row_looking
	
	pop si
	jmp dont_go

set_col_0:
	mov dl,0 ;sets col to 0
	inc dh
	mov bh,0
	mov ah,02
	int 10h
	inc currrow
	mov bx,1
	mov currcol,bx
	
	
inc_arraypos:
	inc arraypos
	pop si
	push dx
	mov ax,arraypos
	add ax,'0'
	mov ah,0
	mov es:[2600],al
	jmp stopprinting

before_leaving:
	pop si
	inc arraypos

dont_go:
	mov ax,arraypos
	add ax,'0'
	mov es:[2600],al
	pop si
	push dx
	jmp stopprinting

moveleft:
	pop dx
	cmp dl,0
	je repushdx
	
	mov ah,02 
	mov bh,0
	dec dl
	int 10h
	
	dec currcol
	dec arraypos
	
	push dx
	jmp stopprinting
	
quitnandsave:
	mov di,0
	mov si,0
	mov cx,new_sizee
copy_over_array:
	mov al,auxilarray[di]
	cmp al,0dh
	je add_oah
	mov printhis[si],al
continue_the_moving:
	inc si
	inc di
	loop copy_over_array
	jmp time_to_write
	
add_oah:
	mov printhis[si],al
	inc si
	inc new_sizee
	mov printhis[si],0ah
	jmp continue_the_moving
	
	
time_to_write:
	mov ax,new_sizee
	mov sizee,ax
	call writetofile
	
	mov ah, 3Eh
    mov bx, inh
    int 21h
	
errorr:
fin:	
	
	
	mov ah, 4ch
	int 21h

	ret

barfortext db 'Esc-Quit & Save   Insert - Off   Caps-Lock - Off','$'
barfortext1 db 'Esc-Quit & Save   Insert - Off   Caps-Lock - On','$'
barfortext2 db 'Esc-Quit & Save   Insert - On   Caps-Lock - Off','$'
barfortext3 db 'Esc-Quit & Save   Insert - On   Caps-Lock - On','$'
;Best way to print if the button is toggled? maybe make a thing to check.


inname db 'newnew.txt',0 ;in future this will be changed to what they input

inh dw ?

writethis db 'w','$'

arraypos dw 0
printhis db 30000 dup(00h),'$'
auxilarray db 30000 dup(00h),'$'
extra_array db 100 dup(00h),'$'
where_countrow dw 0

new_sizee dw ?
charcount db 0
resetcount dw 0
rows dw 0
sizee dw ?
count dw 0
track dw ?


currcol dw 1
currrow dw 1

	code ends	
end start

;notes
;Everytime we are editting a file, and we type something we want to write it to the file using mov ah,40h

;how do we use int 81h to retreive command line args, like what do we do to get whats in 81h



;how to make our own cursor?
;int 10 to set cursor shape
