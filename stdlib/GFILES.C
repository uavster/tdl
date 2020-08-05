/* fitxer: gfiles.c
 *
 *  Rutines de lectura de formats grÖfics. Llegeix els segÅents formats:
 *
 *    - Bitmap de Windows, comprimit i sense comprimir.
 *
 */

#include "ttl.h"

// Definicions de dades

#pragma pack(__push,1);

typedef struct
{
  WORD    bfType;
	DWORD   bfSize;
  WORD    bfReserved1;
  WORD    bfReserved2;
	DWORD   bfOffBits;
} BITMAPFILEHEADER;

typedef struct
{
	DWORD   biSize;
  DWORD   biWidth;
  DWORD   biHeight;
	WORD    biPlanes;
	WORD    biBitCount;
	DWORD   biCompression;
	DWORD   biSizeImage;
  DWORD   biXPelsPerMeter;
  DWORD   biYPelsPerMeter;
	DWORD   biClrUsed;
	DWORD   biClrImportant;
}	BITMAPINFOHEADER;

#pragma pack(__pop);

/*⁄ƒ BYTE *ReadBMP(char *fname, DWORD off, BYTE *pal, int *sx, int *sy) ƒƒø
  ≥                                                                       ≥
  ≥ Descripci¢ : Llegeix un BMP de Windows de 256 colors.                 ≥
  ≥                                                                       ≥
  ≥ Arguments  : fname - nom del fitxer que contÇ el BMP.                 ≥
  ≥              off - offset dins el fitxer a l'inici del BMP.           ≥
  ≥              pal - punter a l'espai per carregar la paleta.           ≥
  ≥              sx, sy - punters tamany del BMP.                         ≥
  ≥                                                                       ≥
  ≥ Retorna    : punter al buffer que contÇ el BMP.                       ≥
  ≥                                                                       ≥
  ¿ƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒƒŸ*/

#define BI_RGB  0L
#define BI_RLE8 1L

BYTE buf[1280];     // Buffer per l°nies de fins a 1280 pixels

BYTE *ReadBMP(char *fname, DWORD off, BYTE *pal, int *sx, int *sy)
{
  DWORD   in;
  BYTE    entry[4], code[2], *bmp;
  int     i, padbytes, x, y;
  BITMAPFILEHEADER bmfh;
  BITMAPINFOHEADER bmih;

  // Obre el fitxer i es posiciona
  if ((in = ttl_open(fname, READ_ONLY)) == NULL)
    return NULL;
  ttl_seek(in, off, SEEK_SET);

  // Llegeix BITMAPFILEHEADER i comprova si Çs un bitmap
  if (ttl_read((BYTE *)&bmfh, sizeof(BITMAPFILEHEADER), in) != sizeof(BITMAPFILEHEADER))
  {
    ttl_close(in);
    return NULL;
  }
  if (bmfh.bfType != (WORD)'MB') // Identificaci¢ BM
	{
    ttl_close(in);
    return NULL;
  }

  // Llegeix BITMAPINFOHEADER
  if (ttl_read((BYTE *)&bmih, sizeof(BITMAPINFOHEADER), in) != sizeof(BITMAPINFOHEADER))
  {
    ttl_close(in);
    return NULL;
  }

/*
  printf("biSize: %u\n", bmih.biSize);
  printf("biWidth: %d\n", bmih.biWidth);
  printf("biHeight: %d\n", bmih.biHeight);
  printf("biPlanes: %u\n", (DWORD)bmih.biPlanes);
  printf("biBitCount: %u\n", (DWORD)bmih.biBitCount);
  printf("biCompression: %u\n", bmih.biCompression);
  printf("biSizeImage: %u\n", bmih.biSizeImage);
  printf("biXPelsPerMeter: %d\n", bmih.biXPelsPerMeter);
  printf("biYPelsPerMeter: %d\n", bmih.biYPelsPerMeter);
  printf("biClrUsed: %u\n", bmih.biClrUsed);
  printf("biClrImportant: %u\n", bmih.biClrImportant);
  getch();
*/

  // Si no Çs de 256 colors surt
  if (bmih.biBitCount != 8)
  {
    ttl_close(in);
    return NULL;
  }

  // Llegeix la paleta
  for (i = 0; i < 256; i++)
  {
    if (ttl_read(entry, 4, in) != 4)
    {
      ttl_close(in);
      return NULL;
    }
    pal[i * 3]      = entry[2] >> 2;
    pal[i * 3 + 1]  = entry[1] >> 2;
    pal[i * 3 + 2]  = entry[0] >> 2;
  }

  // Reserva buffer i neteja buffer
  if ((bmp = (BYTE *)malloc(bmih.biWidth * bmih.biHeight)) == NULL)
  {
    ttl_close(in);
    return NULL;
  }
  memset(bmp, 0, bmih.biWidth * bmih.biHeight);

  // Decodifica la imatge
  switch(bmih.biCompression)
  {
    case BI_RGB:      // Bitmap no comprimit

      // Calcula la mida d'una l°nia, que ha d'estar alineada a 32-bits
      padbytes = (4 - (bmih.biWidth & 3)) & 3;

      // Llegeix la imatge
      for (i = bmih.biHeight - 1; i >= 0; i--)
      {
        if (ttl_read(&bmp[bmih.biWidth * i], bmih.biWidth, in) != bmih.biWidth)
        {
          free(bmp);
          ttl_close(in);
          return NULL;
        }

        // Es salta els bytes que sobren
        if (padbytes)
          ttl_seek(in, padbytes, SEEK_CUR);

      }
      break;

    case BI_RLE8:     // Bitmap comprimit RLE

      // Llegeix la imatge
      for (y = bmih.biHeight - 1; y >= 0; )
      {
        // Llegeix parelles de codis
        if (ttl_read(code, 2, in) != 2)
        {
          free(bmp);
          ttl_close(in);
          return NULL;
        }

        // Comprova si Çs una repetici¢ o un escape
        if (code[0])
        {
          memset(&bmp[y * bmih.biWidth + x], code[1], code[0]);
          x += code[0];
        }
        else
          switch (code[1])
          {
            case 0:     // End of line
              x = 0;
              y--;
              break;

            case 1:     // End of bitmap
              y = -1;
              break;

            case 2:     // Delta
              if (ttl_read(code, 2, in) != 2)
              {
                free(bmp);
                ttl_close(in);
                return NULL;
              }
              x += code[0];   // delta-x
              y += code[1];   // delta-y
              break;

            default:    // Absolute mode (code[1] bytes "literals", word-align)
              if (ttl_read(buf, (code[1] + 1) & ~1, in) != (code[1] + 1) & ~1)
              {
                free(bmp);
                ttl_close(in);
                return NULL;
              }
              memcpy(&bmp[y * bmih.biWidth + x], buf, code[1]);
              x += code[1];
          }
      }
      break;

    default:

      ttl_close(in);
      return NULL;
  }

  // Tanca el fitxer
  ttl_close(in);

  // Retorna informaci¢
  if (sx != NULL)
    *sx = bmih.biWidth;
  if (sy != NULL)
    *sy = bmih.biHeight;
  return bmp;
}

