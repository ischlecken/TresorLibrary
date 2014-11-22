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
 * This is a byte oriented version of SHA1 that operates on arrays of bytes
 * stored in memory.
 */

#include <string.h>     /* for memcpy() etc.        */
#include "sha1.h"

#define rotl32(x,n)   (((x) << n) | ((x) >> (32 - n)))
#define rotr32(x,n)   (((x) >> n) | ((x) << (32 - n)))

#if !defined(bswap_32)
#define bswap_32(x) ((rotr32((x), 24) & 0x00ff00ff) | (rotr32((x), 8) & 0xff00ff00))
#endif

#if (PLATFORM_BYTE_ORDER == IS_LITTLE_ENDIAN)
#define SWAP_BYTES
#else
#undef  SWAP_BYTES
#endif

#if defined(SWAP_BYTES)
#define bsw_32(p,n) \
    { int _i = (n); while(_i--) ((uint_32t*)p)[_i] = bswap_32(((uint_32t*)p)[_i]); }
#else
#define bsw_32(p,n)
#endif

#define SHA1_MASK   (SHA1_BLOCK_SIZE - 1)

#if 0

#define ch(x,y,z)       (((x) & (y)) ^ (~(x) & (z)))
#define parity(x,y,z)   ((x) ^ (y) ^ (z))
#define maj(x,y,z)      (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

#else   /* Discovered by Rich Schroeppel and Colin Plumb   */

#define ch(x,y,z)       ((z) ^ ((x) & ((y) ^ (z))))
#define parity(x,y,z)   ((x) ^ (y) ^ (z))
#define maj(x,y,z)      (((x) & (y)) | ((z) & ((x) ^ (y))))

#endif

/* Compile 64 bytes of hash data into SHA1 context. Note    */
/* that this routine assumes that the byte order in the     */
/* ctx[0].wbuf[] at this point is in such an order that low   */
/* address bytes in the ORIGINAL byte stream will go in     */
/* this buffer to the high end of 32-bit words on BOTH big  */
/* and little endian systems                                */

#ifdef ARRAY
#define q(v,n)  v[n]
#else
#define q(v,n)  v##n
#endif

#define one_cycle(v,a,b,c,d,e,f,k,h)            \
    q(v,e) += rotr32(q(v,a),27) +               \
              f(q(v,b),q(v,c),q(v,d)) + k + h;  \
    q(v,b)  = rotr32(q(v,b), 2)

#define five_cycle(v,f,k,i)                 \
    one_cycle(v, 0,1,2,3,4, f,k,hf(i  ));   \
    one_cycle(v, 4,0,1,2,3, f,k,hf(i+1));   \
    one_cycle(v, 3,4,0,1,2, f,k,hf(i+2));   \
    one_cycle(v, 2,3,4,0,1, f,k,hf(i+3));   \
    one_cycle(v, 1,2,3,4,0, f,k,hf(i+4))

static void sha1_compile(SHA1ContextT ctx[1])
{ uint_32t    *w = ctx[0].wbuf;

#ifdef ARRAY
  uint_32t    v[5];
  memcpy(v, ctx[0].hash, 5 * sizeof(uint_32t));
#else
  uint_32t    v0, v1, v2, v3, v4;
  v0 = ctx[0].hash[0]; v1 = ctx[0].hash[1];
  v2 = ctx[0].hash[2]; v3 = ctx[0].hash[3];
  v4 = ctx[0].hash[4];
#endif

#define hf(i)   w[i]

  five_cycle(v, ch, 0x5a827999,  0);
  five_cycle(v, ch, 0x5a827999,  5);
  five_cycle(v, ch, 0x5a827999, 10);
  one_cycle(v,0,1,2,3,4, ch, 0x5a827999, hf(15)); \

#undef  hf
#define hf(i) (w[(i) & 15] = rotl32(                    \
               w[((i) + 13) & 15] ^ w[((i) + 8) & 15] \
             ^ w[((i) +  2) & 15] ^ w[(i) & 15], 1))

  one_cycle(v,4,0,1,2,3, ch, 0x5a827999, hf(16));
  one_cycle(v,3,4,0,1,2, ch, 0x5a827999, hf(17));
  one_cycle(v,2,3,4,0,1, ch, 0x5a827999, hf(18));
  one_cycle(v,1,2,3,4,0, ch, 0x5a827999, hf(19));

  five_cycle(v, parity, 0x6ed9eba1,  20);
  five_cycle(v, parity, 0x6ed9eba1,  25);
  five_cycle(v, parity, 0x6ed9eba1,  30);
  five_cycle(v, parity, 0x6ed9eba1,  35);

  five_cycle(v, maj, 0x8f1bbcdc,  40);
  five_cycle(v, maj, 0x8f1bbcdc,  45);
  five_cycle(v, maj, 0x8f1bbcdc,  50);
  five_cycle(v, maj, 0x8f1bbcdc,  55);

  five_cycle(v, parity, 0xca62c1d6,  60);
  five_cycle(v, parity, 0xca62c1d6,  65);
  five_cycle(v, parity, 0xca62c1d6,  70);
  five_cycle(v, parity, 0xca62c1d6,  75);

#ifdef ARRAY
  ctx[0].hash[0] += v[0]; ctx[0].hash[1] += v[1];
  ctx[0].hash[2] += v[2]; ctx[0].hash[3] += v[3];
  ctx[0].hash[4] += v[4];
