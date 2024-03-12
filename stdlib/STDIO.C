/* ������������������������������������������������������������
   Standard input/output functions for C language
   ������������������������������������������������������������ */

#include "c:\twcc\h\stdarg.h"

#include <string.h>
#include <stddef.h>

#define MAX_STRING_LENGTH 256

void PrintFormatted(char *);
#pragma aux PrintFormatted "*" parm [esi]\
                               modify [eax ebx ecx edx esi edi ebp 8087];
							  
void FormatString(char *, const char *);
#pragma aux FormatString "*" parm [edi] [esi]\
                             modify [eax ebx ecx edx esi edi ebp 8087];	

void prepare_args(va_list la, const char *cadena, char *tmpstr) {
        DWORD   i,j,len;
        int     psize;
        i=0;
        j=0;
        len=strlen(cadena);
        while(i<len && i<MAX_STRING_LENGTH)
        {
                if (cadena[i]=='%' && cadena[i+1]!='%')
                {
                        psize=4;
                        while(cadena[i]!='n' && cadena[i]!='\n' && cadena[i]!='\0' && cadena[i]!='s' && cadena[i]!='S' && i<len && i<MAX_STRING_LENGTH)
                        {
                                tmpstr[j]=cadena[i];
                                if (cadena[i]=='f' || cadena[i]=='F') psize=8;
                                i++;
                                j++;
                        }
                        tmpstr[j]=cadena[i];
                        tmpstr[j+1]=(char)la[0];
                        tmpstr[j+2]=(char)((DWORD)la[0] >> 8);
                        tmpstr[j+3]=(char)((DWORD)la[0] >> 16);
                        tmpstr[j+4]=(char)((DWORD)la[0] >> 24);
                        j+=5;
                        i++;
                        switch(psize) {
                                case 4: va_arg(la,DWORD);
                                        break;
                                case 8: va_arg(la,QWORD);
                                        break;
                        }
                }
                else
                {
						if (cadena[i] == '\n') {
							tmpstr[j] = '\r';
							tmpstr[++j] = '\n';
							i++;
							j++;
						} else {
							tmpstr[j]=cadena[i];
							i++;
							j++;
						}
                }
        }
        tmpstr[j]='\0';
}

void printf(const char *cadena, ...) {
    va_list la;
    char    tmpstr[MAX_STRING_LENGTH];

    va_start(la,cadena);
    prepare_args(la, cadena, tmpstr);
    va_end(la);
    PrintFormatted(tmpstr);
}

int sprintf(const char *str, const char *format, ...) {
    va_list la;
    char    tmp_format[MAX_STRING_LENGTH];

    va_start(la, format);
    prepare_args(la, format, tmp_format);
    va_end(la);
    FormatString(str, tmp_format);
    return strlen(str);
}
