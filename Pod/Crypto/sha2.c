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

/*
 This is a byte oriented version of SHA2 that operates on arrays of bytes
 stored in memory. This code implements sha256, sha384 and sha512 but the
 latter two functions rely on efficient 64-bit integer operations that
 may not be very efficient on 32-bit machines

 The sha256 functions use a type 'sha256_ctx' to hold details of the
 current hash state and uses the following three calls:

       void sha256_begin(sha256_ctx ctx[1])
       void sha256_hash(const unsigned char data[],
                            unsigned long len, sha256_ctx ctx[1])
       void sha_end1(unsigned char hval[], sha256_ctx ctx[1])

 The first subroutine initialises a hash computation by setting up the
 context in the sha256_ctx context. The second subroutine hashes 8-bit
 bytes from array data[] into the hash state withinh sha256_ctx context,
 the number of bytes to be hashed being given by the the unsigned long
 integer len.  The third subroutine completes the hash calculation and
 places the resulting digest value in the array of 8-bit bytes hval[].

 The sha384 and sha512 functions are similar and use the interfaces:

       void sha384_begin(sha384_ctx ctx[1]);
       void sha384_hash(const unsigned char data[],
                            unsigned long len, sha384_ctx ctx[1]);
       void sha384_end(unsigned char hval[], sha384_ctx ctx[1]);

       void sha512_begin(sha512_ctx ctx[1]);
       void sha512_hash(const unsigned char data[],
                            unsigned long len, sha512_ctx ctx[1]);
       void sha512_end(unsigned char hval[], sha512_ctx ctx[1]);

 In addition there is a function sha2 that can be used to call all these
 functions using a call with a hash length parameter as follows:

       int sha2_begin(unsigned long len, sha2_ctx ctx[1]);
       void sha2_hash(const unsigned char data[],
                            unsigned long len, sha2_ctx ctx[1]);
       void sha2_end(unsigned char hval[], sha2_ctx ctx[1]);

 My thanks to Erik Andersen <andersen@codepoet.org> for testing this code
 on big-endian systems and for his assistance with corrections
*/

#include <string.h>     /* for memcpy() etc.        */
#include "sha2.h"

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

#if 0

#define ch(x,y,z)       (((x) & (y)) ^ (~(x) & (z)))
#define maj(x,y,z)      (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

#else   /* Thanks to Rich Schroeppel and Colin Plumb for the following      */

#define ch(x,y,z)       ((z) ^ ((x) & ((y) ^ (z))))
#define maj(x,y,z)      (((x) & (y)) | ((z) & ((x) ^ (y))))

#endif

/* round transforms for SHA256 and SHA512 compression functions */

#define vf(n,i) v[(n - i) & 7]

#define hf(i) (p[i & 15] += \
    g_1(p[(i + 14) & 15]) + p[(i + 9) & 15] + g_0(p[(i + 1) & 15]))

#define v_cycle(i,j)                                \
    vf(7,i) += (j ? hf(i) : p[i]) + k_0[i+j]        \
    + s_1(vf(4,i)) + ch(vf(4,i),vf(5,i),vf(6,i));   \
    vf(3,i) += vf(7,i);                             \
    vf(7,i) += s_0(vf(0,i))+ maj(vf(0,i),vf(1,i),vf(2,i))


#define SHA256_MASK (SHA256_BLOCK_SIZE - 1)

#if defined(SWAP_BYTES)
#define bsw_32(p,n) \
    { int _i = (n); while(_i--) ((uint_32t*)p)[_i] = bswap_32(((uint_32t*)p)[_i]); }
#else
#define bsw_32(p,n)
#endif

#define s_0(x)  (rotr32((x),  2) ^ rotr32((x), 13) ^ rotr32((x), 22))
#define s_1(x)  (rotr32((x),  6) ^ rotr32((x), 11) ^ rotr32((x), 25))
#define g_0(x)  (rotr32((x),  7) ^ rotr32((x), 18) ^ ((x) >>  3))
#define g_1(x)  (rotr32((x), 17) ^ rotr32((x), 19) ^ ((x) >> 10))
#define k_0     k256

