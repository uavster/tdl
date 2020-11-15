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

typedef struct
{
        float   x;
		float	y;
		float	z;
} POINT3D;

typedef struct
{
  float X;
  float Y;
  float k[SPAN_MAX_INTERPOLATE_VARS+1];
  POINT3D       PointPos;
  int           PointFlags;
  POINT3D       OrigPointPos;
  POINT3D		OrigNormal;
  POINT3D		Normal;
} RENDERPOINT;

typedef struct
{
  DWORD Type;
  DWORD N;
  RENDERPOINT *P1;
  RENDERPOINT *P2;
  RENDERPOINT *P3;
  SLI *Texture1;
  SLI *Texture2;
  int   PolyFlags;
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
        int             CamFocus;
        // Useful precalculated values
        int             sin_alpha;
		int				cos_alpha;
		int				sin_beta;
		int				cos_beta;
		int				sin_gamma;
		int				cos_gamma;
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
