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

#include <stdlib.h>
#include "base64.h"


/**
 *
 */
static char base64_encode_value(char value_in)
{ static const char* encoding = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  
	if (value_in > 63) 
    return '=';
	
  return encoding[(int)value_in];
} /* of base64_encode_value() */

/**
 *
 */
void base64_encode_begin(base64_encodestate* ctx,int charsPerLine)
{ ctx->step         = step_A;
	ctx->result       = 0;
	ctx->stepcount    = 0;
  ctx->charsPerLine = charsPerLine;
} /* of base64_encode_begin() */

/**
 *
 */
int base64_encode_length(int plainInLength,int charsPerLine)
{ int n      = plainInLength;
  int l      = (n + 2 - ((n+2) % 3) ) / 3 * 4;
  int result = l;
  
  if( charsPerLine>0 )
    result += l/charsPerLine;
  
  return result;
} /* of base64_encode_length() */


/**
 *
 */
int base64_encode_data(base64_encodestate* ctx,BufferT* plainIn, char* code_out)
{	const char*       plainchar    = (char*)plainIn->data;
	const char* const plaintextend = plainchar + plainIn->length;
  char*             codechar     = code_out;
	char              result       = ctx->result;
	char              fragment;
	
	switch (ctx->step)
	{
		while (1)
		{
      case step_A:
        if (plainchar == plaintextend)
        { ctx->result = result;
          ctx->step   = step_A;
          
          return (int)(codechar - code_out);
        } /* of if */
    
        fragment    = *plainchar++;
        result      = (fragment & 0x0fc) >> 2;
        *codechar++ = base64_encode_value(result);
        result      = (fragment & 0x003) << 4;
      case step_B:
        if (plainchar == plaintextend)
        { ctx->result = result;
          ctx->step   = step_B;
          
          return (int)(codechar - code_out);
        } /* of if */
    
        fragment     = *plainchar++;
        result      |= (fragment & 0x0f0) >> 4;
        *codechar++  = base64_encode_value(result);
        result       = (fragment & 0x00f) << 2;
      case step_C:
        if (plainchar == plaintextend)
        { ctx->result = result;
          ctx->step   = step_C;
          
          return (int)(codechar - code_out);
        } /* of if */
    
        fragment     = *plainchar++;
        result      |= (fragment & 0x0c0) >> 6;
        *codechar++  = base64_encode_value(result);
        result       = (fragment & 0x03f) >> 0;
        *codechar++  = base64_encode_value(result);
        
        ++(ctx->stepcount);
        if( ctx->charsPerLine>0 && ctx->stepcount == ctx->charsPerLine/4 )
        { *codechar++    = '\n';
          ctx->stepcount = 0;
        } /* of if */
		} /* of while(1) */
	} /* of switch */
  
	/* control should not reach here */
	return BASE64_FAILURE;
} /* of base64_encode_data() */

/**
 *
 */
int base64_encode_end(base64_encodestate* ctx,char* code_out)
{	char* codechar = code_out;
	
	switch (ctx->step)
	{ case step_B:
      *codechar++ = base64_encode_value(ctx->result);
      *codechar++ = '=';
      *codechar++ = '=';
      break;
    case step_C:
      *codechar++ = base64_encode_value(ctx->result);
      *codechar++ = '=';
      break;
    case step_A:
      break;
	} /* of switch */
  
	//*codechar++ = '\n';
	
	return (int)(codechar - code_out);
} /* of base64_encode_end() */

/**
 *
 */
static int base64_decode_value(char value_in)
{ static const char decoding[]    = 
  {62,-1,-1,-1,63,52,53,54,55,56,57,58,59,60,61,-1,
   -1,-1,-2,-1,-1,-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,
   10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,
   -1,-1,-1,-1,-1,-1,26,27,28,29,30,31,32,33,34,35,
   36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51
  };
	
  static const char decoding_size = sizeof(decoding);
	
  value_in -= 43;
	
  if (value_in < 0 || value_in > decoding_size) 
    return -1;
  
	return decoding[(int)value_in];
} /* of base64_decode_value() */

/**
 *
 */
void base64_decode_begin(base64_decodestate* ctx,int charsPerLine)
{ ctx->step         = step_a;
	ctx->plainchar    = 0;
  ctx->charsPerLine = charsPerLine;
} /* of base64_decode_begin() */

/**
 *
 */
int base64_decode_data(base64_decodestate* ctx,BufferT* codeIn,char* plaintext_out)
{ const char* codechar      = (char*)codeIn->data;
  const char* codecharend   = (char*)codeIn->data + codeIn->length;
  char*       plainchar     = plaintext_out;
	char        fragment;
	
	*plainchar = ctx->plainchar;
	
	switch (ctx->step)
	{
    while (1)
    {
      case step_a:
        do 
        { if (codechar == codecharend)
          { ctx->step      = step_a;
            ctx->plainchar = *plainchar;
            
            return (int)(plainchar - plaintext_out);
          } /* of if */
          
          fragment = (char)base64_decode_value(*codechar++);
        } while (fragment < 0);
        
        *plainchar    = (fragment & 0x03f) << 2;
      case step_b:
        do 
        { if (codechar == codecharend)
          { ctx->step      = step_b;
            ctx->plainchar = *plainchar;
            
            return (int)(plainchar - plaintext_out);
          } /* of if */
          
          fragment = (char)base64_decode_value(*codechar++);
        } while (fragment < 0);
        
        *plainchar++ |= (fragment & 0x030) >> 4;
        *plainchar    = (fragment & 0x00f) << 4;
      case step_c:
        do 
        { if (codechar == codecharend)
          { ctx->step      = step_c;
            ctx->plainchar = *plainchar;
            
            return (int)(plainchar - plaintext_out);
          } /* of if */
          
          fragment = (char)base64_decode_value(*codechar++);
        } while (fragment < 0);
        
        *plainchar++ |= (fragment & 0x03c) >> 2;
        *plainchar    = (fragment & 0x003) << 6;
      case step_d:
        do 
        { if (codechar == codecharend)
          { ctx->step      = step_d;
            ctx->plainchar = *plainchar;
            
            return (int)(plainchar - plaintext_out);
          } /* of if */
          
          fragment = (char)base64_decode_value(*codechar++);
        } while (fragment < 0);
        
        *plainchar++   |= (fragment & 0x03f);
    } /* of while(1) */
	} /* of switch */
  
	/* control should not reach here */
	return BASE64_FAILURE;
} /* of base64_decode_data() */

/**
 *
 */
void base64_decode_end  (base64_decodestate* ctx,char* plaintext_out)
{
  
} /* of base64_decode_end() */

/**
 *
 */
int base64_decode_length(int codeInLength,int charsPerLine)
{ int codeLength = codeInLength;
  
  if( charsPerLine>0 )
    codeLength -= codeInLength/charsPerLine;
  
  int result     = codeLength*3/4;
  
  return result;
} /* of base64_decode_length() */
/*============================================================================END-OF-FILE============================================================================*/

