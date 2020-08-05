/* fitxer: rpack.c
 *
 *  Per llegir fitxers empaquetats amb l'utilitat PACK.
 *
 */

#include <stdio.h>
#include <string.h>
#include <demolib.h>

ENTRY rpck_files[200];    // Tampoc crec que empaqueti m‚s de 200 fitxers...

/*ÚÄ long GetOffset(char *lib, char *fname, long *len) ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
  ³                                                                          ³
  ³ Descripci¢ : Obt‚ l'offset i longitud del fitxer fname dins lib.         ³
  ³                                                                          ³
  ³ Arguments  : lib - llibreria on buscar.                                  ³
  ³              fname - fitxer a buscar.                                    ³
  ³              len - punter a la variable que rebr… la longitud (o NULL).  ³
  ³                                                                          ³
  ³ Retorna    : offset de fname dins lib.                                   ³
  ³                                                                          ³
  ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ*/

long GetOffset(char *lib, char *fname, long *len)
{
  FILE *hLib;
  long offset, sign, entries;
  int i;

  // Obre el fitxer empaquetat
  if ((hLib = fopen(lib, "rb")) == NULL)
    return -1;

  // Comprova si t‚ un fitxer empaquetat afegit
  fseek(hLib, -4, SEEK_END);
  if (fread(&sign, 1, 4, hLib) != 4)
  {
    fclose(hLib);
    return -1;
  }
  if (sign != *(long *)"TPCK")
  {
    fclose(hLib);
    return -1;
  }

  // Llegeix l'offset a la taula d'entrades i la llegeix
  fseek(hLib, -8, SEEK_END);
  if (fread(&offset, 1, 4, hLib) != 4)
  {
    fclose(hLib);
    return -1;
  }
  fseek(hLib, offset, SEEK_SET);
  if (fread(&entries, 1, 4, hLib) != 4)
  {
    fclose(hLib);
    return -1;
  }
  if (fread(rpck_files, sizeof(ENTRY), entries, hLib) != entries)
  {
    fclose(hLib);
    return -1;
  }
  fclose(hLib);

  // Busca el fitxer
  for (i = 0; i < entries && strcmp(rpck_files[i].fname, fname); i++) ;
  if (i == entries)
    return -1;

  // Returna la informaci¢
  if (len != NULL)
    *len = rpck_files[i].len;
  return rpck_files[i].offset;
}

