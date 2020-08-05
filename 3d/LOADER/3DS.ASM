;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; 3DS loading procedures
;
; Author: Ignacio Mellado Bataller (a.k.a. B52 / The DarkRising)
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

JUMPS

.386p
.model flat
.code
        INCLUDE filesys.inc
        INCLUDE alloc.inc
        INCLUDE utils.inc
        INCLUDE stderror.inc
        INCLUDE 3ds.inc
        INCLUDE 3d.inc
        INCLUDE render.inc
        INCLUDE littable.inc

FLOAT   STRUC
        dd ?
ENDS

SHORT_INT       STRUC
        dw ?
ENDS

; 3DS chunk hierarchy
PRIMARY_CHUNK   EQU 4D4Dh

        MESH_DATA_CHUNK EQU 3D3Dh

                OBJECT_BLOCK_CHUNK      EQU 4000h
                        TRIANG_POLY_OBJECT_CHUNK EQU 4100h
                                VERTEX_LIST_CHUNK       EQU 4110h
                                FACE_LIST_CHUNK         EQU 4120h
                                        MESH_MAT_GROUP_CHUNK    EQU 4130h
                                TEX_VERT_LIST_CHUNK     EQU 4140h
                        LIGHT_CHUNK     EQU 4600h
                            SPOTLIGHT_CHUNK     EQU 4610h
                        CAMERA_CHUNK    EQU 4700h

                MATERIAL_CHUNK  EQU 0AFFFh
                        MATNAME_CHUNK           EQU 0A000h
                        MATTEXTFILE_CHUNK       EQU 0A200h
                                MATTEXTNAME_CHUNK       EQU 0A300h

; Chunk header
TCHUNK  struc
        chunk_id        dw ?
        next_chunk      dd ?
        ends

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Generic chunk parser
;
; INPUT  : AX  = chunk identifier
;          ECX = size of buffer where to search chunk
;          DS:ESI -> point where to start searching chunk
;          EBX -> near procedure to call when chunk is found
;
;               Near procedure is called with:
;                       DS:ESI -> chunk data
;                       ECX = size of chunk data
;
; OUTPUT : CF = 0 if any chunk found
;          CF = 1 otherwise
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
scan_chunk      proc
        push    ecx esi
        mov     result,0
        mov     inchunk_proc,ebx
        mov     edx,esi
        add     edx,ecx
        search_chunk:
                cmp     [esi.chunk_id],ax
                jne     no_chunk_data
                        mov     result,1
                        mov     ecx,[esi.next_chunk]
                        push    inchunk_proc edx eax esi
                        add     esi,size TCHUNK
                        sub     ecx,size TCHUNK
                        call    inchunk_proc
                        pop     esi eax edx inchunk_proc
                no_chunk_data:
        add     esi,[esi.next_chunk]    ; goto next chunk
        cmp     edx,esi
        jnz     search_chunk
        pop     esi ecx
        sub     result,1    ; CARRY = 1 if no chunk found
        void_proc:
        ret
inchunk_proc    dd offset void_proc
result          dd ?
scan_chunk      endp

;---------------------------------
; Chunk routines
;---------------------------------
search_mesh     proc
        ; Search meshes
        mov     ax,MESH_DATA_CHUNK
        mov     ebx,offset parse_mesh
        call    scan_chunk
        ret
search_mesh     endp
;---------------------------------
found_material  proc
        test    OnlyTest,1
        jnz     skip_material
                mov     ax,MATNAME_CHUNK
                mov     ebx,offset found_matname
                call    scan_chunk
                mov     ax,MATTEXTFILE_CHUNK
                mov     ebx,offset found_matfile
                call    scan_chunk
        skip_material:
        inc     NMaterials
        ret
found_material  endp
;---------------------------------
found_matname   proc
        mov     edi,NMaterials
        imul    edi,size RENDERMATERIAL
        add     edi,MaterialOffset
        lea     edi,[edi.MatName]
        call    CopyString
        ret
