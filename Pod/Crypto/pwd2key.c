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
 *
 * This is an implementation of RFC2898, which specifies key derivation from
 * a password and a salt value.
 */

#include <memory.h>
#include "pwd2key.h"

/**
 *
 */
int deriveKey(BufferT* pwd,BufferT* salt,BufferT* key,unsigned int iter)
{
  if( pwd==NULL       || salt==NULL       || key==NULL       ||
      pwd->data==NULL || salt->data==NULL || key->data==NULL
    )
    return DERIVEKEY_FAILURE;
  
  unsigned int    i, j, k, n_blk;
  unsigned char   uu[HASH_OUTPUT_SIZE], ux[HASH_OUTPUT_SIZE];
  HMACContextT    c1[1], c2[1], c3[1];

  /* set HMAC context (c1) for password               */
  SUCCESS( hmac_sha_begin(c1)   );
  SUCCESS( hmac_sha_key(c1,pwd) );

  /* set HMAC context (c2) for password and salt      */
  memcpy(c2, c1, sizeof(HMACContextT));
  SUCCESS( hmac_sha_data(c2,salt) ) ;

  /* find the number of SHA blocks in the key         */
  n_blk = 1 + (key->length - 1) / HASH_OUTPUT_SIZE;

  /* for each block in key */
  for(i = 0; i < n_blk; ++i) 
  {
    /* ux[] holds the running xor value             */
    memset(ux, 0, HASH_OUTPUT_SIZE);

    /* set HMAC context (c3) for password and salt  */
    memcpy(c3, c2, sizeof(HMACContextT));

    /* enter additional data for 1st block into uu  */
    uu[0] = (unsigned char)((i + 1) >> 24);
    uu[1] = (unsigned char)((i + 1) >> 16);
    uu[2] = (unsigned char)((i + 1) >> 8);
    uu[3] = (unsigned char)(i + 1);
    
    /* this is the key mixing iteration         */
    for(j = 0, k = 4; j < iter; ++j)
    { BufferT x;
      
      buffer_init(&x,k,uu);
      
      /* add previous round data to HMAC      */
      SUCCESS( hmac_sha_data(c3,&x) );
      
      buffer_init(&x,HASH_OUTPUT_SIZE,uu);

      /* obtain HMAC for uu[]                 */
      SUCCESS( hmac_sha_end(c3,&x) );

      /* xor into the running xor block       */
      for(k = 0; k < HASH_OUTPUT_SIZE; ++k)
        ux[k] ^= uu[k];

      /* set HMAC context (c3) for password   */
      memcpy(c3, c1, sizeof(HMACContextT));
    } // of for

    /* compile key blocks into the key output   */
    j = 0; k = i * HASH_OUTPUT_SIZE;
    while(j < HASH_OUTPUT_SIZE && k < key->length)
      key->data[k++] = ux[j++];
  } // of for
  
  return DERIVEKEY_OK;
} // of deriveKey()
/*========================================================END-OF-FILE========================================================*/

