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
 */
#ifndef _SHA2_H
#define _SHA2_H

#include <stdlib.h>
#include "crypto.h"
#include "buffer.h"


/* Note that the following function prototypes are the same */
/* for both the bit and byte oriented implementations.  But */
/* the length fields are in bytes or bits as is appropriate */
/* for the version used.  Bit sequences are arrays of bytes */
/* in which bit sequence indexes increase from the most to  */
/* the least significant end of each byte                   */

#define SHA224_DIGEST_SIZE  28
#define SHA224_BLOCK_SIZE   64
#define SHA256_DIGEST_SIZE  32
#define SHA256_BLOCK_SIZE   64

/* type to hold the SHA256 (and SHA224) context */

typedef struct
{ uint_32t magic0;
  
  uint_32t count[2];
  uint_32t hash[8];
  uint_32t wbuf[16];
  
  uint_32t magic1;
} SHA256ContextT;

typedef SHA256ContextT  SHA224ContextT;

int  sha224_begin(SHA224ContextT ctx[1]);
#define sha224_hash sha256_hash
int  sha224_end(SHA224ContextT ctx[1],BufferT* digest);

int  sha256_begin(SHA256ContextT ctx[1]);
int  sha256_hash(SHA256ContextT ctx[1],BufferT* in);
int  sha256_end(SHA256ContextT ctx[1],BufferT* digest);

#define SHA384_DIGEST_SIZE  48
#define SHA384_BLOCK_SIZE  128
#define SHA512_DIGEST_SIZE  64
#define SHA512_BLOCK_SIZE  128
#define SHA2_MAX_DIGEST_SIZE    SHA512_DIGEST_SIZE

#define SHA2_OK         0
#define SHA2_FAILURE   -1
#define SHA2_CORRUPTED -2

/* type to hold the SHA384 (and SHA512) context */

typedef struct
{ uint_32t      magic0;
  
  uint_64t      count[2];
  uint_64t      hash[8];
  uint_64t      wbuf[16];
  
  uint_32t      magic1;
} SHA512ContextT;

typedef SHA512ContextT  SHA384ContextT;

typedef struct
{ union
  { SHA256ContextT ctx256[1];
    SHA512ContextT ctx512[1];
  } uu[1];
  uint_32t    sha2_len;
} SHA2ContextT;


int  sha384_begin(SHA384ContextT ctx[1]);
#define sha384_hash sha512_hash
int  sha384_end(SHA384ContextT ctx[1],BufferT* digest);

int  sha512_begin(SHA512ContextT ctx[1]);
int  sha512_hash(SHA512ContextT ctx[1],BufferT* in);
int  sha512_end(SHA512ContextT ctx[1],BufferT* digest);

int  sha2_begin(SHA2ContextT ctx[1],unsigned long size);
int  sha2_hash(SHA2ContextT ctx[1],BufferT* in);
int  sha2_end(SHA2ContextT ctx[1],BufferT* digest);

#endif
/*============================================================================END-OF-FILE============================================================================*/