found_matname   endp
;---------------------------------
found_matfile   proc
        mov     ax,MATTEXTNAME_CHUNK
        mov     ebx,offset found_mattext
        call    scan_chunk
        ret
found_matfile   endp
;---------------------------------
found_mattext   proc
        mov     eax,esi
        mov     ebx,8   ; 8 bits
        call    LoadGFX
        ErrorCode eax
        mov     edi,NMaterials
        imul    edi,size RENDERMATERIAL
        add     edi,MaterialOffset
        mov     [edi.MatSLI],ebx

        mov     eax,ebx
        mov     ebx,1   ; Negro - Original
        mov     ecx,129 ; 1024 bytes por nivel : 128Kb
        call    CreateLitTableSLI
        ret
found_mattext   endp
;---------------------------------
parse_mesh      proc
        ; Search materials
        mov     ax,MATERIAL_CHUNK
        mov     ebx,offset found_material
        call    scan_chunk
        ; Search object
        mov     ax,OBJECT_BLOCK_CHUNK
        mov     ebx,offset found_obj
        call    scan_chunk
        ret
parse_mesh      endp
;---------------------------------
found_obj       proc
        ; Jump over the name string
        push    ecx esi
        mov     ObjName,esi
        call    StringLength
        inc     ecx             ; Zero at end
        mov     ebx,ecx
        pop     esi ecx
        add     esi,ebx
        sub     ecx,ebx
        ; Find object data
        mov     ax,TRIANG_POLY_OBJECT_CHUNK
        mov     ebx,offset search_tpolyobj
        call    scan_chunk
        ; Find camera data
        mov     ax,CAMERA_CHUNK
        mov     ebx,offset found_camera
        call    scan_chunk
        ; Find lights
        mov     ax,LIGHT_CHUNK
        mov     ebx,offset found_light
        call    scan_chunk
        ret
found_obj       endp
;---------------------------------

N_LIGHT STRUC
        light_x         dd ?
        light_z         dd ?
        light_y         dd ?
ENDS

SPOT_L  STRUC
        l_target_x      dd ?
        l_target_z      dd ?
        l_target_y      dd ?
        hotspot         dd ?
        falloff         dd ?
ENDS

found_light     proc
        test    OnlyTest,1
        jnz     dont_take_light
        mov     eax,NLights
        imul    eax,size RENDERLIGHT
        add     eax,LightOffset
        mov     ebx,[esi.light_x]
        mov     [eax.LightPos.x],ebx
        mov     ebx,[esi.light_y]
        mov     [eax.LightPos.y],ebx
        mov     ebx,[esi.light_z]
        mov     [eax.LightPos.z],ebx
        mov     light_offset,eax

        sub     ecx,size N_LIGHT
        add     esi,size N_LIGHT
        mov     ax,SPOTLIGHT_CHUNK
        mov     ebx,offset found_spotlight
        call    scan_chunk

        mov     esi,light_offset
        fld     [esi.LightVector.x]
        fsub    [esi.LightPos.x]
        fstp    [esi.LightVector.x]
        fld     [esi.LightVector.y]
        fsub    [esi.LightPos.y]
        fstp    [esi.LightVector.y]
        fld     [esi.LightVector.z]
        fsub    [esi.LightPos.z]
        fstp    [esi.LightVector.z]
        lea     eax,[esi.LightVector]
        call    NormalizeVector

        mov     esi,ObjName
        mov     edi,light_offset
        lea     edi,[edi.LightName]
        call    CopyString

        dont_take_light:
        inc     NLights
        ret
light_offset    dd ?
found_light     endp
;---------------------------------
found_spotlight proc
        mov     ebx,light_offset
        mov     eax,[esi.l_target_x]
        mov     [ebx.LightVector.x],eax
        mov     eax,[esi.l_target_y]
        mov     [ebx.LightVector.y],eax
        mov     eax,[esi.l_target_z]
        mov     [ebx.LightVector.z],eax
        ret
