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
#include <string.h>
#include <stdio.h>
#include "buffer.h"
#include "base64.h"

#include <Security/SecRandom.h>

/**
 *
 */
void buffer_init(BufferT* buffer,unsigned int length,unsigned char* data)
{ if( buffer!=NULL )
  { memset(buffer,0xFE,sizeof(BufferT));
    
    buffer->length = length;
    buffer->data   = data;
    buffer->magic1 = 0xADADADAD;
  } // of if
} /* of buffer_init() */

/**
 *
 */
BufferT* buffer_alloc(unsigned int length,unsigned char* data)
{ Buffer1T* result = malloc(sizeof(BufferT)+length);
  
  if( result!=NULL )
  { memset(result,0xFC,sizeof(BufferT)+length);
    
    result->length = length;
    result->data   = result->buffer;
    
    if( data!=NULL && data!=BUFFER_RANDOM )
      memcpy(result->buffer,data,length);
    else if( data==BUFFER_RANDOM )
    {
      if( SecRandomCopyBytes(kSecRandomDefault,result->length,result->data)!=0 )
      { 
        for( int i=0;i<length;i++ )
          result->data[i] = (unsigned char)(arc4random() & 0xFF);
      } /* of if */
    } /* of else if */
    
    void* magic1Adr = (void*)result+sizeof(BufferT)+length-sizeof(unsigned char*);
    
    memset(magic1Adr,0xAD,4);
  } // of if
  
  return (BufferT*)result;
} /* of buffer_alloc() */



/**
 *
 */
static int buffer_check1(Buffer1T* buffer)
{ int result = BUFFER_OK;
  
  if( buffer!=NULL )
  { void* magic1Adr = ((unsigned char*)buffer) + sizeof(BufferT) + buffer->length - sizeof( unsigned char* );
    
    unsigned int magic1Value = *((unsigned int*)magic1Adr) & 0xFFFFFFFF;
    
    if( buffer->magic0!=0xFCFCFCFC || magic1Value!=0xADADADAD )
      result = BUFFER_CORRUPTED;
  } // of if
  
  return result;
}

/**
 *
 */
int buffer_check(BufferT* buffer)
{ int result = BUFFER_OK;
  
  if( buffer!=NULL )
  { if( buffer->magic0==0xFCFCFCFC )
      result = buffer_check1((Buffer1T*)buffer);
    else if( buffer->magic0!=0xFEFEFEFE || buffer->magic1!=0xADADADAD )
      result = BUFFER_CORRUPTED;
  } // of if
     
  return result;
}


/**
 *
 */
int buffer_binary2hexstr(BufferT* in,BufferT* out)
{ if( in==NULL || out==NULL || out->length<in->length*2+1 )
    return BUFFER_FAILURE;
  
  for( int i=0;i<in->length;i++ )
    sprintf((char*)(out->data + i * 2), "%02x",in->data[i]);
  
  return BUFFER_OK;
} /* of buffer_binary2hexstr() */

/**
 *
 */
int buffer_hexstr2binary(BufferT* in,BufferT* out)
{ if( in==NULL || out==NULL || out->length<in->length/2 )
    return BUFFER_FAILURE;
  
  unsigned char digit[3];
  
  memset(digit,0,3);
  
  for( int i=0;i<in->length/2;i++ )
  { digit[0]     = in->data[2*i];
    digit[1]     = in->data[2*i+1];
   
    out->data[i] = (unsigned char)strtol((char*)digit, NULL, 16);
  } /* of for */
  
  return BUFFER_OK;
} /* of buffer_hexstr2binary() */

/**
 *
 */
int buffer_binary2base64(BufferT* in,BufferT* out)
{ if( in==NULL || out==NULL || (in->length>0 && out->length<base64_encode_length(in->length,0)) )
    return BUFFER_FAILURE;
  
  if( in->length>0 )
  { base64_encodestate ctx[1];
    
    base64_encode_begin(ctx,0);
    
    int encodedBytes = base64_encode_data (ctx, in, (char*)out->data);
    
    base64_encode_end(ctx, (char*)out->data+encodedBytes);
  } /* of if */
  
  return BUFFER_OK;
} /* of buffer_binary2base64() */

/**
 *
 */
int buffer_base642binary(BufferT* in,BufferT* out)
{ if( in==NULL || out==NULL || (in->length>0 && out->length<base64_decode_length(in->length,0)) )
    return BUFFER_FAILURE;
  
  if( in->length>0 )
  { base64_decodestate ctx[1];
    
    base64_decode_begin(ctx,0);
    base64_decode_data (ctx, in, (char*)out->data);
    base64_decode_end  (ctx, (char*)out->data);
  } /* of if */
  
  return BUFFER_OK;
} /* of buffer_base642binary() */
/*============================================================================END-OF-FILE============================================================================*/
