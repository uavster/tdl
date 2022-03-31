;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; 3D mesh renderer
;       by Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

.386p
.model flat
.code
include utils.inc
        INCLUDE 3d.inc
        INCLUDE render.inc
        INCLUDE gfx.inc
        INCLUDE sli.inc
        INCLUDE sbuffer.inc

        FOCUS_DISTANCE          EQU 256.0
        DEFAULT_CAMERA_Z        EQU -256.0

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Renders a 3D solid polygon with sbuffer
;
; INTPUT : EAX -> RENDERPOLY structure
;          EBX -> Destination SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SolidPoly       proc
        mov     edx,eax
        mov     eax,ebx
        call    GenericTriangleMapper
        ret
SolidPoly       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Renders a 3D polygon with line methode
;
; INTPUT : EAX -> RENDERPOLY structure
;          EBX -> Destination SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
LinedPoly       proc
        mov     esi,eax
        mov     edi,ebx
        mov     ebp,[esi.point1]
        fld     ds:[ebp.ScreenPos.u]
        fistp   trash
        mov     eax,trash
        fld     ds:[ebp.ScreenPos.v]
        fistp   trash
        mov     ebx,trash
        mov     ebp,[esi.point2]
        fld     ds:[ebp.ScreenPos.u]
        fistp   trash
        mov     ecx,trash
        fld     ds:[ebp.ScreenPos.v]
        fistp   trash
        mov     edx,trash
        push    esi edi
        mov     esi,LineColor
        call    Line
        pop     edi esi
        mov     ebp,[esi.point2]
        fld     ds:[ebp.ScreenPos.u]
        fistp   trash
        mov     eax,trash
        fld     ds:[ebp.ScreenPos.v]
        fistp   trash
        mov     ebx,trash
        mov     ebp,[esi.point3]
        fld     ds:[ebp.ScreenPos.u]
        fistp   trash
        mov     ecx,trash
        fld     ds:[ebp.ScreenPos.v]
        fistp   trash
        mov     edx,trash
        push    esi edi 
        mov     esi,LineColor
        call    Line
        pop     edi esi
        mov     ebp,[esi.point3]
        fld     ds:[ebp.ScreenPos.u]
        fistp   trash
        mov     eax,trash
        fld     ds:[ebp.ScreenPos.v]
        fistp   trash
        mov     ebx,trash
        mov     ebp,[esi.point1]
        fld     ds:[ebp.ScreenPos.u]
        fistp   trash
        mov     ecx,trash
        fld     ds:[ebp.ScreenPos.v]
        fistp   trash
        mov     edx,trash
        mov     esi,LineColor
        call    Line
        ret
LinedPoly       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the position of the camera from the world reference system
;
; INPUT : EAX = float X
;         EBX = float Y
;         ECX = float Z
;         EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetCameraPos    proc
        test    edx,edx
        jnz     no_def_cam_pos
                mov     edx,Camera
        no_def_cam_pos:
        mov     [edx.CamPos.x],eax
        mov     [edx.CamPos.y],ebx
        mov     [edx.CamPos.z],ecx
        ret
SetCameraPos    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the position of the camera from the world reference system
;
; INPUT  : EAX -> RENDERCAMERA or NULL if Current Camera
;
; OUTPUT : EAX = float X
;          EBX = float Y
;          ECX = float Z
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetCameraPos    proc
        mov     edx,eax
        test    eax,eax
        jnz     dont_get_current_cam_pos
                mov     edx,Camera
        dont_get_current_cam_pos:
        mov     eax,[edx.CamPos.x]
        mov     ebx,[edx.CamPos.y]
        mov     ecx,[edx.CamPos.z]
        ret
GetCameraPos    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets a pointer to default camera
;
; OUTPUT : EAX -> RENDERCAMERA structure of default camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetActiveCamera proc
        mov     eax,Camera
        ret
GetActiveCamera endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the current active camera
;
; INPUT : EAX -> RENDERCAMERA
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetActiveCamera proc
        mov     Camera,eax
        ret