found_spotlight endp
;---------------------------------

N_Camera        STRUC
        camera_x        dd ?
        camera_y        dd ?
        camera_z        dd ?
                           
        target_x        dd ?
        target_y        dd ?
        target_z        dd ?

        bank_angle      dd ?
        focus           dd ?
ENDS

found_camera    proc
        test    OnlyTest,1
        jnz     dont_take_cam
                ; Take camera data
                mov     edx,NCameras
                imul    edx,size RENDERCAMERA
                add     edx,CameraOffset

                mov     eax,[esi.camera_x]
                mov     [edx.CamPos.x],eax
                mov     eax,[esi.camera_y]
                mov     [edx.CamPos.z],eax
                mov     eax,[esi.camera_z]
                mov     [edx.CamPos.y],eax
                fld     [esi.focus]
                fmul    PixelsPerMillimeter
                fstp    [edx.CamFocus]

                mov     eax,[esi.bank_angle]
                mov     [edx.CamOrientation.z],eax

                mov     eax,[esi.target_x]
                mov     ebx,[esi.target_z]
                mov     ecx,[esi.target_y]
                push    esi edx
                call    SetCameraTarget
                pop     edx esi

                mov     esi,ObjName
                lea     edi,[edx.CamName]
                call    CopyString
        dont_take_cam:
        inc     NCameras
        ret
PixelsPerMillimeter     dd PIXELS_PER_MILLIMETER
found_camera    endp
;---------------------------------
search_tpolyobj proc
        inc     NMeshes
        test    OnlyTest,1
        jnz     dont_fill1
        ; Fill in RENDERMESH structure
        mov     edi,CurrentMesh
        mov     eax,CurrentPoly
        mov     [edi.polydata],eax
        mov     eax,CurrentPoint
        mov     [edi.pointdata],eax

        mov     NPoints,0
        mov     NPolys,0

        dont_fill1:
        ; Buscamos listas de caras del objeto antes que la de puntos
        mov     ax,FACE_LIST_CHUNK
        mov     ebx,offset found_face_list
        call    scan_chunk
        ; Buscamos puntos de textura de los v굍tices
        mov     ax,TEX_VERT_LIST_CHUNK
        mov     ebx,offset found_tex_vert_list
        call    scan_chunk
        ; Buscamos listas de v굍tices del objeto

        fldz
        fst     PivotX
        fst     PivotY
        fstp    PivotZ

        mov     ax,VERTEX_LIST_CHUNK
        mov     ebx,offset found_vertex_list
        call    scan_chunk

        test    OnlyTest,1
        jnz     dont_fill2

        ; Fill in RENDERMESH structure
        mov     edi,CurrentMesh
        mov     eax,NPolys
        mov     [edi.polygons],eax
        mov     eax,NPoints
        mov     [edi.points],eax
        add     CurrentMesh,size RENDERMESH

        fld     PivotX
        fidiv   NPoints
        fstp    [edi.Pivot.x]
        fld     PivotY
        fidiv   NPoints
        fstp    [edi.Pivot.z]
        fld     PivotZ
        fidiv   NPoints
        fstp    [edi.Pivot.y]

        mov     esi,ObjName
        lea     edi,[edi.MeshName]
        call    CopyString
        dont_fill2:
        ret
