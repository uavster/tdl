.386p
.model flat
.stack 10000h
.code
        INCLUDE utils.inc
        INCLUDE render.inc
        INCLUDE 3d.inc
        INCLUDE newsgl.inc
        INCLUDE sli.inc
        INCLUDE blitter.inc
        INCLUDE uniload.inc
        INCLUDE sbuffer.inc
        INCLUDE loader.inc
start:
        InitDPMI

        ErrorExit "InitDPMI"
        
        xor     eax,eax
        int     33h
        sub     eax,1
        ErrorExit "This program needs a mouse!"

        mov     eax,offset back_f
        mov     ebx,32
        call    LoadGFX
        ErrorExit "Unable to load backward image"
        mov     back_sli,ebx

        mov     eax,offset fname
        call    LoadUniverse
        ErrorExit "Unable to load universe!"
        mov     rw,eax

        mov     eax,640
        mov     ebx,480
        mov     ecx,16
        call    CreateVideoSLI
        ErrorExit "Unable to set video mode"

        mov     eax,640
        mov     ebx,480
        mov     ecx,32
        mov     edx,1
        call    CreateSLI
        ErrorExit "Error creating SLI"
        mov     our_sli,ebx

        mov     eax,our_sli
        call    SLI2SBuffer
        ErrorExit "Error converting SLI to SBuffer"

        mov     eax,RMet
        call    SetRenderMethode

        mov     eax,offset cam_name
        mov     ebx,rw
        mov     ecx,CAMERA_TYPE
        call    GetObjectByName
        ErrorExit "Couldn't find camera"

        call    SetActiveCamera

        mov     eax,offset mesh_name
        mov     ebx,rw
        mov     ecx,MESH_TYPE
        call    GetObjectByName
        ErrorExit "Couldn't find object"
        mov     mesh_ptr,eax

        mov     eax,offset light_name
        mov     ebx,rw
        mov     ecx,LIGHT_TYPE
        call    GetObjectByName
        ErrorExit "Couldn't find light"
        mov     light_ptr,eax

        mov     edx,light_ptr
        movf    eax,-50.0
        movf    ebx,50.0
        movf    ecx,200.0
        call    SetLightPos

        mov     eax,offset light_name1
        mov     ebx,rw
        mov     ecx,LIGHT_TYPE
        call    GetObjectByName
        ErrorExit "Couldn't find light"
        mov     light_ptr1,eax

        mov     edx,light_ptr1
        movf    eax,0.0
        movf    ebx,0.0
        movf    ecx,-50.0
        call    SetLightPos

        mov     edx,light_ptr1
        movf    eax,0.0
        movf    ebx,0.0
        movf    ecx,0.0
        call    SetLightTarget

;fld [eax.LightVector.x]
;fistp trash
;mov ebx,trash
;fld [eax.LightVector.y]
;fistp trash
;mov ecx,trash
;fld [eax.LightVector.z]
;fistp trash
;mov edx,trash
;int 3

        xor     eax,eax
        call    GetCameraOrientation
        mov     cam_alpha,eax
        mov     cam_beta,ebx
        mov     cam_gamma,ecx

        xor     eax,eax
        call    GetCameraPos
        mov     xc,eax
        mov     yc,ebx
        mov     zc,ecx

        main:
                mov     esi,back_sli
                mov     edi,our_sli
                call    Blit

                mov     ebx,our_sli
                mov     eax,rw
                call    RenderUniverse

                call    GetVideoSLI
                mov     edi,eax
                mov     esi,our_sli
                call    Blit

                call    ShowPage

                mov     eax,3
                int     33h
                movzx   ecx,cx
                movzx   edx,dx
                shr     ecx,1

                mov     trash,ecx
                fild    trash
;                fldf    10.0
;                fmulp    
                fstp    trash
                mov     eax,trash
                mov     trash,edx
                fild    trash
