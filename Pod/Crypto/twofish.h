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
#ifndef TWOFISH_H
#define TWOFISH_H

#include "crypto.h"
#include "buffer.h"

#define TWOFISH_OK         0
#define TWOFISH_FAILURE   -1
#define TWOFISH_CORRUPTED -2

#define TWOFISH_BLOCK_SIZE       16
#define TWOFISH_BLOCK_SIZE_DWORD (TWOFISH_BLOCK_SIZE/sizeof(uint_32t))
#define TWOFISH_KEY_SIZE         32
#define TWOFISH_KEY_SIZE_DWORD   (TWOFISH_KEY_SIZE/sizeof(uint_32t))

#define		MAX_KEY_SIZE		64	/* # of ASCII chars needed to represent a key */
#define		MAX_ROUNDS      16	/* max # rounds (for allocating subkey array) */
#define		MAX_IV_SIZE			16	/* # of bytes needed to represent an IV */

#define		INPUT_WHITEN		0	/* subkey array indices */
#define		OUTPUT_WHITEN		( INPUT_WHITEN + TWOFISH_BLOCK_SIZE/sizeof(uint_32t))
#define		ROUND_SUBKEYS		(OUTPUT_WHITEN + TWOFISH_BLOCK_SIZE/sizeof(uint_32t))	/* use 2 * (# rounds) */
#define		TOTAL_SUBKEYS		(ROUND_SUBKEYS + 2*MAX_ROUNDS)


#define TWOFISH_OK         0
#define TWOFISH_FAILURE   -1
#define TWOFISH_CORRUPTED -2

#define 	BAD_KEY_DIR 		  -3	/* Key direction is invalid (unknown value) */
#define 	BAD_KEY_MAT 		  -4	/* Key material not of correct length */
#define 	BAD_KEY_INSTANCE 	-5	/* Key passed is not valid */
#define 	BAD_CIPHER_MODE 	-6 	/* Params struct passed to cipherInit invalid */
#define 	BAD_CIPHER_STATE 	-7 	/* Cipher in wrong state (e.g., not initialized) */

/* CHANGE POSSIBLE: inclusion of algorithm specific defines */
/* TWOFISH specific definitions */
#define		BAD_INPUT_LEN		-8	/* inputLen not a multiple of block size */
#define		BAD_PARAMS			-9	/* invalid parameters */
#define		BAD_IV_MAT			-10	/* invalid IV text */
#define		BAD_ENDIAN			-11	/* incorrect endianness define */
#define		BAD_ALIGN32			-12	/* incorrect 32-bit alignment */


typedef struct TwofishContext
{
  uint_32t magic0;
  
	uint_8t direction;					/* Key used for encrypting or decrypting? */
	int     keyLen;					/* Length of the key */
	char    keyMaterial[MAX_KEY_SIZE+4];/* Raw key data in ASCII */
  
	/* Twofish-specific parameters: */
	uint_32t keySig;					/* set to VALID_SIG by makeKey() */
	int	     numRounds;				/* number of rounds in cipher */
	uint_32t key32[TWOFISH_KEY_SIZE_DWORD];	/* actual key bits, in dwords */
	uint_32t sboxKeys[TWOFISH_KEY_SIZE/(sizeof(uint_32t)*2)];/* key bits used for S-boxes */
	uint_32t subKeys[TOTAL_SUBKEYS];	/* round subkeys, input/output whitening bits */
  
	uint_8t  mode;						/* MODE_ECB, MODE_CBC */
	uint_32t iv32[TWOFISH_BLOCK_SIZE_DWORD];		/* CBC IV bytes arranged as dwords */
  
  uint_32t magic1;
} TwofishContextT;


/**
 * key.length = 16(128bit),24(192bit),32(256bit)
 * iv         = initialization vector: if set, CBC mode will be used, else ECB mode
 */

int twofish_begin  (TwofishContextT ctx[1],BufferT* key,BufferT* iv);
int twofish_encrypt(TwofishContextT ctx[1],BufferT* in,BufferT* out,int usePadding);
int twofish_decrypt(TwofishContextT ctx[1],BufferT* in,BufferT* out,int usePadding);
int twofish_end    (TwofishContextT ctx[1]);

#endif