search_tpolyobj endp
;---------------------------------
found_mat_group proc
        ; Buscamos el offset del SLI de textura de entre los de la lista
        mov     ecx,NMaterials
        test    ecx,ecx
        jz      no_materials
        mov     edi,MaterialOffset
        search_material:
                push    ecx esi edi
                lea     edi,[edi.MatName]
                call    CompareString
                pop     edi esi ecx
                jnc     found_mat
                add     edi,size RENDERMATERIAL
        loop    search_material
        no_materials:
        ret
        found_mat:
        push    [edi.MatSLI] esi
        call    StringLength
        pop     esi
        add     esi,ecx
        inc     esi             ; + '\0' del final
        pop     eax
        test    eax,eax
        jz      no_faces_with_material
        xor     ecx,ecx
        mov     cx,[esi]        ; N즡ero de caras de la lista
        test    ecx,ecx
        jz      no_faces_with_material
        add     esi,size SHORT_INT
        walk_face_mats:
                xor     ebx,ebx
                mov     bx,[esi]
                imul    ebx,size RENDERPOLY
                add     ebx,CurrentPoly
                mov     [ebx.texture1],eax
                mov     [ebx.PolyType],3
                mov     [ebx.N],3
                add     esi,size SHORT_INT
        loop    walk_face_mats
        no_faces_with_material:
        ret
        ret
found_mat_group endp
;---------------------------------
found_vertex_list       proc
        xor     ecx,ecx
        mov     cx,[esi]
        or      ecx,ecx
        jz      no_vertex_here
        ; Treat ECX vertexs
                add     NPoints,ecx
                test    OnlyTest,1
                jnz     no_vertex_here
                        add     esi,size SHORT_INT
                        mov     edi,CurrentPoint
                        copy_points:
                                mov     eax,[esi]
                                mov     [edi.PointPos.x],eax
                                mov     [edi.OrigPointPos.x],eax
                                fld     dword ptr [esi]
                                fadd    PivotX
                                fstp    PivotX
                                mov     eax,[esi+size FLOAT]
                                mov     [edi.PointPos.z],eax
                                mov     [edi.OrigPointPos.z],eax
                                fld     dword ptr [esi+size FLOAT]
                                fadd    PivotY
                                fstp    PivotY
                                mov     eax,[esi+2*size FLOAT]
                                mov     [edi.PointPos.y],eax
                                mov     [edi.OrigPointPos.y],eax
                                fld     dword ptr [esi+2*size FLOAT]
                                fadd    PivotZ
                                fstp    PivotZ
                                fldf    20.0   ; Iluminaci줻 inicial
                                fstp    [edi.Light1]
                                add     esi,3*size FLOAT
                                add     edi,size RENDERPOINT
                        loop    copy_points
                        mov     CurrentPoint,edi
        no_vertex_here:
        ret
PivotX  dd ?   
PivotY  dd ?   
PivotZ  dd ?   
found_vertex_list       endp
;---------------------------------
found_face_list proc
        mov     ebp,ecx
        xor     ecx,ecx
        mov     cx,[esi]
        imul    ecx,4*size SHORT_INT
        add     ecx,size SHORT_INT
        sub     ebp,ecx         ; EBP = Size of rest of data (MATERIAL GROUPS...)

        xor     ecx,ecx
        mov     cx,[esi]        
        or      ecx,ecx
        jz      no_faces_here
        ; Treat ECX faces
                add     NPolys,ecx
                test    OnlyTest,1
                jnz     no_faces_here
                        add     esi,size SHORT_INT
                        mov     edi,CurrentPoly
                        copy_polys:
                                ; Flat por defecto
                                mov     [edi.PolyFlags],BACK_FACE_CULLED
                                mov     [edi.PolyType],1
                                mov     [edi.N],0
                                mov     [edi.texture1],0ff0000h ; RED
                                xor     eax,eax
                                mov     ax,[esi]
                                imul    eax,size RENDERPOINT
                                add     eax,CurrentPoint
                                mov     [edi.point1],eax

                                xor     eax,eax
                                mov     ax,[esi+size SHORT_INT]
                                imul    eax,size RENDERPOINT
                                add     eax,CurrentPoint
                                mov     [edi.point2],eax

                                xor     eax,eax
                                mov     ax,[esi+2*size SHORT_INT]
                                imul    eax,size RENDERPOINT
                                add     eax,CurrentPoint
                                mov     [edi.point3],eax

                                ; Fourth short is for flags
                                add     esi,4*size SHORT_INT
                                add     edi,size RENDERPOLY
                        loop    copy_polys
                        ; Buscamos listas de caras por textura
                        mov     ax,MESH_MAT_GROUP_CHUNK
                        mov     ebx,offset found_mat_group
                        mov     ecx,ebp
                        push    edi
                        call    scan_chunk
                        pop     CurrentPoly
                        mov eax,CurrentPoly
        no_faces_here:
        ret
