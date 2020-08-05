#ifdef __cplusplus
  extern "C" {
#endif

// Render methodes
#define RENDER_LINE  0
#define RENDER_SOLID 1

// Object types for searches
#define MESH_TYPE   0
#define CAMERA_TYPE 1
#define LIGHT_TYPE  2

// Face culling types
#define BACK_FACE_CULLED    1
#define FRONT_FACE_CULLED   2

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Renders the 3D world 
;
; INPUT : EAX -> RENDERWORLD structure
;         EBX -> Destination SLI
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void RenderUniverse(RENDERWORLD *,SLI *);
#pragma aux RenderUniverse "*" parm   [eax] [ebx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets a pointer to default camera
;
; OUTPUT : EAX -> RENDERCAMERA structure of default camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
RENDERCAMERA *GetActiveCamera();
#pragma aux GetActiveCamera "*" modify [eax ebx ecx edx esi edi ebp] \
                                value  [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the current active camera
;
; INPUT : EAX -> RENDERCAMERA
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetActiveCamera(RENDERCAMERA *);
#pragma aux SetActiveCamera "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp] \

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the pointer to an object into the world with the given name
;
; INPUT  : EAX -> Mesh name
;          EBX -> RENDERWORLD
;          ECX = Object type
;
; OUTPUT : CF = 0 if ok
;               EAX -> World object
;          CF = 1 if object not found
;               EAX = NULL
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void *GetObjectByName(char *,RENDERWORLD *,int);
#pragma aux GetObjectByName "*" parm   [eax] [ebx] [ecx] \
                             modify [eax ebx ecx edx esi edi ebp] \
                             value  [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the position of the camera from the world reference system
;
; INTPUT -> EAX = float X
;           EBX = float Y
;           ECX = float Z
;           EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetCameraPos(float,float,float,RENDERCAMERA *);
#pragma aux SetCameraPos "*" parm   [eax] [ebx] [ecx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the orientation of the camera from the world reference system
;
; INPUT : EAX = float ALPHA
;         EBX = float BETA
;         EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetCameraOrientation(float,float,RENDERCAMERA *);
#pragma aux SetCamerOrientation "*" parm   [eax] [ebx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Gets the orientation of the camera from the world reference system
;
; INPUT :  EAX -> RENDERCAMERA or NULL if Current Camera
;
; OUTPUT : EAX = float ALPHA
;          EBX = float BETA
;          ECX = float GAMMA
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Points the camera to a target point
;
; INPUT : EAX = float target X
;         EBX = float target Y
;         ECX = float target Z
;         EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetCameraTarget(float,float,float,RENDERCAMERA *);
#pragma aux SetCameraTarget "*" parm   [eax] [ebx] [ecx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a light position
;
; INPUT : EAX = Float X
;         EBX = Float Y
;         ECX = Float Z
;         EDX -> RENDERLIGHT
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetLightPos(float,float,float,RENDERLIGHT *);
#pragma aux SetLightPos "*" parm   [eax] [ebx] [ecx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a light target vector
;
; INPUT : EAX = Float target X
;         EBX = Float target Y
;         ECX = Float target Z
;         EDX -> RENDERLIGHT
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetLightTarget(float,float,float,RENDERLIGHT *);
#pragma aux SetLightTarget "*" parm   [eax] [ebx] [ecx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the color of the Lined Render in B:G:R:0 format
;
; INPUT : EAX = Color in B:G:R:0 format
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetLinedRenderColor(int);
#pragma aux SetVideoMode "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Rotates a RENDERMESH
;
; INPUT : EAX = Float ALPHA
;         EBX = Float BETA
;         EDX -> RENDERMESH structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void RotateMesh(float,float,RENDERMESH *);
#pragma aux RotateMesh "*" parm   [eax] [ebx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Moves a mesh pivot
;
; INPUT : EAX = Float X
;         EBX = Float Y
;         ECX = Float Z
;         EDX -> RENDERMESH structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void MoveMesh(float,float,float,RENDERMESH *);
#pragma aux MoveMesh "*" parm   [eax] [ebx] [ecx] [edx] \
                             modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the current render methode
;
; INPUT : EAX = Render methode
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetRenderMethode(int);
#pragma aux SetRenderMethode "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
  };
#endif

