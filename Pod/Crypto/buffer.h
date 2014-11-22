/*
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/.
 */

#ifndef BUFFER_H
#define BUFFER_H

typedef struct
{ unsigned int   magic0;
  unsigned int   length;
  unsigned char* data;
  unsigned int   magic1;
} BufferT;


typedef struct
{ unsigned int   magic0;
  unsigned int   length;
  unsigned char* data;
  unsigned char  buffer[];
} Buffer1T;

#define BUFFER_OK         0
#define BUFFER_FAILURE   -1
#define BUFFER_CORRUPTED -2

#define BUFFER_RANDOM    ((unsigned char*)0xFFFFFFFF)

#define BUFFER_T(len,varname)          \
struct                                 \
{ unsigned int   magic0;               \
  unsigned int   length;               \
  unsigned char* data;                 \
  unsigned char  buffer[len];          \
  unsigned int   magic1;               \
} varname;                             \
                                       \
memset(&varname,0xFC,sizeof(varname)); \
varname.length = len;                  \
varname.data   = varname.buffer;       \
varname.magic1 = 0xADADADAD

#define BUFFER_STR(varname,str)        \
BufferT varname;                       \
                                       \
buffer_init(&varname,(unsigned int)strlen(str),(unsigned char*)str) 


void      buffer_init(BufferT* buffer,unsigned int length,unsigned char* data);
BufferT*  buffer_alloc(unsigned int length,unsigned char* data);

int       buffer_binary2hexstr(BufferT* in,BufferT* out);
int       buffer_hexstr2binary(BufferT* in,BufferT* out);

int       buffer_binary2base64(BufferT* in,BufferT* out);
int       buffer_base642binary(BufferT* in,BufferT* out);

int       buffer_check(BufferT* buffer);

#endif
/*=============================================END-OF-FILE=============================*/