found_face_list endp
;---------------------------------
found_tex_vert_list     proc
        test    OnlyTest,1
        jnz     no_text_verts_here
                xor     ecx,ecx
                mov     cx,[esi]
                or      ecx,ecx
                jz      no_text_verts_here
                ; Treat ECX texture vertices
                        add     esi,size SHORT_INT
                        mov     edi,CurrentPoint
                        copy_tex_verts:
                                fld     dword ptr [esi]
                                fldf    255.0
                                fmulp
                                fstp    [edi.TextPos.u]
                                fld     dword ptr [esi+size FLOAT]
                                fldf    -255.0
                                fmulp
                                fstp    [edi.TextPos.v]
                                add     esi,2*size FLOAT
                                add     edi,size RENDERPOINT
                        loop    copy_tex_verts
        no_text_verts_here:
        ret
found_tex_vert_list     endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Calculates de normal vectors in the vertices of a polygon
;
; INPUT : EDI -> RENDERPOLY
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
CalcPolyNormals proc
        ; (Nx,Ny,Nz) = (Ay*Bz-By*Az , Az*Bx-Bz*Ax , Ax*By-Bx*Ay)
        ; (Ax,Ay,Az) = (x2-x1 , y2-y1 , z2-z1)
        ; (Bx,By,Bz) = (x3-x1 , y3-y1 , z3-z1)

        ; [st(5),st(4),st(3)] = (Ax,Ay,Az)
        mov     eax,[edi.point1]
        mov     ebx,[edi.point2]
        fld     [ebx.PointPos.x]
        fsub    [eax.PointPos.x]
        fld     [ebx.PointPos.y]
        fsub    [eax.PointPos.y]
        fld     [ebx.PointPos.z]
        fsub    [eax.PointPos.z]

        ; [st(2),st(1),st(0)] = (Bx,By,Bz)
        mov     ebx,[edi.point3]
        fld     [ebx.PointPos.x]
        fsub    [eax.PointPos.x]
        fld     [ebx.PointPos.y]
        fsub    [eax.PointPos.y]
        fld     [ebx.PointPos.z]
        fsub    [eax.PointPos.z]

        ; Nx = Ay*Bz-By*Az
        fld     st(4)           ; Ay
        fmul    st(0),st(1)     ; *Bz
        fld     st(4)           ; Az
        fmul    st(0),st(3)     ; *By
        fsubp                   ; -
        fstp    [edi.PNormal.x] ; Nx

        ; Ny = Az*Bx-Bz*Ax
        fld     st(3)           ; Az
        fmul    st(0),st(3)     ; *Bx
        fld     st(6)           ; Ax
        fmul    st(0),st(2)     ; *Bz
        fsubp                   ; -
        fstp    [edi.PNormal.y] ; Ny

        ; Nz = Ax*By-Bx*Ay
        fld     st(5)           ; Ax
        fmul    st(0),st(2)     ; *By
        fld     st(5)           ; Ay
        fmul    st(0),st(4)     ; *Bx
        fsubp                   ; -
        fstp    [edi.PNormal.z] ; Nz

        fstp    trash
        fstp    trash
        fstp    trash
        fstp    trash
        fstp    trash
        fstp    trash

        ret
