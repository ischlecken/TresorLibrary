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
 * This is an implementation of HMAC, the FIPS standard keyed hash function
 */

#ifndef _HMAC_H
#define _HMAC_H

#include <memory.h>
#include "crypto.h"
#include "buffer.h"


#define  USE_SHA1 1

#if !defined(USE_SHA1) && !defined(USE_SHA256)
#error define USE_SHA1 or USE_SHA256 to set the HMAC hash algorithm
#endif

#ifdef USE_SHA1

#include "sha1.h"

#define HASH_INPUT_SIZE     SHA1_BLOCK_SIZE
#define HASH_OUTPUT_SIZE    SHA1_DIGEST_SIZE
#define sha_ctx             SHA1ContextT
#define sha_begin           sha1_begin
#define sha_hash            sha1_hash
#define sha_end             sha1_end

#endif

#ifdef USE_SHA256

#include "sha2.h"

#define HASH_INPUT_SIZE     SHA256_BLOCK_SIZE
#define HASH_OUTPUT_SIZE    SHA256_DIGEST_SIZE
#define sha_ctx             SHA256ContextT
#define sha_begin           sha256_begin
#define sha_hash            sha256_hash
#define sha_end             sha256_end

#endif

#define HMAC_OK                0
#define HMAC_FAILURE          -1
#define HMAC_BAD_MODE         -2
#define HMAC_IN_DATA           1

typedef struct
{ uint_32t        magic0;
  unsigned char   key[HASH_INPUT_SIZE];
  unsigned long   klen;
  sha_ctx         ctx;
  uint_32t        magic1;
} HMACContextT;

int hmac_sha_begin(HMACContextT* ctx);
int hmac_sha_key(HMACContextT* ctx,BufferT* key);
int hmac_sha_data(HMACContextT* ctx,BufferT* data);
int hmac_sha_end(HMACContextT* ctx,BufferT* out);

#endif
/*============================================================================END-OF-FILE============================================================================*/
