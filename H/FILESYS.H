/* 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴
   File system include file
   컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴 */

#ifndef _FILESYS_INCLUDED_
#define _FILESYS_INCLUDED_

#ifdef __cplusplus
  extern "C" {
#endif

#define READ_ONLY   0   // Access rights
#define WRITE_ONLY  1
#define READ_WRITE  2

#define SEEK_SET    0   // start of file
#define SEEK_CUR    1   // current file position
#define SEEK_END    2   // end of file

DWORD ttl_open(char *szName, DWORD dwAccess);
#pragma aux ttl_open "*" parm [edx] [eax] \
                         modify [eax] \
                         value [eax];

DWORD ttl_create(char *szName);
#pragma aux ttl_create "*" parm   [edx] \
                           modify [eax] \
                           value  [eax];

void ttl_close(DWORD dwHandle);
#pragma aux ttl_close "*" parm   [ebx] \
                          modify [eax];

DWORD ttl_read(void *pvBuffer, DWORD dwSize, DWORD dwHandle);
#pragma aux ttl_read "*" parm   [edx] [ecx] [ebx] \
                         modify [eax] \
                         value  [eax];

DWORD ttl_write(void *pvBuffer, DWORD dwSize, DWORD dwHandle);
#pragma aux ttl_write "*" parm   [edx] [ecx] [ebx] \
                          modify [eax] \
                          value  [eax];

  // NOTA IMPORTANT: si poses "al" com a parm no va be, fa la convencio de
  //                 pas de par꿲etres com li rota... :(

DWORD ttl_seek(DWORD dwHandle, int dwPos, DWORD bWhence);
#pragma aux ttl_seek "*" parm [ebx] [edx] [eax] \
                         modify [eax] \
                         value  [eax];

#ifdef __cplusplus
  };
#endif

#endif