SetActiveCamera endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a light position
;
; INPUT : EAX = Float X
;         EBX = Float Y
;         ECX = Float Z
;         EDX -> RENDERLIGHT
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetLightPos     proc
        mov     [edx.LightPos.x],eax
        mov     [edx.LightPos.y],ebx
        mov     [edx.LightPos.z],ecx
        ret
SetLightPos     endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a light target vector
;
; INPUT : EAX = Float target X
;         EBX = Float target Y
;         ECX = Float target Z
;         EDX -> RENDERLIGHT
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetLightTarget  proc
        mov     trash,eax
        fld     trash
        fsub    [edx.LightPos.x]
        fstp    [edx.LightVector.x]
        mov     trash,ebx
        fld     trash
        fsub    [edx.LightPos.y]
        fstp    [edx.LightVector.y]
        mov     trash,ecx
        fld     trash
        fsub    [edx.LightPos.z]
        fstp    [edx.LightVector.z]
        lea     eax,[edx.LightVector]
        call    NormalizeVector
        ret
SetLightTarget  endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the pointer to an object into the world with the given name
;
; INPUT  : EAX -> Mesh name
;          EBX -> RENDERWORLD
;          ECX = Object type
;
; OUTPUT : CF = 0 if ok
;               EAX -> World object
;          CF = 1 if object not found or invalid type
;               EAX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetObjectByName proc
        push    ebp
        mov     esi,eax
        xor     ebp,ebp
        cmp     ecx,MESH_TYPE
        jnz     not_a_mesh
                mov     eax,[ebx.MeshArray]
                lea     ebp,[ebp.MeshName]
                mov     ecx,[ebx.NumMeshes]
                mov     edx,size RENDERMESH                        
                jmp     search_object
        not_a_mesh:
        cmp     ecx,CAMERA_TYPE
        jnz     not_a_cam
                mov     eax,[ebx.CameraArray]
                lea     ebp,[ebp.CamName]
                mov     ecx,[ebx.NumCameras]
                mov     edx,size RENDERCAMERA
                jmp     search_object
        not_a_cam:
        cmp     ecx,LIGHT_TYPE
        jnz     not_a_light
                mov     eax,[ebx.LightArray]
                lea     ebp,[ebp.LightName]
                mov     ecx,[ebx.NumLights]
                mov     edx,size RENDERLIGHT
                jmp     search_object
        not_a_light:
        pop     ebp
        stc
        ret
        search_object:
        test    ecx,ecx
        jz      cant_find_obj
        parse_objects:
                lea     edi,ds:[eax+ebp]
                push    edx eax esi ecx
                call    CompareString
                pop     ecx esi eax edx
                jz      found_mesh
                add     eax,edx
        loop    parse_objects
        cant_find_obj:
        pop     ebp
        xor     eax,eax
        stc
        ret

        found_mesh:
        pop     ebp
        clc
        ret
GetObjectByName endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the orientation of the camera from the world reference system
;
; INPUT : EAX = float ALPHA
;         EBX = float BETA
;         ECX = float GAMMA
;         EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetCameraOrientation    proc
        test    edx,edx
        jnz     no_def_cam_orient
                mov     edx,Camera
        no_def_cam_orient:
        mov     [edx.CamOrientation.x],eax
        mov     [edx.CamOrientation.y],ebx
        mov     [edx.CamOrientation.z],ecx
        ; Calculate sin(ALPHA) & cos(ALPHA)
        fld     [edx.CamOrientation.x]
        fsincos
        fstp    [edx.cos_alpha]
        fstp    [edx.sin_alpha]
        ; Calculate sin(BETA) & cos(BETA)
        fld     [edx.CamOrientation.y]
        fsincos
        fstp    [edx.cos_beta]
        fstp    [edx.sin_beta]
        ; Calculate sin(GAMMA) & cos(GAMM)
        fld     [edx.CamOrientation.z]
        fsincos
        fstp    [edx.cos_gamma]
        fstp    [edx.sin_gamma]
        ret