/* rotated SHA256 round definition. Rather than swapping variables as in    */
/* FIPS-180, different variables are 'rotated' on each round, returning     */
/* to their starting positions every eight rounds                           */

#define q(n)  v##n

#define one_cycle(a,b,c,d,e,f,g,h,k,w)  \
    q(h) += s_1(q(e)) + ch(q(e), q(f), q(g)) + k + w; \
    q(d) += q(h); q(h) += s_0(q(a)) + maj(q(a), q(b), q(c))

/* SHA256 mixing data   */

const uint_32t k256[64] =
{   0x428a2f98ul, 0x71374491ul, 0xb5c0fbcful, 0xe9b5dba5ul,
    0x3956c25bul, 0x59f111f1ul, 0x923f82a4ul, 0xab1c5ed5ul,
    0xd807aa98ul, 0x12835b01ul, 0x243185beul, 0x550c7dc3ul,
    0x72be5d74ul, 0x80deb1feul, 0x9bdc06a7ul, 0xc19bf174ul,
    0xe49b69c1ul, 0xefbe4786ul, 0x0fc19dc6ul, 0x240ca1ccul,
    0x2de92c6ful, 0x4a7484aaul, 0x5cb0a9dcul, 0x76f988daul,
    0x983e5152ul, 0xa831c66dul, 0xb00327c8ul, 0xbf597fc7ul,
    0xc6e00bf3ul, 0xd5a79147ul, 0x06ca6351ul, 0x14292967ul,
    0x27b70a85ul, 0x2e1b2138ul, 0x4d2c6dfcul, 0x53380d13ul,
    0x650a7354ul, 0x766a0abbul, 0x81c2c92eul, 0x92722c85ul,
    0xa2bfe8a1ul, 0xa81a664bul, 0xc24b8b70ul, 0xc76c51a3ul,
    0xd192e819ul, 0xd6990624ul, 0xf40e3585ul, 0x106aa070ul,
    0x19a4c116ul, 0x1e376c08ul, 0x2748774cul, 0x34b0bcb5ul,
    0x391c0cb3ul, 0x4ed8aa4aul, 0x5b9cca4ful, 0x682e6ff3ul,
    0x748f82eeul, 0x78a5636ful, 0x84c87814ul, 0x8cc70208ul,
    0x90befffaul, 0xa4506cebul, 0xbef9a3f7ul, 0xc67178f2ul,
};

/**
 * Compile 64 bytes of hash data into SHA256 digest value   
 * NOTE: this routine assumes that the byte order in the    
 * ctx->wbuf[] at this point is such that low address bytes 
 * in the ORIGINAL byte stream will go into the high end of 
 * words on BOTH big and little endian systems              
 */
static void sha256_compile(SHA256ContextT ctx[1])
{ uint_32t j, *p = ctx->wbuf, v[8];

  memcpy(v, ctx->hash, 8 * sizeof(uint_32t));

  for(j = 0; j < 64; j += 16)
  {
    v_cycle( 0, j); v_cycle( 1, j);
    v_cycle( 2, j); v_cycle( 3, j);
    v_cycle( 4, j); v_cycle( 5, j);
    v_cycle( 6, j); v_cycle( 7, j);
    v_cycle( 8, j); v_cycle( 9, j);
    v_cycle(10, j); v_cycle(11, j);
    v_cycle(12, j); v_cycle(13, j);
    v_cycle(14, j); v_cycle(15, j);
  }

  ctx->hash[0] += v[0]; ctx->hash[1] += v[1];
  ctx->hash[2] += v[2]; ctx->hash[3] += v[3];
  ctx->hash[4] += v[4]; ctx->hash[5] += v[5];
  ctx->hash[6] += v[6]; ctx->hash[7] += v[7];
}

/**
 *
 */
static int sha256_check(SHA256ContextT ctx[1])
{ int result = SHA2_OK;
  
  if( ctx==NULL || ctx[0].magic0!=0xE7E7E7E7 || ctx[0].magic1!=0xB1B1B1B1 )
    result = SHA2_CORRUPTED;
  
  return result;
} /* of sha256_check() */