;                fldf    10.0
;                fmulp    
                fstp    trash
                mov     ebx,trash
                test    mouse_flag,1
                jz      no_mouse
                        mov trash,eax
                        fld trash
                        fldf 10.0
                        fmulp
                        fstp trash
                        mov eax,trash
                        mov trash,ebx
                        fld trash
                        fldf 10.0
                        fmulp
                        fstp trash
                        mov ebx,trash
                        movf    ecx,0.0
                        mov     edx,light_ptr
                        call    SetLightTarget
                        jmp     lights_ok                                
                no_mouse:
                        mov trash,eax
                        fld trash
                        fldf 320.0
                        fdivp
                        fldf 6.2831
                        fmulp
						sub esp,4						
                        fstp dword ptr ss:[esp]
                        mov eax,esp

                        mov trash,ebx
                        fld trash
                        fldf 200.0
                        fdivp
                        fldf 6.2831
                        fmulp
						sub esp,4
                        fstp dword ptr ss:[esp]
                        mov ebx,esp

                        mov     edx,mesh_ptr
                        call    RotateMesh
						add		esp,4*2
                lights_ok:                        
        mov     ah,1
        int     16h
        jz      main
        xor     ah,ah
        int     16h
        cmp     al,'o'
        jnz     no_o
                fld     cam_alpha
                fldf    0.1
                fsubp
                fstp    cam_alpha
                mov     eax,cam_alpha
                mov     ebx,cam_beta
                mov     ecx,cam_gamma
                xor     edx,edx
                call    SetCameraOrientation
                jmp     main
        no_o:
        cmp     al,'p'
        jnz     no_p
                fld     cam_alpha
                fldf    0.1
                faddp
                fstp    cam_alpha
                mov     eax,cam_alpha
                mov     ebx,cam_beta
                mov     ecx,cam_gamma
                xor     edx,edx
                call    SetCameraOrientation
                jmp     main
        no_p:
        cmp     al,'q'
        jnz     no_q
                fld     cam_beta
                fldf    0.1
                faddp
                fstp    cam_beta
                mov     eax,cam_alpha
                mov     ebx,cam_beta
                mov     ecx,cam_gamma
                xor     edx,edx
                call    SetCameraOrientation
                jmp     main                
        no_q:
        cmp     al,'a'
        jnz     no_a
                fld     cam_beta
                fldf    0.1
                fsubp
                fstp    cam_beta
                mov     eax,cam_alpha
                mov     ebx,cam_beta
                mov     ecx,cam_gamma
                xor     edx,edx
                call    SetCameraOrientation
                jmp     main
        no_a:
        cmp     al,'u'
        jnz     no_u
                fld     cam_gamma
                fldf    0.1
                fsubp
                fstp    cam_gamma
                mov     eax,cam_alpha
                mov     ebx,cam_beta
                mov     ecx,cam_gamma
                xor     edx,edx
                call    SetCameraOrientation
                jmp     main                
        no_u:
        cmp     al,'i'
        jnz     no_i
                fld     cam_gamma
                fldf    0.1
                faddp
                fstp    cam_gamma
                mov     eax,cam_alpha
                mov     ebx,cam_beta
                mov     ecx,cam_gamma
                xor     edx,edx
                call    SetCameraOrientation
                jmp     main
        no_i:
        cmp     al,'w'
        jnz     no_w
                fld     zc
                fldf    55.0
                faddp
                fstp    zc
                mov     eax,xc
                mov     ebx,yc
                mov     ecx,zc
                xor     edx,edx
                call    SetCameraPos
                jmp     main
        no_w:
        cmp     al,'s'
        jnz     no_s
                fld     zc
                fldf    55.0
                fsubp
                fstp    zc
                mov     eax,xc
                mov     ebx,yc
                mov     ecx,zc
                xor     edx,edx
                call    SetCameraPos
                jmp     main
        no_s:
        cmp     al,'z'
        jnz     no_z
                fld     xc
                fldf    55.0
                fsubp
                fstp    xc
                mov     eax,xc
                mov     ebx,yc
                mov     ecx,zc
                xor     edx,edx
                call    SetCameraPos
                jmp     main
        no_z:
        cmp     al,'x'
        jnz     no_x
                fld     xc
                fldf    55.0
                faddp
                fstp    xc
                mov     eax,xc
                mov     ebx,yc
                mov     ecx,zc
                xor     edx,edx
                call    SetCameraPos
                jmp     main
        no_x:
        cmp     al,'d'
        jnz     no_d
                fld     yc
                fldf    55.0
                fsubp
                fstp    yc
                mov     eax,xc
                mov     ebx,yc
                mov     ecx,zc
                xor     edx,edx
                call    SetCameraPos
                jmp     main
        no_d:
        cmp     al,'c'
        jnz     no_c
                fld     yc
                fldf    55.0
                faddp
                fstp    yc
                mov     eax,xc
                mov     ebx,yc
                mov     ecx,zc
                xor     edx,edx
                call    SetCameraPos
                jmp     main
        no_c:
        cmp     al,' '
        jnz     no_sp
                xor     RMet,1
                mov     eax,RMet
                call    SetRenderMethode
                jmp     main
        no_sp:
        cmp     al,'m'
        jnz     no_m
                xor     mouse_flag,1
                jmp     main
        no_m:
        dec     ah
        jnz     main
        
		mov		eax,our_sli
		call	DestroySLI
		
        mov     eax,3
        call    DestroyVideoSLI

        mov     eax,rw
        call    DestroyUniverse
        ErrorExit "Error destroying universe!"

        Exit

.data
cam_alpha       dd 0.0 ;3.1415
cam_beta        dd 0.0
cam_gamma       dd 0.0
xc              dd 0.0
yc              dd 0.0
zc              dd -256.0
RMet            dd RENDER_SOLID

fname           db "skulmask.3ds",0
cam_name        db "Camera01",0
light_name      db "Light01",0
light_name1     db "Light02",0
back_f          db "back.bmp",0
mesh_name       db "Object03",0
;mesh_name       db "0----01",0

mouse_flag      db 0

.data?
our_sli dd ?
back_sli dd ?
ourmesh dd ?
nmesh   dd ?
rw      dd ?
trash   dd ?
light_ptr       dd ?
light_ptr1      dd ?
mesh_ptr        dd ?

end start
