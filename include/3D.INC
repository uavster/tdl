;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Type definitions for 3d stuff
;       by Ignacio Mellado Bataller (a.k.a. B52 / the DarkRising)
;
; NOTE: Structures defined are compatible with 3D.H
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ

        INCLUDE euclides.inc

RENDERVERTEXPROPERTIES	STRUC
        TextPos         POINT2D <>		; (u, v) in the texture
        Light1          dd ?            ; If Goraud, this is the light intensity; if pseudo-Phong, it's the u coordinate in the light map
        Light2          dd ?            ; If pseudo-Phong, this is the v coordinate in the light map
ENDS
		
RENDERPOINT     STRUC
        ScreenPos       POINT2D <>      ; Transformed coords.
        InverseZ        dd ?            ; SBuffer data
		Properties		RENDERVERTEXPROPERTIES <>
        PointPos        POINT3D <>
        PointFlags      dd ?            ; bit 0: behind camera plane

        OrigPointPos    POINT3D <>      ; Original point position

        ; Useful internal data
        OrigNormal      POINT3D <>      ; Original normal
        Normal          POINT3D <>      ; Interpolated normal of vertex
ENDS

BACK_FACE_CULLED        EQU 1
FRONT_FACE_CULLED       EQU 2
VERTEX1_HAS_PROPS		EQU 4
VERTEX2_HAS_PROPS		EQU 8
VERTEX3_HAS_PROPS		EQU 16

RENDERPOLY      STRUC
        PolyType        dd ?    ; SBuffer data
        N               dd ?    ; SBuffer data
        point1          dd ?    ; Pointers to vertex RENDERPOINTs
        point2          dd ?
        point3          dd ?
		vertex1_props	RENDERVERTEXPROPERTIES <>
		vertex2_props	RENDERVERTEXPROPERTIES <>
		vertex3_props	RENDERVERTEXPROPERTIES <>
        texture1        dd ?    ; -> 256x256 texture SLI
        texture2        dd ?    ; -> Phong and light texture
        PolyFlags       dd ?
        ; Useful internal data
		OrigPNormal		POINT3D <>		; Original polygon normal
        PNormal         POINT3D <>      ; Polygon normal vector
ENDS

RENDERMESH      STRUC
        polygons        dd ?    ; Number of polys in mesh
        polydata        dd ?    ; -> array of RENDERPOLYs
        points          dd ?    ; Number of points in mesh
        pointdata       dd ?    ; -> array of renderpoints
        Pivot           POINT3D <>
        ; mmmm grgrgr... heh!
        MeshName        db 128 dup(?)   ; mmhhhh hehhh...
ENDS

RENDERCAMERA    STRUC
        CamPos          POINT3D <>
        CamOrientation  POINT3D <>      ; x,y,z are angles from universal Ref.S
        CamFocus        dd ?
        ; Useful precalculated values
        sin_alpha       dd ?
        cos_alpha       dd ?
        sin_beta        dd ?
        cos_beta        dd ?
        sin_gamma       dd ?
        cos_gamma       dd ?
        ; The useful name
        CamName         db 128 dup(?)
ENDS

RENDERMATERIAL  STRUC
        MatSLI          dd ?
        MatName         db 128 dup(?)        
ENDS

RENDERLIGHT     STRUC
        LightPos        POINT3D <>
        LightVector     POINT3D <>
        LightIntensity  dd ?    ; Float [0.0 , 1.0]
        LightName       db 128 dup(?)
ENDS

RENDERWORLD     STRUC
        ; Fields MUST be this order!!!
        NumMeshes       dd ?
        MeshArray       dd ?    ; -> array of RENDERMESHES
        NumCameras      dd ?
        CameraArray     dd ?
        NumLights       dd ?
        LightArray      dd ?

        WorldDestructor dd ?    ; Procedure that frees all memory
ENDS

;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Normalizes a 3D vector
;
; INPUT : EAX -> 3D vector
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
global  NormalizeVector : NEAR