/* SHA256 hash data in an array of bytes into hash buffer   */
/* and call the hash_compile function as required.          */
int sha256_hash(SHA256ContextT ctx[1],BufferT* in)
{ uint_32t pos = (uint_32t)(ctx->count[0] & SHA256_MASK),
         space = SHA256_BLOCK_SIZE - pos;
  
  const unsigned char* data = in->data;
  unsigned long        len  = in->length;
  const unsigned char* sp   = data;

  if((ctx->count[0] += len) < len)
    ++(ctx->count[1]);

  while(len >= space)     /* tranfer whole blocks while possible  */
  {
    memcpy(((unsigned char*)ctx->wbuf) + pos, sp, space);
    sp += space; len -= space; space = SHA256_BLOCK_SIZE; pos = 0;
    bsw_32(ctx->wbuf, SHA256_BLOCK_SIZE >> 2)
    sha256_compile(ctx);
  }

  memcpy(((unsigned char*)ctx->wbuf) + pos, sp, len);
  
  return sha256_check(ctx);
} /* of sha256_hash() */

/* SHA256 Final padding and digest calculation  */

static void sha_end1(SHA256ContextT ctx[1],BufferT* digest)
{ uint_32t    i = (uint_32t)(ctx->count[0] & SHA256_MASK);

  /* put bytes in the buffer in an order in which references to   */
  /* 32-bit words will put bytes with lower addresses into the    */
  /* top of 32 bit words on BOTH big and little endian machines   */
  bsw_32(ctx->wbuf, (i + 3) >> 2)

  /* we now need to mask valid bytes and add the padding which is */
  /* a single 1 bit and as many zero bits as necessary. Note that */
  /* we can always add the first padding byte here because the    */
  /* buffer always has at least one empty slot                    */
  ctx->wbuf[i >> 2] &= 0xffffff80 << 8 * (~i & 3);
  ctx->wbuf[i >> 2] |= 0x00000080 << 8 * (~i & 3);

  /* we need 9 or more empty positions, one for the padding byte  */
  /* (above) and eight for the length count.  If there is not     */
  /* enough space pad and empty the buffer                        */
  if(i > SHA256_BLOCK_SIZE - 9)
  {
      if(i < 60) ctx->wbuf[15] = 0;
      sha256_compile(ctx);
      i = 0;
  }
  else    /* compute a word index for the empty buffer positions  */
      i = (i >> 2) + 1;

  while(i < 14) /* and zero pad all but last two positions        */
      ctx->wbuf[i++] = 0;

  /* the following 32-bit length fields are assembled in the      */
  /* wrong byte order on little endian machines but this is       */
  /* corrected later since they are only ever used as 32-bit      */
  /* word values.                                                 */
  ctx->wbuf[14] = (ctx->count[1] << 3) | (ctx->count[0] >> 29);
  ctx->wbuf[15] = ctx->count[0] << 3;
  sha256_compile(ctx);

  /* extract the hash value as bytes in case the hash buffer is   */
  /* mislaigned for 32-bit words                                  */
  if( digest!=NULL )
    for(i = 0; i < digest->length; ++i)
      digest->data[i] = (unsigned char)(ctx->hash[i >> 2] >> (8 * (~i & 3)));
} /* of sha_end1() */


const uint_32t i224[8] =
{
  0xc1059ed8ul, 0x367cd507ul, 0x3070dd17ul, 0xf70e5939ul,
  0xffc00b31ul, 0x68581511ul, 0x64f98fa7ul, 0xbefa4fa4ul
};


/**
 *
 */
int sha224_begin(SHA224ContextT ctx[1])
{ memset(ctx,0xE7,sizeof(SHA224ContextT));
  ctx->count[0] = ctx->count[1] = 0;
  memcpy(ctx->hash, i224, 8 * sizeof(uint_32t));
  ctx->magic1 = 0xB1B1B1B1;
  
  return SHA2_OK;
} /* of sha224_begin() */

/**
 *
 */
int sha224_end(SHA224ContextT ctx[1],BufferT* digest)
{ if( digest==NULL || digest->length!=SHA224_DIGEST_SIZE )
    return SHA2_FAILURE;
  
  sha_end1(ctx, digest);
  
  return sha256_check(ctx);
} /* of sha224_end */

