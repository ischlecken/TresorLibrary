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
#ifndef _SHA1_H
#define _SHA1_H

#include <stdlib.h>
#include "crypto.h"
#include "buffer.h"

#define SHA1_BLOCK_SIZE  64
#define SHA1_DIGEST_SIZE 20

#define SHA1_OK         0
#define SHA1_FAILURE   -1
#define SHA1_CORRUPTED -2


/* type to hold the SHA256 context  */

typedef struct
{ uint_32t magic0;
  
  uint_32t count[2];
  uint_32t hash[5];
  uint_32t wbuf[16];
  
  uint_32t magic1;
} SHA1ContextT;


/* Note that these prototypes are the same for both bit and */
/* byte oriented implementations. However the length fields */
/* are in bytes or bits as appropriate for the version used */
/* and bit sequences are input as arrays of bytes in which  */
/* bit sequences run from the most to the least significant */
/* end of each byte                                         */

int sha1_begin  (SHA1ContextT ctx[1]);
int sha1_hash   (SHA1ContextT ctx[1],BufferT* in);
int sha1_end    (SHA1ContextT ctx[1],BufferT* out);

#endif
/*============================================================================END-OF-FILE============================================================================*/