SetCameraOrientation    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the orientation of the camera from the world reference system
;
; INPUT :  EAX -> RENDERCAMERA or NULL if Current Camera
;
; OUTPUT : EAX = float ALPHA
;          EBX = float BETA
;          ECX = float GAMMA
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
GetCameraOrientation    proc
        mov     edx,eax
        test    eax,eax
        jnz     dont_get_current_cam_or
                mov     edx,Camera
        dont_get_current_cam_or:
        mov     eax,[edx.CamOrientation.x]
        mov     ebx,[edx.CamOrientation.y]
        mov     ecx,[edx.CamOrientation.z]
        ret
GetCameraOrientation    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Points a camera to a target point
;
; INTPUT : EAX = float target X
;          EBX = float target Y
;          ECX = float target Z
;          EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetCameraTarget proc
        test    edx,edx
        jnz     no_def_cam_pointing
                mov     edx,Camera
        no_def_cam_pointing:
        mov     trash,eax
        fld     trash
        fsub    [edx.CamPos.x]
        mov     trash,ebx
        fld     trash
        fsub    [edx.CamPos.y]
        mov     trash,ecx
        fld     trash
        fsub    [edx.CamPos.z]
        ; Alpha = atan(x/z)
        fld     st(2)
        fld     st(1)
        fpatan
        fstp    trash
        mov     eax,trash
        ; Beta = atan(y/radius)
        ; radius = sqrt(x^2+y^2+z^2)
        fld     st(1)
        fld     st(1)
        fmul    st(0),st(2)
        fld     st(3)
        fmul    st(0),st(4)
        faddp
        fld     st(4)
        fmul    st(0),st(5)
        faddp
        fsqrt
        fpatan
        fstp    trash
        mov     ebx,trash
        fstp    trash
        fstp    trash
        fstp    trash
        mov     ecx,[edx.CamOrientation.z]
        call    SetCameraOrientation
        ret
SetCameraTarget endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the color of the Lined Render in B:G:R:0 format
;
; INPUT : EAX = Color in B:G:R:0 format
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetLinedRenderColor    proc
        mov     LineColor,eax
        ret
SetLinedRenderColor    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the current render methode
;
; INPUT : EAX = Render methode
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetRenderMethode        proc
        mov     RenderMethode,eax
        ret
SetRenderMethode        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the camera focus distance
;
; INPUT : EAX = New focus distance in FLOAT (camera apperture)
;         EBX -> RENDERCAMERA (NULL for active camera)
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
SetApperture    proc
        test    ebx,ebx
        jnz     not_active_one
                mov     ebx,Camera
        not_active_one:
        mov     [ebx.CamFocus],eax
        ret