const uint_32t i256[8] =
{
  0x6a09e667ul, 0xbb67ae85ul, 0x3c6ef372ul, 0xa54ff53aul,
  0x510e527ful, 0x9b05688cul, 0x1f83d9abul, 0x5be0cd19ul
};

/**
 *
 */
int sha256_begin(SHA256ContextT ctx[1])
{ memset(ctx,0xE7,sizeof(SHA256ContextT));
  ctx->count[0] = ctx->count[1] = 0;
  memcpy(ctx->hash, i256, 8 * sizeof(uint_32t));
  ctx->magic1 = 0xB1B1B1B1;
  
  return SHA2_OK;
} /* of sha256_end() */

/**
 *
 */
int sha256_end(SHA256ContextT ctx[1],BufferT* digest)
{ if( digest==NULL || digest->length!=SHA256_DIGEST_SIZE )
    return SHA2_FAILURE;
  
  sha_end1(ctx, digest);
  
  return sha256_check(ctx);
} /* of sha256_end() */

#define SHA512_MASK (SHA512_BLOCK_SIZE - 1)

#define rotr64(x,n)   (((x) >> n) | ((x) << (64 - n)))

#if !defined(bswap_64)
#define bswap_64(x) (((uint_64t)(bswap_32((uint_32t)(x)))) << 32 | bswap_32((uint_32t)((x) >> 32)))
#endif

#if defined(SWAP_BYTES)
#define bsw_64(p,n) \
    { int _i = (n); while(_i--) ((uint_64t*)p)[_i] = bswap_64(((uint_64t*)p)[_i]); }
#else
#define bsw_64(p,n)
#endif

/* SHA512 mixing function definitions   */

#ifdef   s_0
# undef  s_0
# undef  s_1
# undef  g_0
# undef  g_1
# undef  k_0
#endif

#define s_0(x)  (rotr64((x), 28) ^ rotr64((x), 34) ^ rotr64((x), 39))
#define s_1(x)  (rotr64((x), 14) ^ rotr64((x), 18) ^ rotr64((x), 41))
#define g_0(x)  (rotr64((x),  1) ^ rotr64((x),  8) ^ ((x) >>  7))
#define g_1(x)  (rotr64((x), 19) ^ rotr64((x), 61) ^ ((x) >>  6))
#define k_0     k512

/* SHA384/SHA512 mixing data    */

const uint_64t  k512[80] =
{
  li_64(428a2f98d728ae22), li_64(7137449123ef65cd),
  li_64(b5c0fbcfec4d3b2f), li_64(e9b5dba58189dbbc),
  li_64(3956c25bf348b538), li_64(59f111f1b605d019),
  li_64(923f82a4af194f9b), li_64(ab1c5ed5da6d8118),
  li_64(d807aa98a3030242), li_64(12835b0145706fbe),
  li_64(243185be4ee4b28c), li_64(550c7dc3d5ffb4e2),
  li_64(72be5d74f27b896f), li_64(80deb1fe3b1696b1),
  li_64(9bdc06a725c71235), li_64(c19bf174cf692694),
  li_64(e49b69c19ef14ad2), li_64(efbe4786384f25e3),
  li_64(0fc19dc68b8cd5b5), li_64(240ca1cc77ac9c65),
  li_64(2de92c6f592b0275), li_64(4a7484aa6ea6e483),
  li_64(5cb0a9dcbd41fbd4), li_64(76f988da831153b5),
  li_64(983e5152ee66dfab), li_64(a831c66d2db43210),
  li_64(b00327c898fb213f), li_64(bf597fc7beef0ee4),
  li_64(c6e00bf33da88fc2), li_64(d5a79147930aa725),
  li_64(06ca6351e003826f), li_64(142929670a0e6e70),
  li_64(27b70a8546d22ffc), li_64(2e1b21385c26c926),
  li_64(4d2c6dfc5ac42aed), li_64(53380d139d95b3df),
  li_64(650a73548baf63de), li_64(766a0abb3c77b2a8),
  li_64(81c2c92e47edaee6), li_64(92722c851482353b),
  li_64(a2bfe8a14cf10364), li_64(a81a664bbc423001),
  li_64(c24b8b70d0f89791), li_64(c76c51a30654be30),
  li_64(d192e819d6ef5218), li_64(d69906245565a910),
  li_64(f40e35855771202a), li_64(106aa07032bbd1b8),
  li_64(19a4c116b8d2d0c8), li_64(1e376c085141ab53),
  li_64(2748774cdf8eeb99), li_64(34b0bcb5e19b48a8),
  li_64(391c0cb3c5c95a63), li_64(4ed8aa4ae3418acb),
  li_64(5b9cca4f7763e373), li_64(682e6ff3d6b2b8a3),
  li_64(748f82ee5defb2fc), li_64(78a5636f43172f60),
  li_64(84c87814a1f0ab72), li_64(8cc702081a6439ec),
  li_64(90befffa23631e28), li_64(a4506cebde82bde9),
  li_64(bef9a3f7b2c67915), li_64(c67178f2e372532b),
  li_64(ca273eceea26619c), li_64(d186b8c721c0c207),
  li_64(eada7dd6cde0eb1e), li_64(f57d4f7fee6ed178),
  li_64(06f067aa72176fba), li_64(0a637dc5a2c898a6),
  li_64(113f9804bef90dae), li_64(1b710b35131c471b),
  li_64(28db77f523047d84), li_64(32caab7b40c72493),
  li_64(3c9ebe0a15c9bebc), li_64(431d67c49c100d4c),
  li_64(4cc5d4becb3e42b6), li_64(597f299cfc657e2a),
  li_64(5fcb6fab3ad6faec), li_64(6c44198c4a475817)
};

