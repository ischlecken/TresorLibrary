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

#include "hmac.h"

/* initialise the HMAC context to zero */
int hmac_sha_begin(HMACContextT* cx)
{ if( cx==NULL )
    return HMAC_FAILURE;
  
  memset(cx, 0, sizeof(*cx));
  
  cx->magic0  = 0xE7E7E7E7;
  cx->magic1  = 0xC1C1C1C1;

  return HMAC_OK;
} /* of hmac_sha_begin() */

/* 
 * input the HMAC key (can be called multiple times)    
 */
int hmac_sha_key(HMACContextT* cx,BufferT* key)
{ 
  /* error if further key input   */
  /* is attempted in data mode    */
  if( cx->klen==HMAC_IN_DATA )               
    return HMAC_BAD_MODE;     

  /* if the key has to be hashed  */
  if(cx->klen + key->length > HASH_INPUT_SIZE)    
  {
    /* if the hash has not yet been */
    if(cx->klen <= HASH_INPUT_SIZE)         
    { 
      /* hash stored key characters   */
      SUCCESS( sha_begin(&cx->ctx) );               
      
      BufferT k;
      
      buffer_init(&k, (unsigned int)cx->klen, cx->key);
      
      SUCCESS( sha_hash(&cx->ctx,&k) );
    }

    /* hash long key data into hash */
    SUCCESS( sha_hash(&cx->ctx,key) );       
  }
  else
    /* otherwise store key data     */
    memcpy(cx->key + cx->klen, key->data, key->length);

  /* update the key length count  */
  cx->klen += key->length;                        
  
  return HMAC_OK;
} /* of hmac_sha_key() */

/* 
 * input the HMAC data (can be called multiple times)
 * note that this call terminates the key input phase
 */
int hmac_sha_data(HMACContextT* cx,BufferT* data)
{ unsigned int i;

  /* if not yet in data phase */
  if( cx->klen!=HMAC_IN_DATA )               
  {
    /* if key is being hashed   */
    if(cx->klen > HASH_INPUT_SIZE)          
    { BufferT digest;
      
      buffer_init(&digest,HASH_OUTPUT_SIZE,cx->key);
      
      /* complete the hash and    */
      /* store the result as the  */
      SUCCESS( sha_end(&cx->ctx,(BufferT*)&digest) );
      
      /* key and set new length   */
      cx->klen = HASH_OUTPUT_SIZE;        
    } /* of if */

    /* pad the key if necessary */
    memset(cx->key + cx->klen, 0, HASH_INPUT_SIZE - cx->klen);

    /* xor ipad into key value  */
    for(i = 0; i < (HASH_INPUT_SIZE >> 2); ++i)
      ((uint_32t*)cx->key)[i] ^= 0x36363636;

    /* and start hash operation */
    SUCCESS( sha_begin(&cx->ctx) );
    
    BufferT k;
    buffer_init(&k, HASH_INPUT_SIZE, cx->key);
    SUCCESS( sha_hash(&cx->ctx,&k) );

    /* mark as now in data mode */
    cx->klen = HMAC_IN_DATA;
  } /* of if */

  /* hash the data (if any)       */
  if( data!=NULL )
    SUCCESS( sha_hash(&cx->ctx,data) );
  
  return HMAC_OK;
} /* of hmac_sha_data() */

/* 
 * compute and output the MAC value 
 */
int hmac_sha_end(HMACContextT* cx,BufferT* out)
{ unsigned int  i;

  /* if no data has been entered perform a null data phase        */
  if( cx->klen!=HMAC_IN_DATA )
    hmac_sha_data(cx,NULL);

  BUFFER_T(HASH_OUTPUT_SIZE,dig);
  
  /* complete the inner hash       */
  sha_end(&cx->ctx,(BufferT*)&dig);         
  
  /* set outer key value using opad and removing ipad */
  for( i=0;i<(HASH_INPUT_SIZE>>2);++i )
    ((uint_32t*)cx->key)[i] ^= 0x36363636 ^ 0x5c5c5c5c;

  /* perform the outer hash operation */
  SUCCESS(sha_begin(&cx->ctx) );
  
  BufferT b;
  
  buffer_init(&b, HASH_INPUT_SIZE, cx->key);
  SUCCESS( sha_hash(&cx->ctx,&b) );
  SUCCESS( sha_hash(&cx->ctx,(BufferT*)&dig) );
  SUCCESS( sha_end(&cx->ctx,out) );
  
  return HMAC_OK;
} /* of hmac_sha_end() */
/*========================================================END-OF-FILE========================================================*/





