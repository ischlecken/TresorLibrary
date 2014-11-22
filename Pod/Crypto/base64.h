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

#ifndef BASE64_H
#define BASE64_H

#include "buffer.h"

#define BASE64_OK         0
#define BASE64_FAILURE   -1


typedef enum
{ step_A, step_B, step_C
} base64_encodestep;

typedef struct
{	base64_encodestep step;
	char              result;
	int               stepcount;
  int               charsPerLine;
} base64_encodestate;

void base64_encode_begin (base64_encodestate* ctx,int charsPerLine);
int  base64_encode_data  (base64_encodestate* ctx,BufferT* plainIn,char* code_out);
int  base64_encode_end   (base64_encodestate* ctx,char* code_out);
int  base64_encode_length(int plainInLength,int charsPerLine);

typedef enum
{	step_a, step_b, step_c, step_d
} base64_decodestep;

typedef struct
{	base64_decodestep step;
	char              plainchar;  
  int               charsPerLine;
} base64_decodestate;

void base64_decode_begin (base64_decodestate* ctx,int charsPerLine); 
int  base64_decode_data  (base64_decodestate* ctx,BufferT* codeIn,char* plaintext_out);
void base64_decode_end   (base64_decodestate* ctx,char* plaintext_out); 
int  base64_decode_length(int codeInLength,int charsPerLine);
#endif /* BASE64_H */
/*============================================================================END-OF-FILE============================================================================*/