/* Compile 128 bytes of hash data into SHA384/512 digest    */
/* NOTE: this routine assumes that the byte order in the    */
/* ctx->wbuf[] at this point is such that low address bytes */
/* in the ORIGINAL byte stream will go into the high end of */
/* words on BOTH big and little endian systems              */
static void sha512_compile(SHA512ContextT ctx[1])
{ uint_64t    v[8], *p = ctx->wbuf;
  uint_32t    j;

  memcpy(v, ctx->hash, 8 * sizeof(uint_64t));

  for(j = 0; j < 80; j += 16)
  {
    v_cycle( 0, j); v_cycle( 1, j);
    v_cycle( 2, j); v_cycle( 3, j);
    v_cycle( 4, j); v_cycle( 5, j);
    v_cycle( 6, j); v_cycle( 7, j);
    v_cycle( 8, j); v_cycle( 9, j);
    v_cycle(10, j); v_cycle(11, j);
    v_cycle(12, j); v_cycle(13, j);
    v_cycle(14, j); v_cycle(15, j);
  }

  ctx->hash[0] += v[0]; ctx->hash[1] += v[1];
  ctx->hash[2] += v[2]; ctx->hash[3] += v[3];
  ctx->hash[4] += v[4]; ctx->hash[5] += v[5];
  ctx->hash[6] += v[6]; ctx->hash[7] += v[7];
}

/* Compile 128 bytes of hash data into SHA256 digest value  */
/* NOTE: this routine assumes that the byte order in the    */
/* ctx->wbuf[] at this point is in such an order that low   */
/* address bytes in the ORIGINAL byte stream placed in this */
/* buffer will now go to the high end of words on BOTH big  */
/* and little endian systems                                */
int sha512_hash(SHA512ContextT ctx[1],BufferT* in )
{ uint_32t pos = (uint_32t)(ctx->count[0] & SHA512_MASK),
         space = SHA512_BLOCK_SIZE - pos;
  
  const unsigned char* data = in->data;
  unsigned long        len  = in->length;
  const unsigned char* sp   = data;

  if((ctx->count[0] += len) < len)
      ++(ctx->count[1]);

  while(len >= space)     /* tranfer whole blocks while possible  */
  {
      memcpy(((unsigned char*)ctx->wbuf) + pos, sp, space);
      sp += space; len -= space; space = SHA512_BLOCK_SIZE; pos = 0;
      bsw_64(ctx->wbuf, SHA512_BLOCK_SIZE >> 3);
      sha512_compile(ctx);
  }

  memcpy(((unsigned char*)ctx->wbuf) + pos, sp, len);
  
  return SHA2_OK;
} /* of sha512_hash() */