SetApperture    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Perspective transform of a RENDERPOINT
;
; INPUT  : EAX = Center X of destination SLI
;          EBX = Center Y of destination SLI
;          ECX -> RENDERPOINT
;          EDX -> RENDERCAMERA
;          XS = Float where to store 2D X
;          YS = Float where to store 2D Y
;
; OUTPUT : 2D x,y stored
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TransformPoint  MACRO XS,YS,IZ
        ; X0 = Xo - XC
        fld     [ecx.PointPos.x]
        fsub    [edx.CamPos.x]
        fstp    x0
        ; Y0 = Yo - YC
        fld     [ecx.PointPos.y]
        fsub    [edx.CamPos.y]
        fstp    y0
        ; Z0 = Zo - ZC
        fld     [ecx.PointPos.z]
        fsub    [edx.CamPos.z]
        fstp    z0

        ; Z1 = Z0*cos(alpha)+X0*sin(alpha)
        fld     z0                      ; Z0
        fmul    [edx.cos_alpha]         ; *cos(alpha)
        fld     x0                      ; X0
        fmul    [edx.sin_alpha]         ; *sin(alpha)
        faddp                           ; +
        ; Xc = X0*cos(alpha)-Z0*sin(alpha)
        fld     x0                      ; X0
        fmul    [edx.cos_alpha]         ; *cos(alpha)
        fld     z0                      ; Z0
        fmul    [edx.sin_alpha]         ; *sin(alpha)
        fsubp                           ; -
        ; Yc = Y0*cos(beta)-Z0*sin(beta)
        fld     y0                 ; Y0
        fmul    [edx.cos_beta]          ; *cos(beta)
        fld     st(2)                   ; Z1
        fmul    [edx.sin_beta]          ; *sin(beta)
        fsubp                           ; -
        ; Zc = Z1*cos(beta)+Y0*sin(beta)
        fld     st(2)
        fmul    [edx.cos_beta]          ; *cos(beta)
        fld     y0                      ; Y0
        fmul    [edx.sin_beta]          ; *sin(beta)
        faddp                           ; +

        ; Is this point behind camera plain?
        mov     [ecx.PointFlags],0
        ftst
        push    eax
        fnstsw  ax
        sahf
        pop     eax
        jae     not_behind
                or      [ecx.PointFlags],1
        not_behind:

        ; D / Zc
        fld1
        fdivrp
        fst     IZ
        fmul    [edx.CamFocus]

        ; Ys = Yc * D / Zc
        fmul    st(1),st(0)

        ; Xs = D * Xc / Zc
        fmul    st(0),st(2)

        ; Ys = Xs*sin(gamma)-Ys*cos(gamma)
        fld     st(0)
        fmul    [edx.sin_gamma]
        fld     st(2)
        fmul    [edx.cos_gamma]
        fsubp
        ; Xs = Xs*cos(gamma)+Ys*sin(gamma)
        fld     st(1)
        fmul    [edx.cos_gamma]
        fld     st(3)
        fmul    [edx.sin_gamma]
        faddp

        fadd    MiddleX
        fstp    XS                      ; XS

        fadd    MiddleY
        fstp    YS                      ; YS

        fstp    trash
        fstp    trash
        fstp    trash
        fstp    trash
        fstp    trash
ENDM

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Perspective transform of 3D points
;
; INPUT  : EAX -> RENDERMESH structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
TransformMesh   proc
        mov     ebp,[eax.points]
        test    ebp,ebp
        jz      no_points_to_transform
        mov     ecx,[eax.pointdata]
        mov     edx,Camera
        trf_points:
                TransformPoint [ecx.ScreenPos.u],[ecx.ScreenPos.v],[ecx.InverseZ]
                add     ecx,size RENDERPOINT
        dec     ebp
        jnz     trf_points
        no_points_to_transform:
        ret                            
TransformMesh   endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Decides if a polygon will be rendered or not
;
; INPUT  : EAX -> RENDERPOLY structure
;          EBX -> Destination SLI
;
; OUTPUT : CF = 0 if polygon will be shown
;          CF = 1 otherwise
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
HandleVisibility        proc
        push    ecx eax ebx

        ; -----------------------3D clipping----------------------------------
        ; De momento, no rederizamos el poly si hay alg£n punto...
        ; ...detr s del plano de c mara
        mov     esi,[eax.point1]
        mov     edi,[eax.point2]
        mov     ebp,[eax.point3]
