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
#ifndef MD5_H
#define MD5_H

#include "crypto.h"
#include "buffer.h"

#define MD5_DIGEST_SIZE 16

typedef struct MD5Context
{ uint_32t magic0;
  uint_32t count[2];	/* message length in bits, lsw first */
  uint_32t abcd[4];		/* digest buffer */
  uint_8t  buf[64];		/* accumulate block */
  uint_32t magic1;
} MD5ContextT;

#define MD5_OK         0
#define MD5_FAILURE   -1
#define MD5_CORRUPTED -2

int md5_begin (MD5ContextT ctx[1]);
int md5_hash  (MD5ContextT ctx[1],BufferT* data);
int md5_end   (MD5ContextT ctx[1],BufferT* digest);

#endif
