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
#ifndef PWD2KEY_H
#define PWD2KEY_H

#include "buffer.h"
#include "hmac.h"

#define DERIVEKEY_OK         0
#define DERIVEKEY_FAILURE   -1

#define DERIVEKEY_OUTPUT_SIZE HASH_OUTPUT_SIZE

int deriveKey(BufferT* pwd,BufferT* salt,BufferT* key,unsigned int iter);
#endif
/*============================================================================END-OF-FILE============================================================================*/