;        mov     poly_limits,esi
;        mov     poly_limits+4,edi
;        mov     poly_limits+4*2,ebp
        test    [esi.PointFlags],1
        jnz     dont_render_poly2
        test    [edi.PointFlags],1
        jnz     dont_render_poly2
        test    ds:[ebp.PointFlags],1
        jnz     dont_render_poly2

        ; --------------------Back/Front Face Culling-------------------------
        mov     ebx,[eax.PolyFlags]
        and     bl,BACK_FACE_CULLED OR FRONT_FACE_CULLED
        cmp     bl,BACK_FACE_CULLED OR FRONT_FACE_CULLED
        jz      dont_render_poly2
        cmp     bl,0
        jz      render_poly2
        mov     ecx,[eax.point2]
        mov     ebx,[eax.point1]
        fld     [ebx.ScreenPos.u]
        fsub    [ecx.ScreenPos.u]
        fld     [ebx.ScreenPos.v]
        fsub    [ecx.ScreenPos.v]
        mov     ebx,[eax.point3]
        fld     [ebx.ScreenPos.u]
        fsub    [ecx.ScreenPos.u]
        fld     [ebx.ScreenPos.v]
        fsub    [ecx.ScreenPos.v]
        fmulp   st(3)
        fmulp   st(1)
        test    [eax.PolyFlags],FRONT_FACE_CULLED
        jz      its_back_face_culled
                fxch
        its_back_face_culled:
        fsubp
        ftst
        fnstsw  ax
        fstp    trash
        sahf
        jbe     dont_render_poly2
        
comment #
        ; -----------------------2D clipping----------------------------------
        mov     ecx,[ebx.SLIClip.SLRR1.SLPX]
        mov     edx,[ebx.SLIClip.SLRR1.SLPY]
        ; Move transformed vertexs to origin 2D clip region
        sub     [esi.ScreenPos.u],ecx
        sub     [edi.ScreenPos.u],ecx
        sub     ds:[ebp.ScreenPos.u],ecx
        sub     [esi.ScreenPos.v],edx
        sub     [edi.ScreenPos.v],edx
        sub     ds:[ebp.ScreenPos.v],edx

        ; Calculate sizes of clip region
        sub     ecx,[ebx.SLIClip.SLRR2.SLPX]
        sub     edx,[ebx.SLIClip.SLRR2.SLPY]
        neg     ecx
        neg     edx

        xor     ebp,ebp
        test_poly_limits:
                mov     esi,[ebp*4+poly_limits]
                cmp     ebp,2
                jnz     no_module
                        mov     edi,poly_limits
                        jmp     short module_done
                no_module:
                        lea     edi,[ebp+1]
                        mov     edi,[edi*4+poly_limits]
                module_done:

                mov     eax,[esi.ScreenPos.u]
                mov     ebx,[edi.ScreenPos.u]
                ; If both points are outside with same sign, don't draw line
                cmp     eax,ecx
                jb      xs_are_ok
                cmp     ebx,ecx
                jb      xs_are_ok
                sar     eax,31
                sar     ebx,31
                xor     eax,ebx
                jz      dont_draw_line

                xs_are_ok:
                mov     eax,[esi.ScreenPos.v]
                mov     ebx,[edi.ScreenPos.v]
                cmp     eax,edx
                jb      render_poly
                cmp     ebx,edx
                jb      render_poly
                sar     eax,31
                sar     ebx,31
                xor     eax,ebx
                jnz     render_poly
                ys_are_ok:

                dont_draw_line:
        inc     ebp
        cmp     ebp,3
        jnz     test_poly_limits
        dont_render_poly:
        pop     ebx
        mov     ecx,[ebx.SLIClip.SLRR1.SLPX]
        mov     edx,[ebx.SLIClip.SLRR1.SLPY]
        ; Move transformed vertexs to origin 2D clip region
        mov     esi,poly_limits
        mov     edi,poly_limits+4
        mov     ebp,poly_limits+4*2
        add     [esi.ScreenPos.u],ecx
        add     [edi.ScreenPos.u],ecx
        add     ds:[ebp.ScreenPos.u],ecx
        add     [esi.ScreenPos.v],edx
        add     [edi.ScreenPos.v],edx
        add     ds:[ebp.ScreenPos.v],edx
        pop     eax ecx
        stc
        ret

        render_poly:
        pop     ebx
        mov     ecx,[ebx.SLIClip.SLRR1.SLPX]
        mov     edx,[ebx.SLIClip.SLRR1.SLPY]
        ; Move transformed vertexs to origin 2D clip region
        mov     esi,poly_limits
        mov     edi,poly_limits+4
        mov     ebp,poly_limits+4*2
        add     [esi.ScreenPos.u],ecx
        add     [edi.ScreenPos.u],ecx
        add     ds:[ebp.ScreenPos.u],ecx
        add     [esi.ScreenPos.v],edx
        add     [edi.ScreenPos.v],edx
        add     ds:[ebp.ScreenPos.v],edx
        pop     eax ecx
