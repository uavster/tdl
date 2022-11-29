/* ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ 
   Include file for 3D universe rendering functions
   ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ */
#ifndef _RENDER_INCLUDED_
#define _RENDER_INCLUDED_

#include <sli.h>

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
;         ECX = float GAMMA
;         EDX -> RENDERCAMERA or NULL if Current Camera
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetCameraOrientation(float alpha, float beta, float gamma, RENDERCAMERA *camera);
#pragma aux SetCamerOrientation "*" parm   [eax] [ebx] [ecx] [edx] \
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
; INPUT : EAX -> RENDERLIGHT
;         st0 = Float X
;         st1 = Float Y
;         st2 = Float Z
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetLightPos(float,float,float,RENDERLIGHT *);
#pragma aux SetLightPos "*" parm   [8087] [8087] [8087] [eax] \
                             modify [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets a light target vector
;
; INPUT : EAX -> RENDERLIGHT
;         st0 = Float target X
;         st1 = Float target Y
;         st2 = Float target Z
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetLightTarget(float,float,float,RENDERLIGHT *);
#pragma aux SetLightTarget "*" parm		[8087] [8087] [8087] [eax] \
										modify [eax];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Sets the color of the Lined Render in B:G:R:0 format
;
; INPUT : EAX = Color in B:G:R:0 format
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void SetLinedRenderColor(int);
#pragma aux SetLinedRenderColor "*" parm   [eax] \
                                    modify [eax ebx ecx edx esi edi ebp];

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Rotates a RENDERMESH
;
; INPUT : ST1 = Float ALPHA
;         ST0 = Float BETA
;         EDX -> RENDERMESH structure
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
void RotateMesh(float, float, RENDERMESH *);
#pragma aux RotateMesh "*" parm   [8087] [8087] [edx] \
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

typedef struct {
	float	x;
	float	y;
} POINT2;

/*
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
; Project point on camera.
;
; INPUT  : EAX -> POINT2D where to store the point projection
; 		   ECX -> RENDERPOINT
;          EDX -> RENDERCAMERA
;
; OUTPUT : EAX -> POINT2D with the point projected on the camera plane
;ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ
*/
const POINT2D *ProjectPointOnCamera(RENDERPOINT *, RENDERCAMERA *, POINT2D *);
#pragma aux ProjectPointOnCamera "*" parm   [ecx] [edx] [eax] \
                             modify [eax ebx ecx edx esi edi ebp 8087] \
							 value [eax];

#ifdef __cplusplus
  };
#endif

#endif