CalcPolyNormals endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Tests a 3DS file
;
; INPUT  : EDX -> 3DS file name
;
; OUTPUT : CF = 0 if it was a 3DS file
;          CF = 1 if it was NOT a valid 3DS file
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
Test3DS proc
        mov     al,READ_ONLY
        call    ttl_open
        ErrorCode FILE_OPEN_ERROR
        mov     ebx,eax
        mov     al,SEEK_SET
        xor     edx,edx
        push    ebx
        call    ttl_seek
        pop     ebx
        ErrorCode FILE_SEEK_ERROR
        mov     ecx,2
        mov     edx,offset Signature
        push    ebx
        call    ttl_read
        pop     ebx
        ErrorCode FILE_READ_ERROR
        call    ttl_close
        ErrorCode FILE_CLOSE_ERROR
        cmp     Signature,PRIMARY_CHUNK
        jnz     file_not_correct
        clc
        ret

        file_not_correct:
        stc
        ret
Signature       dw 2 dup(?)
Test3DS endp

INCLUDE loader.inc
INCLUDE stderror.inc

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Reads a 3DS file into memory
;
; INPUT  : EDX -> 3DS file name
;
; OUTPUT : CF = 0 if ok
;               EAX -> RENDERWORLD
;          CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
Read3DS proc
        call    ttl_load_file
        ErrorCode FILE_ERROR
        mov     FilePool,ebx
        mov     FLen,ecx

        ; Look for file objects
        mov     ax,PRIMARY_CHUNK
        mov     esi,ebx
        mov     ebx,offset search_mesh
        mov     OnlyTest,1
        mov     NMeshes,0
        mov     NPolys,0
        mov     NPoints,0
        mov     NMaterials,0
        mov     NCameras,0
        mov     NLights,0
        call    scan_chunk
        ErrorCode INVALID_FORMAT

        mov     eax,NPoints
        mov     TotalPoints,eax
        mov     eax,NPolys
        mov     TotalPolys,eax

        ; Calculate space for objects
        mov     ecx,size RENDERWORLD
        mov     eax,size RENDERMESH
        imul    eax,NMeshes
        add     ecx,eax
        mov     PolyOffset,ecx
        mov     eax,size RENDERPOLY
        imul    eax,NPolys
        add     ecx,eax
        mov     PointOffset,ecx
        mov     eax,size RENDERPOINT
        imul    eax,NPoints
        add     ecx,eax
        mov     MaterialOffset,ecx
        mov     eax,size RENDERMATERIAL
        imul    eax,NMaterials
        add     ecx,eax
        mov     CameraOffset,ecx
        mov     eax,size RENDERCAMERA
        imul    eax,NCameras
        add     ecx,eax
        mov     LightOffset,ecx
        mov     eax,size RENDERLIGHT
        imul    eax,NLights
        add     ecx,eax
        call    malloc
        ErrorCode MALLOC_ERROR
        mov     edi,ebx
        xor     eax,eax
        rep     stosb
        mov     WorldBuffer,ebx
        mov     MeshBuffer,size RENDERWORLD
        add     MeshBuffer,ebx
        add     PolyOffset,ebx
        add     PointOffset,ebx
        add     MaterialOffset,ebx
        add     CameraOffset,ebx
        add     LightOffset,ebx

        mov     OnlyTest,0
        mov     NMeshes,0
        mov     NMaterials,0
        mov     NPolys,0
        mov     NPoints,0
        mov     NCameras,0
        mov     NLights,0
        mov     eax,MeshBuffer
        mov     CurrentMesh,eax
        mov     eax,PolyOffset
        mov     CurrentPoly,eax
        mov     eax,PointOffset
        mov     CurrentPoint,eax
        mov     eax,MaterialOffset
        mov     CurrentMaterial,eax
        mov     eax,CameraOffset
        mov     CurrentCamera,eax
        mov     eax,LightOffset
        mov     CurrentLight,eax

        mov     ax,PRIMARY_CHUNK
        mov     esi,FilePool
        mov     ebx,offset search_mesh
        mov     ecx,FLen
        call    scan_chunk
        ErrorCode INVALID_FORMAT

        mov     ebx,FilePool
        call    free
        ErrorCode FREE_ERROR

        mov     ebx,WorldBuffer
        mov     eax,NMeshes
        mov     [ebx.NumMeshes],eax
        mov     eax,MeshBuffer
        mov     [ebx.MeshArray],eax
        mov     eax,NCameras
        mov     [ebx.NumCameras],eax
        mov     eax,CameraOffset
        mov     [ebx.CameraArray],eax
        mov     eax,LightOffset
        mov     [ebx.LightArray],eax
        mov     eax,NLights
        mov     [ebx.NumLights],eax

        push    ebx

        ; Calculate normals in polygons
        mov     ecx,TotalPolys
        test    ecx,ecx
        jz      no_normals_to_calc
        mov     edi,PolyOffset
        calc_all_normals:
                call    CalcPolyNormals
                add     edi,size RENDERPOLY
        loop    calc_all_normals

        ; Interpolate normals in vertices
        mov     ecx,TotalPoints
        test    ecx,ecx
        jz      no_normals_to_calc
        mov     edi,PointOffset
        interp_point_normals:
                push    edi ecx
                mov     ecx,TotalPolys
                mov     esi,PolyOffset
                xor     ebx,ebx
                search_sided_polys:
                        cmp     [esi.point1],edi
                        jz      found_poly
                        cmp     [esi.point2],edi
                        jz      found_poly
                        cmp     [esi.point3],edi
                        jnz     not_this_one
                        found_poly:
                                fld     [edi.Normal.x]
                                fadd    [esi.PNormal.x]
                                fstp    [edi.Normal.x]
                                fld     [edi.Normal.y]
                                fadd    [esi.PNormal.y]
                                fstp    [edi.Normal.y]
                                fld     [edi.Normal.z]
                                fadd    [esi.PNormal.z]
                                fstp    [edi.Normal.z]
                                inc     ebx
                        not_this_one:
                        add     esi,size RENDERPOLY                        
                loop    search_sided_polys
                ; Arithmetic average
                mov     trash,ebx
                fild    trash
                fld     [edi.Normal.x]
                fdivrp
                fst     [edi.Normal.x]
                fstp    [edi.OrigNormal.x]
                fild    trash
                fld     [edi.Normal.y]
                fdivrp
                fst     [edi.Normal.y]
                fstp    [edi.OrigNormal.y]
                fild    trash
                fld     [edi.Normal.z]
                fdivrp
                fst     [edi.Normal.z]
                fstp    [edi.OrigNormal.z]
                lea     eax,[edi.Normal]
                call    NormalizeVector
                lea     eax,[edi.OrigNormal]
                call    NormalizeVector
                pop     ecx edi
                add     edi,size RENDERPOINT
        loop    interp_point_normals

        no_normals_to_calc:
        pop     eax
        ret