#
        render_poly2:
        pop ebx eax ecx
        clc
        ret

        dont_render_poly2:
        pop     ebx eax ecx
        stc
        ret

;poly_limits     dd ?,?,?
HandleVisibility        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Calculates ilumination of the vertices of a polygon
; with the RENDERLIGHTs array
;
; INPUT : EAX -> RENDERMESH structure
;         EBX -> RENDERLIGHTs array
;         ECX = Number of RENDERLIGHTS
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
Iluminate       proc
		test	ecx,ecx
		jz		no_more_lights
        mov     edi,eax
                mov     edx,[edi.points]
                mov     esi,[edi.pointdata]
                ilum_points:
                        fld     [ebx.LightVector.x]
                        fmul    [esi.Normal.x]
                        fld     [ebx.LightVector.y]
                        fmul    [esi.Normal.y]
                        faddp
                        fld     [ebx.LightVector.z]
                        fmul    [esi.Normal.z]
                        faddp
                        ftst
                        fnstsw  ax
                        sahf
                        jae     with_light
                                fstp    trash
                                fldz
                        with_light:
                        fmul    light_constant
                        fstp    [esi.Properties.Light1]
                        add     esi,size RENDERPOINT                        
                dec     edx
                jnz     ilum_points

                add     ebx,size RENDERLIGHT
        dec     ecx
        jz      no_more_lights
        walk_renderlights:
                mov     edx,[edi.points]
                mov     esi,[edi.pointdata]
                ilum_points1:
                        fld     [ebx.LightVector.x]
                        fmul    [esi.Normal.x]
                        fld     [ebx.LightVector.y]
                        fmul    [esi.Normal.y]
                        faddp
                        fld     [ebx.LightVector.z]
                        fmul    [esi.Normal.z]
                        faddp
                        ftst
                        fnstsw  ax
                        sahf
                        jae     with_light1
                                fstp    trash
                                fldz
                        with_light1:
                        fmul    light_constant
                        fadd    [esi.Properties.Light1]
                        fcom    light_constant
                        fnstsw  ax
                        sahf
                        jb      more_lights
                                fstp    trash
                                fld     light_constant
                        more_lights:
                        fstp    [esi.Properties.Light1]
                        add     esi,size RENDERPOINT                        
                dec     edx
                jnz     ilum_points1

                add     ebx,size RENDERLIGHT
        dec     ecx
        jnz     walk_renderlights
        no_more_lights:
        ret
