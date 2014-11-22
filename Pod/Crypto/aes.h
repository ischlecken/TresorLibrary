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
#ifndef AES_H
#define AES_H

#import "crypto.h"
#include "buffer.h"

#define AES_BLOCK_SIZE 16
#define AES_KEY_SIZE   32

#define AES_OK         0
#define AES_FAILURE   -1
#define AES_CORRUPTED -2

typedef struct AESContext
{
  uint_32t magic0;
  
  // The number of rounds in AES aes_Cipher. It is simply initiated to zero. The actual value is received in the program.
  int Nr;
  
  // The number of 32 bit words in the key. It is simply initiated to zero. The actual value is received in the program.
  int Nk;
  
  // in    - it is the array that holds the plain text to be encrypted.
  uint_8t in[AES_BLOCK_SIZE];
  
  // state - the array that holds the intermediate results during encryption.
  uint_8t state[4][4];
  
  // The array that stores the round keys.
  uint_8t RoundKey[240];
  
  uint_8t use_iv;
  uint_8t iv0[AES_BLOCK_SIZE];  
  uint_8t iv [AES_BLOCK_SIZE];  
  
  uint_32t magic1;
} AESContextT;


/**
 * key.length = 16(128bit),24(192bit),32(256bit)
 * iv         = initialization vector: if set, CBC mode will be used, else ECB mode
 */

int aes_begin  (AESContextT ctx[1],BufferT* key,BufferT* iv);
int aes_encrypt(AESContextT ctx[1],BufferT* in,BufferT* out);
int aes_decrypt(AESContextT ctx[1],BufferT* in,BufferT* out);
int aes_end    (AESContextT ctx[1]);

#endif