/**
 * SHA384/512 Final padding and digest calculation  
 */
static void sha_end2(SHA512ContextT ctx[1],BufferT* digest)
{ uint_32t    i = (uint_32t)(ctx->count[0] & SHA512_MASK);

  /* put bytes in the buffer in an order in which references to   */
  /* 32-bit words will put bytes with lower addresses into the    */
  /* top of 32 bit words on BOTH big and little endian machines   */
  bsw_64(ctx->wbuf, (i + 7) >> 3);

  /* we now need to mask valid bytes and add the padding which is */
  /* a single 1 bit and as many zero bits as necessary. Note that */
  /* we can always add the first padding byte here because the    */
  /* buffer always has at least one empty slot                    */
  ctx->wbuf[i >> 3] &= li_64(ffffffffffffff00) << 8 * (~i & 7);
  ctx->wbuf[i >> 3] |= li_64(0000000000000080) << 8 * (~i & 7);

  /* we need 17 or more empty byte positions, one for the padding */
  /* byte (above) and sixteen for the length count.  If there is  */
  /* not enough space pad and empty the buffer                    */
  if(i > SHA512_BLOCK_SIZE - 17)
  {
      if(i < 120) ctx->wbuf[15] = 0;
      sha512_compile(ctx);
      i = 0;
  }
  else
      i = (i >> 3) + 1;

  while(i < 14)
      ctx->wbuf[i++] = 0;

  /* the following 64-bit length fields are assembled in the      */
  /* wrong byte order on little endian machines but this is       */
  /* corrected later since they are only ever used as 64-bit      */
  /* word values.                                                 */
  ctx->wbuf[14] = (ctx->count[1] << 3) | (ctx->count[0] >> 61);
  ctx->wbuf[15] = ctx->count[0] << 3;
  sha512_compile(ctx);

  /* extract the hash value as bytes in case the hash buffer is   */
  /* misaligned for 32-bit words                                  */  
  if( digest!=NULL )
    for(i = 0; i < digest->length; ++i)
      digest->data[i] = (unsigned char)(ctx->hash[i >> 3] >> (8 * (~i & 7)));
} /* of sha_end2() */



/* SHA384 initialisation data   */

const uint_64t  i384[80] =
{
  li_64(cbbb9d5dc1059ed8), li_64(629a292a367cd507),
  li_64(9159015a3070dd17), li_64(152fecd8f70e5939),
  li_64(67332667ffc00b31), li_64(8eb44a8768581511),
  li_64(db0c2e0d64f98fa7), li_64(47b5481dbefa4fa4)
};

/**
 *
 */
static int sha512_check(SHA512ContextT ctx[1])
{ int result = SHA2_OK;
  
  if( ctx==NULL || ctx[0].magic0!=0xE7E7E7E7 || ctx[0].magic1!=0xB1B1B1B1 )
    result = SHA2_CORRUPTED;
  
  return result;
} /* of sha512_check() */


/**
 *
 */
int sha384_begin(SHA384ContextT ctx[1])
{ memset(ctx,0xE7,sizeof(SHA384ContextT));
  ctx->count[0] = ctx->count[1] = 0;
  memcpy(ctx->hash, i384, 8 * sizeof(uint_64t));
  ctx->magic1 = 0xB1B1B1B1;
  
  return SHA2_OK;
} /* of sha384_begin() */

/**
 *
 */
int sha384_end(SHA384ContextT ctx[1],BufferT* digest)
{ if( digest==NULL || digest->length!=SHA384_DIGEST_SIZE )
    return SHA2_FAILURE;
  
  sha_end2(ctx, digest);
  
  return sha512_check(ctx);
} /* of sha384_end() */


/* SHA512 initialisation data   */

const uint_64t  i512[80] =
{
  li_64(6a09e667f3bcc908), li_64(bb67ae8584caa73b),
  li_64(3c6ef372fe94f82b), li_64(a54ff53a5f1d36f1),
  li_64(510e527fade682d1), li_64(9b05688c2b3e6c1f),
  li_64(1f83d9abfb41bd6b), li_64(5be0cd19137e2179)
};