light_constant  dd 255.0
Iluminate       endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Rotates a RENDERMESH
;
; INPUT : EAX -> Float ALPHA
;         EBX -> Float BETA
;         EDX -> RENDERMESH structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RotateMesh      proc
        fld     dword ptr [eax]
        fsincos
        fstp    m_cos_alpha
        fstp    m_sin_alpha

        fld     dword ptr [ebx]
        fsincos
        fstp    m_cos_beta
        fstp    m_sin_beta

        mov     ecx,[edx.points]
        mov     ebx,[edx.pointdata]

        rotate_points:
                ; X0 = Xo - Xp
                fld     [ebx.OrigPointPos.x]
                fsub    [edx.Pivot.x]
                fstp    x0
                ; Y0 = Yo - Yp
                fld     [ebx.OrigPointPos.y]
                fsub    [edx.Pivot.y]
                fstp    y0
                ; Z0 = Zo - Zp
                fld     [ebx.OrigPointPos.z]
                fsub    [edx.Pivot.z]
                fstp    z0

                ; Rotate normals
                fld     x0
                fadd    [ebx.OrigNormal.x]
                fstp    v1
                fld     y0
                fadd    [ebx.OrigNormal.y]
                fstp    v2
                fld     z0
                fadd    [ebx.OrigNormal.z]
                fstp    v3
                ; Z1 = Z0*cos(alpha)+X0*sin(alpha)
                fld     v3          ; Z0
                fmul    m_cos_alpha         ; *cos(alpha)
                fld     v1          ; X0
                fmul    m_sin_alpha         ; *sin(alpha)
                faddp                           ; +
                ; Xc = X0*cos(alpha)-Z0*sin(alpha)
                fld     v1          ; X0
                fmul    m_cos_alpha         ; *cos(alpha)
                fld     v3         ; Z0
                fmul    m_sin_alpha         ; *sin(alpha)
                fsubp                           ; -
                fstp    xn0
                ; Yc = Y0*cos(beta)-Z0*sin(beta)
                fld     v2     ; Y0
                fmul    m_cos_beta          ; *cos(beta)
                fld     st(1)                   ; Z1
                fmul    m_sin_beta          ; *sin(beta)
                fsubp                           ; -
                fstp    yn0
                ; Zc = Z1*cos(beta)+Y0*sin(beta)
                fld     st(0)
                fmul    m_cos_beta         ; *cos(beta)
                fld     v2          ; Y0
                fmul    m_sin_beta          ; *sin(beta)
                faddp                           ; +
                fstp    [ebx.Normal.z]
                fstp    trash
                fld     xn0
                fstp    [ebx.Normal.x]
                fld     yn0
                fstp    [ebx.Normal.y]


                ; Rotate points
                ; Z1 = Z0*cos(alpha)+X0*sin(alpha)
                fld     z0                      ; Z0
                fmul    m_cos_alpha         ; *cos(alpha)
                fld     x0                      ; X0
                fmul    m_sin_alpha         ; *sin(alpha)
                faddp                           ; +
                ; Xc = X0*cos(alpha)-Z0*sin(alpha)
                fld     x0                      ; X0
                fmul    m_cos_alpha         ; *cos(alpha)
                fld     z0                      ; Z0
                fmul    m_sin_alpha         ; *sin(alpha)
                fsubp                           ; -
                fstp    [ebx.PointPos.x]
                ; Yc = Y0*cos(beta)-Z0*sin(beta)
                fld     y0                 ; Y0
                fmul    m_cos_beta          ; *cos(beta)
                fld     st(1)                   ; Z1
                fmul    m_sin_beta          ; *sin(beta)
                fsubp                           ; -
                fstp    [ebx.PointPos.y]
                ; Zc = Z1*cos(beta)+Y0*sin(beta)
                fld     st(0)
                fmul    m_cos_beta         ; *cos(beta)
                fld     y0                      ; Y0
                fmul    m_sin_beta          ; *sin(beta)
                faddp                           ; +                
                fstp    [ebx.PointPos.z]
                fstp    trash

                ; Untransform normals                        
                fld     [ebx.Normal.x]
                fsub    [ebx.PointPos.x]
                fstp    [ebx.Normal.x]
                fld     [ebx.Normal.y]
                fsub    [ebx.PointPos.y]
                fstp    [ebx.Normal.y]
                fld     [ebx.Normal.z]
                fsub    [ebx.PointPos.z]
                fstp    [ebx.Normal.z]

                ; X0 = Xo + Xp
                fld     [ebx.PointPos.x]
                fadd    [edx.Pivot.x]
                fstp    [ebx.PointPos.x]
                ; Y0 = Yo + Yp
                fld     [ebx.PointPos.y]
                fadd    [edx.Pivot.y]
                fstp    [ebx.PointPos.y]
                ; Z0 = Zo + Zp
                fld     [ebx.PointPos.z]
                fadd    [edx.Pivot.z]
                fstp    [ebx.PointPos.z]

                add     ebx,size RENDERPOINT
        dec     ecx
        jnz     rotate_points
        ret