Read3DS endp

;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
; Frees all the memory used by a universe
;
; INPUT  : EAX -> RENDERWORLD
;
; OUTPUT : CF = 0 if success
;               EAX = 0
;          CF = 1 if error
;               EAX = Error code
;컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�
Destroy3DS      proc
        mov     ebx,eax
        call    free
        ret
Destroy3DS      endp

.data
Procs3DS        UniLoadProcs <offset Test3DS,offset Read3DS,offset Destroy3DS>

deb_normal      db " %d-n"
                dd offset trash
                db 0
trash dd ?

.data?
FilePool        dd ?
FLen            dd ?
OnlyTest        db ?

NMeshes         dd ?
NPolys          dd ?
NPoints         dd ?
NMaterials      dd ?
NCameras        dd ?
NLights         dd ?

WorldBuffer     dd ?
MeshBuffer      dd ?
PolyOffset      dd ?
PointOffset     dd ?
MaterialOffset  dd ?
CameraOffset    dd ?
LightOffset     dd ?

CurrentMesh     dd ?
CurrentPoly     dd ?
CurrentPoint    dd ?
CurrentMaterial dd ?
CurrentCamera   dd ?
CurrentLight    dd ?

ObjName         dd ?

TotalPolys      dd ?
TotalPoints     dd ?

end
