/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   Include file for 3D universe loading and rendering functions
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _3D_INCLUDED_
#define _3D_INCLUDED_

#include <stddef.h>
#include <sli.h>
#include <sbuffer.def>

#ifdef __cplusplus
  extern "C" {
#endif

#define kBackFaceCulled		1
#define kFrontFaceCulled	2
#define kVertex1HasProps	4
#define kVertex2HasProps	8
#define kVertex3HasProps	16

typedef struct
{
	float x;
	float y;
} POINT2D;

typedef struct
{	
	float x;
	float y;
	float z;
} POINT3D;

typedef struct {
	POINT2D TextureCoordinates;		// (u, v) in the texture
	float Light1;		            // If Goraud, this is the light intensity; if pseudo-Phong, it's the u coordinate in the light map
	float Light2;					// If pseudo-Phong, this is the v coordinate in the light map
} RENDERVERTEXPROPERTIES;

typedef struct
{
	POINT2D ImageProjection;
	float InverseZ;
	RENDERVERTEXPROPERTIES Properties;
	POINT3D PointPos;
	int PointFlags;
	POINT3D OrigPointPos;
	POINT3D OrigNormal;
	POINT3D Normal;
} RENDERPOINT;

typedef struct
{
	DWORD Type;
	DWORD N;
	RENDERPOINT *P1;
	RENDERPOINT *P2;
	RENDERPOINT *P3;
	RENDERVERTEXPROPERTIES Vertex1Props;
	RENDERVERTEXPROPERTIES Vertex2Props;
	RENDERVERTEXPROPERTIES Vertex3Props;
	SLI *Texture1;
	SLI *Texture2;
	int PolyFlags;
	POINT3D PNormal;
} RENDERPOLY;

typedef struct
{
        int             polygons;
        RENDERPOLY      *polydata;
        int             points;
        RENDERPOINT     *pointdata;
        POINT3D         Pivot;
        char            MeshName[128];
} RENDERMESH;

typedef struct
{
        POINT3D         CamPos;
		POINT3D			CamOrientation;
        float           CamFocus;
        // Useful precalculated values
        float           sin_alpha;
		float			cos_alpha;
		float			sin_beta;
		float			cos_beta;
		float			sin_gamma;
		float			cos_gamma;
        // The useful name
        char            CamName[128];
} RENDERCAMERA;

typedef struct
{
        SLI             *MatSLI;
        char            MatName[128];
} RENDERMATERIAL;

typedef struct
{
        POINT3D         LightPos;
		POINT3D			LightVector;
        int             LightIntensity;
        char            LightName[128];
} RENDERLIGHT;

typedef struct
{
        int             NumMeshes;
        RENDERMESH      *MeshArray;
        int             NumCameras;
        RENDERCAMERA     *CameraArray;
        int             NumLights;
        RENDERLIGHT     *LightArray;

        void            *WorldDestructor;
} RENDERWORLD;

void NormalizeVector(POINT3D *v);
#pragma aux NormalizeVector "*" parm   [eax] \
                             modify [eax ebx ecx edx esi edi ebp];

#ifdef __cplusplus
  };
#endif

#include <uniload.h>
#include <render.h>

#endif