#else
  ctx[0].hash[0] += v0; ctx[0].hash[1] += v1;
  ctx[0].hash[2] += v2; ctx[0].hash[3] += v3;
  ctx[0].hash[4] += v4;
#endif
}

/**
 *
 */
static int sha1_check(SHA1ContextT ctx[1])
{ int result = SHA1_OK;
  
  if( ctx==NULL || ctx[0].magic0!=0xE7E7E7E7 || ctx[0].magic1!=0xC1C1C1C1 )
    result = SHA1_CORRUPTED;
  
  return result;
} /* of sha1_check() */

/**
 *
 */
int sha1_begin(SHA1ContextT ctx[1])
{ if( ctx==NULL )
    return SHA1_FAILURE;
  
  memset(ctx,0xE7,sizeof(SHA1ContextT));
  
  ctx[0].count[0] = ctx[0].count[1] = 0;
  ctx[0].hash[0] = 0x67452301;
  ctx[0].hash[1] = 0xefcdab89;
  ctx[0].hash[2] = 0x98badcfe;
  ctx[0].hash[3] = 0x10325476;
  ctx[0].hash[4] = 0xc3d2e1f0;
  
  ctx[0].magic1  = 0xC1C1C1C1;
  
  return SHA1_OK;
} /* of sha1_begin() */

/**
 * SHA1 hash data in an array of bytes into hash buffer and 
 * call the hash_compile function as required.              
 */
int sha1_hash(SHA1ContextT ctx[1],BufferT* in)
{ int result = sha1_check(ctx);
  
  if( result!=SHA1_OK )
    return result;
  
  if( in==NULL )
    return SHA1_FAILURE;
  
  unsigned long        len  = in->length;
  const unsigned char* data = in->data;
  uint_32t             pos  = (uint_32t)(ctx[0].count[0] & SHA1_MASK), space = SHA1_BLOCK_SIZE - pos;
  const unsigned char* sp   = data;

  if((ctx[0].count[0] += len) < len)
    ++(ctx[0].count[1]);

  while(len >= space)     /* tranfer whole blocks if possible  */
  { memcpy(((unsigned char*)ctx[0].wbuf) + pos, sp, space);
    
    sp    += space; 
    len   -= space; 
    space  = SHA1_BLOCK_SIZE; 
    pos    = 0;
    
    bsw_32(ctx[0].wbuf, SHA1_BLOCK_SIZE >> 2);
    
    sha1_compile(ctx);
  } // of while

  memcpy(((unsigned char*)ctx[0].wbuf) + pos, sp, len);
  
  return sha1_check(ctx);
} /* of sha1_hash() */

/**
 * SHA1 final padding and digest calculation
 */
int sha1_end(SHA1ContextT ctx[1],BufferT* out)
{ int result = sha1_check(ctx);
  
  if( result!=SHA1_OK )
    return result;
  
  if( out==NULL || out->length<SHA1_DIGEST_SIZE )
    return SHA1_FAILURE;
  
  uint_32t i = (uint_32t)(ctx[0].count[0] & SHA1_MASK);

  /* put bytes in the buffer in an order in which references to   */
  /* 32-bit words will put bytes with lower addresses into the    */
  /* top of 32 bit words on BOTH big and little endian machines   */
  bsw_32(ctx[0].wbuf, (i + 3) >> 2);

  /* we now need to mask valid bytes and add the padding which is */
  /* a single 1 bit and as many zero bits as necessary. Note that */
  /* we can always add the first padding byte here because the    */
  /* buffer always has at least one empty slot                    */
  ctx[0].wbuf[i >> 2] &= 0xffffff80 << 8 * (~i & 3);
  ctx[0].wbuf[i >> 2] |= 0x00000080 << 8 * (~i & 3);

  /* we need 9 or more empty positions, one for the padding byte  */
  /* (above) and eight for the length count. If there is not      */
  /* enough space, pad and empty the buffer                       */
  if( i>SHA1_BLOCK_SIZE - 9 )
  {
    if(i < 60) ctx[0].wbuf[15] = 0;
    sha1_compile(ctx);
    i = 0;
  } /* of if */
  else    /* compute a word index for the empty buffer positions  */
    i = (i >> 2) + 1;

  while(i < 14) /* and zero pad all but last two positions        */
    ctx[0].wbuf[i++] = 0;

  /* the following 32-bit length fields are assembled in the      */
  /* wrong byte order on little endian machines but this is       */
  /* corrected later since they are only ever used as 32-bit      */
  /* word values.                                                 */
  ctx[0].wbuf[14] = (ctx[0].count[1] << 3) | (ctx[0].count[0] >> 29);
  ctx[0].wbuf[15] = ctx[0].count[0] << 3;
  sha1_compile(ctx);

  /* extract the hash value as bytes in case the hash buffer is   */
  /* misaligned for 32-bit words                                  */
  for( i=0;i<SHA1_DIGEST_SIZE;++i )
    out->data[i] = (unsigned char)(ctx[0].hash[i >> 2] >> (8 * (~i & 3)));
  
  return sha1_check(ctx);
} /* of sha1_end() */
/*============================================================================END-OF-FILE============================================================================*/