m_sin_alpha     dd ?
m_cos_alpha     dd ?
m_sin_beta      dd ?
m_cos_beta      dd ?
v1              dd ?
v2              dd ?
v3              dd ?
xn0             dd ?
yn0             dd ?
RotateMesh      endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Moves a mesh pivot
;
; INPUT : EAX = Float X
;         EBX = Float Y
;         ECX = Float Z
;         EDX -> RENDERMESH structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
MoveMesh        proc
        mov     [edx.Pivot.x],eax
        mov     [edx.Pivot.y],ebx
        mov     [edx.Pivot.z],ecx
        ret
MoveMesh        endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Renders a 3D mesh with the given methode
;
; INPUT : EAX -> RENDERMESH structure
;         EBX -> Destination SLI
;         ECX -> RENDERWORLD structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RenderObject    proc
        mov     edx,[ebx.SLIXSize]
        shr     edx,1
        mov     MiddleX,edx
        fild    MiddleX
        fstp    MiddleX

        mov     edx,[ebx.SLIYSize]
        shr     edx,1
        mov     MiddleY,edx
        fild    MiddleY
        fstp    MiddleY

        ; Perspective transform for 3d points
        push    eax ebx ecx
        call    TransformMesh
        pop     ecx ebx eax

        push    eax ebx
        mov     ebx,[ecx.LightArray]
        mov     ecx,[ecx.NumLights]
        call    Iluminate
        pop     ebx eax

        mov     ecx,[eax.polygons]
        test    ecx,ecx
        jz      no_polygons_to_render
        mov     eax,[eax.polydata]
        render_polys:
                ; Back/Front face culling and clipping
                call    HandleVisibility
                jc      poly_wont_be_shown
                        ; Polygon drawing
                        push    ecx eax ebx
                        mov     edx,RenderMethode
                        call    [edx*4+RenderMethodes]
                        pop     ebx eax ecx
                poly_wont_be_shown:
                add     eax,size RENDERPOLY
        dec     ecx
        jnz     render_polys
        no_polygons_to_render:
        ret
RenderObject    endp

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Renders the 3D world 
;
; INPUT : EAX -> RENDERWORLD structure
;         EBX -> Destination SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
RenderUniverse  proc
        push    ebp
        mov     our_sli,ebx
        mov     our_world,eax

        cmp     RenderMethode,RENDER_SOLID
        jnz     dont_init_sb
				; Prepare SLI for sbuffer, if not done so already
				cmp		[SLI ptr ebx.SLISBufferNfo],0
				jnz		sbuffer_created
						mov		eax,ebx
						call	SLI2SBuffer						
				sbuffer_created:
                mov     eax,our_sli
                call    InitSBufferSLI

		dont_init_sb:
		mov		eax,our_world
        mov     ebx,our_sli
        mov     ecx,[eax.NumMeshes]
		test	ecx,ecx
		jz		no_meshes
        mov     eax,[eax.MeshArray]
        render_meshes:
                push    eax ecx
                mov     ebx,our_sli
                mov     ecx,our_world
                call    RenderObject
                pop     ecx eax
                add     eax,size RENDERMESH
        loop    render_meshes

		no_meshes:
        cmp     RenderMethode,RENDER_SOLID
        jnz     dont_render_sb
                mov     eax,our_sli
                call    RenderSBufferSLI
        dont_render_sb:
        pop     ebp
        ret
RenderUniverse  endp

.data
RenderMethode   dd RENDER_SOLID
RenderMethodes  dd offset LinedPoly,offset SolidPoly

Camera          dd offset DefaultCamera

DefaultCamera   dd 0.0,0.0,DEFAULT_CAMERA_Z
                dd 0.0,0.0,0.0
                dd FOCUS_DISTANCE
                dd 0.0,1.0,0.0,1.0,0.0,1.0
                db "Default Camera",0

LineColor       dd 0ffffffh     ; White

.data?
MiddleX         dd ?
MiddleY         dd ?

x0              dd ?
y0              dd ?
z0              dd ?

our_sli         dd ?
our_world       dd ?

trash           dd ?

end
