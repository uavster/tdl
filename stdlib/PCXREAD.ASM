JUMPS
.386p
.model flat
.stack 100h
.code
INCLUDE     alloc.inc
INCLUDE     filesys.inc
INCLUDE     sgl.inc
INCLUDE     coolpal.inc

public       get_pcx_info
public       pcx_decode
public       read_pcx
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
get_pcx_info proc
; INPUT  -> DS:ESI -> PCX data
; OUTPUT -> AX = width of image ; BX = height of image
;           ECX = size of image data
        add esi,4
        mov bx,[esi+4]
        sub bx,[esi]
        inc bx
        push ebx
        movzx eax,word ptr [esi+6]
        sub ax,[esi+2]
        inc ax
        push eax
        mov y_dim,ax
        mul bx
        shl edx,16
        or eax,edx
        mov ecx,eax
        pop ebx
        pop eax
        ret
get_pcx_info endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
pcx_decode proc
; INPUT  -> DS:ESI -> compressed image data ; ECX = compressed data size
;           DS:EDI -> where to place image
;
; OUTPUT -> CF = 0 if success
;               DS:ESI -> decompressed image
;               AX = width of image ; BX = height of image
;           CF = 1 if invalid file format
        push esi
        cmp byte ptr [esi],0Ah
        jnz not_a_pcx
        cmp byte ptr [esi+2],1
        jnz not_a_pcx
        sub ecx,768
        add esi,ecx
        mov bx,768/4
        take_color:
                mov ax,[esi+2]
                shr al,2
                shr ah,2
                shl eax,16
                mov ax,[esi]
                shr al,2
                shr ah,2
                stosd
                add esi,4
        dec bx
        jnz take_color

        ; Miramos el tama¤o de la imagen
        pop esi
        push esi
        add esi,4
        mov ax,[esi]
        mov bx,[esi+4]
        sub bx,ax
        inc bx
        mov x_dim,bx
        mov cx,word ptr [esi+2]
        movzx eax,word ptr [esi+6]
        sub ax,cx
        inc ax
        mov y_dim,ax
        mul bx
        shl edx,16
        or eax,edx

        add eax,edi
        pop esi
        add esi,128
        mov image_size,eax

        movzx edx,x_dim
        and dx,1         ; si la longitud es impar,la l¡nea real es 1 byte mayor
        xor ecx,ecx
        push edi
        decode:
                mov al,[esi]
                and al,11000000b
                cmp al,11000000b
                jne no_repeat
                mov cl,[esi]
                and cl,00111111b
                mov al,[esi+1]
                add esi,2
                add pixel_count,cx
                jmp put_it
                no_repeat:
                mov cl,1
                mov al,[esi]
                inc esi
                inc pixel_count
                put_it:
                rep stosb
                mov ax,x_dim
                cmp pixel_count,ax
                jne cont
                mov pixel_count,0
                add esi,edx
        cont:
        cmp edi,image_size
        jb decode
        pop esi
        mov ax,x_dim
        mov bx,y_dim
        clc
        ret

        not_a_pcx:
        stc
        ret
image_size      dd ?
x_dim           dw ?
y_dim           dw ?
pixel_count     dw 0
pcx_decode endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
read_pcx proc
; INPUT  -> DS:EDX -> ASCIIZ file name ; DS:EDI -> destination buffer
;
; OUTPUT -> CF = 0 if success
;               DS:ESI -> destiny buffer filled
;               EAX = width of image ; EBX = height of image
;           CF = 1 if error
;               AL =  error code
;              ( 0 = file error ; 1 = invalid format ; 2 = memory error )
        push edi
        call ttl_load_file
        pop edi
        jc read_pcx_error
        mov mem_ptr,ebx
        mov ecx,file_size
        mov esi,ebx
        call pcx_decode
        jnc read_pcx_ok
        ; liberamos el buffer temporal
                mov ebx,mem_ptr
                call free
                mov al,1
                jmp read_pcx_error
        read_pcx_ok:
        mov ebx,mem_ptr
        call free
        mov al,2
        jc read_pcx_error
        mov esi,buffer1
        movzx eax,x_dim
        movzx ebx,y_dim
        clc
        read_pcx_error:
        ret

buffer1         dd ?
buffer2         dd ?
mem_ptr         dd ?
read_pcx endp
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
end