/**
 *
 */
int sha512_begin(SHA512ContextT ctx[1])
{ memset(ctx,0xE7,sizeof(SHA512ContextT));
  ctx->count[0] = ctx->count[1] = 0;
  memcpy(ctx->hash, i512, 8 * sizeof(uint_64t));
  ctx->magic1 = 0xB1B1B1B1;
  
  return SHA2_OK;
} /* of sha512_begin() */

/**
 *
 */
int sha512_end(SHA512ContextT ctx[1],BufferT* digest)
{ if( digest==NULL || digest->length!=SHA512_DIGEST_SIZE )
    return SHA2_FAILURE;
  
  sha_end2(ctx, digest);
  
  return sha512_check(ctx);
} /* of sha512_end() */

#define CTX_224(x)  ((x)->uu->ctx256)
#define CTX_256(x)  ((x)->uu->ctx256)
#define CTX_384(x)  ((x)->uu->ctx512)
#define CTX_512(x)  ((x)->uu->ctx512)

/* SHA2 initialisation */

int sha2_begin(SHA2ContextT ctx[1],unsigned long len)
{ int result = SHA2_OK;
  
  switch(len)
  { case 224:
    case  28:   
      CTX_256(ctx)->count[0] = CTX_256(ctx)->count[1] = 0;
      memcpy(CTX_256(ctx)->hash, i224, 32);
      ctx->sha2_len = 28; 
      break;
    case 256:
    case  32:   
      CTX_256(ctx)->count[0] = CTX_256(ctx)->count[1] = 0;
      memcpy(CTX_256(ctx)->hash, i256, 32);
      ctx->sha2_len = 32; 
      break;
    case 384:
    case  48:   
      CTX_384(ctx)->count[0] = CTX_384(ctx)->count[1] = 0;
      memcpy(CTX_384(ctx)->hash, i384, 64);
      ctx->sha2_len = 48; 
      break;
    case 512:
    case  64:   
      CTX_512(ctx)->count[0] = CTX_512(ctx)->count[1] = 0;
      memcpy(CTX_512(ctx)->hash, i512, 64);
      ctx->sha2_len = 64; 
      break;
    default:    
      result = SHA2_FAILURE;
      break;
  } /* of switch */
  
  return result;
} /* of sha2_begin() */

/**
 *
 */
int sha2_hash(SHA2ContextT ctx[1],BufferT* in)
{ int result = SHA2_OK;
  
  switch(ctx->sha2_len)
  { case 28: 
      result = sha224_hash(CTX_224(ctx),in); 
      break;
    case 32: 
      result = sha256_hash(CTX_256(ctx),in); 
      break;
    case 48: 
      result = sha384_hash(CTX_384(ctx),in); 
      break;
    case 64: 
      result = sha512_hash(CTX_512(ctx),in); 
      break;
  } /* of switch */
  
  return result;
} /* of sha2_hash() */

/**
 *
 */
int sha2_end(SHA2ContextT ctx[1],BufferT* digest)
{ int result = SHA2_OK;
  
  switch(ctx->sha2_len)
  { case 28: 
      if( digest==NULL || digest->length!=SHA224_DIGEST_SIZE )
        result = SHA2_FAILURE;
      else
        sha_end1(CTX_224(ctx), digest); 
      break;
    case 32: 
      if( digest==NULL || digest->length!=SHA256_DIGEST_SIZE )
        result = SHA2_FAILURE;
      else
        sha_end1(CTX_256(ctx), digest); 
      break;
    case 48: 
      if( digest==NULL || digest->length!=SHA384_DIGEST_SIZE )
        result = SHA2_FAILURE;
      else
        sha_end2(CTX_384(ctx), digest); 
      break;
    case 64: 
      if( digest==NULL || digest->length!=SHA512_DIGEST_SIZE )
        result = SHA2_FAILURE;
      else
        sha_end2(CTX_512(ctx), digest); 
      break;
  } /* of switch */
  
  return result;
} /* of sha2_end() */
/*============================================================================END-OF-FILE============================================================================*/
