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

/***************************************************************************
	Submitters:
		Bruce Schneier, Counterpane Systems
		Doug Whiting,	Hi/fn
		John Kelsey,	Counterpane Systems
		Chris Hall,		Counterpane Systems
		David Wagner,	UC Berkeley
			
	Code Author:		Doug Whiting,	Hi/fn
		
	Version  1.00		April 1998
***************************************************************************/

#include <stdlib.h>
#include <string.h>
#include "twofish.h"

#define   TRUE 1
#define   FALSE 0
#define 	DIR_ENCRYPT 	0 		/* Are we encrpyting? */
#define 	DIR_DECRYPT 	1 		/* Are we decrpyting? */
#define 	MODE_ECB 		1 		/* Are we ciphering in ECB mode? */
#define 	MODE_CBC 		2 		/* Are we ciphering in CBC mode? */

#define		ROUNDS_128			 16	/* default number of rounds for 128-bit keys*/
#define		ROUNDS_192			 16	/* default number of rounds for 192-bit keys*/
#define		ROUNDS_256			 16	/* default number of rounds for 256-bit keys*/
#define		MAX_KEY_BITS		256	/* max number of bits of key */
#define		MIN_KEY_BITS		128	/* min number of bits of key (zero pad) */
#define		VALID_SIG	 0x48534946	/* initialization signature ('FISH') */
#define		MCT_OUTER			400	/* MCT outer loop */
#define		MCT_INNER		  10000	/* MCT inner loop */
#define		REENTRANT			  1	/* nonzero forces reentrant code (slightly slower) */


typedef uint_32t fullSbox[4][256];


/* for computing subkeys */
#define	SK_STEP			0x02020202u
#define	SK_BUMP			0x01010101u
#define	SK_ROTL			9

/* Reed-Solomon code parameters: (12,8) reversible code
 g(x) = x**4 + (a + 1/a) x**3 + a x**2 + (a + 1/a) x + 1
 where a = primitive root of field generator 0x14D */
#define	RS_GF_FDBK		0x14D		/* field generator */
#define	RS_rem(x)		\
{ uint_8t  b  = (uint_8t) (x >> 24);											 \
  uint_32t g2 = ((b << 1) ^ ((b & 0x80) ? RS_GF_FDBK : 0 )) & 0xFF;		 \
  uint_32t g3 = ((b >> 1) & 0x7F) ^ ((b & 1) ? RS_GF_FDBK >> 1 : 0 ) ^ g2 ; \
  x = (x << 8) ^ (g3 << 24) ^ (g2 << 16) ^ (g3 << 8) ^ b;				 \
}

/*	Macros for the MDS matrix
 *	The MDS matrix is (using primitive polynomial 169):
 *      01  EF  5B  5B
 *      5B  EF  EF  01
 *      EF  5B  01  EF
 *      EF  01  EF  5B
 *----------------------------------------------------------------
 * More statistical properties of this matrix (from MDS.EXE output):
 *
 * Min Hamming weight (one uint_8t difference) =  8. Max=26.  Total =  1020.
 * Prob[8]:      7    23    42    20    52    95    88    94   121   128    91
 *             102    76    41    24     8     4     1     3     0     0     0
 * Runs[8]:      2     4     5     6     7     8     9    11
 * MSBs[8]:      1     4    15     8    18    38    40    43
 * HW= 8: 05040705 0A080E0A 14101C14 28203828 50407050 01499101 A080E0A0 
 * HW= 9: 04050707 080A0E0E 10141C1C 20283838 40507070 80A0E0E0 C6432020 07070504 
 *        0E0E0A08 1C1C1410 38382820 70705040 E0E0A080 202043C6 05070407 0A0E080E 
 *        141C101C 28382038 50704070 A0E080E0 4320C620 02924B02 089A4508 
 * Min Hamming weight (two uint_8t difference) =  3. Max=28.  Total = 390150.
 * Prob[3]:      7    18    55   149   270   914  2185  5761 11363 20719 32079
 *           43492 51612 53851 52098 42015 31117 20854 11538  6223  2492  1033
 * MDS OK, ROR:   6+  7+  8+  9+ 10+ 11+ 12+ 13+ 14+ 15+ 16+
 *               17+ 18+ 19+ 20+ 21+ 22+ 23+ 24+ 25+ 26+
 */
#define	MDS_GF_FDBK		0x169	/* primitive polynomial for GF(256)*/
#define	LFSR1(x) ( ((x) >> 1)  ^ (((x) & 0x01) ?   MDS_GF_FDBK/2 : 0))
#define	LFSR2(x) ( ((x) >> 2)  ^ (((x) & 0x02) ?   MDS_GF_FDBK/2 : 0)  \
^ (((x) & 0x01) ?   MDS_GF_FDBK/4 : 0))

#define	Mx_1(x) ((uint_32t)  (x))		/* force result to uint_32t so << will work */
#define	Mx_X(x) ((uint_32t) ((x) ^            LFSR2(x)))	/* 5B */
#define	Mx_Y(x) ((uint_32t) ((x) ^ LFSR1(x) ^ LFSR2(x)))	/* EF */

#define	M00		Mul_1
#define	M01		Mul_Y
#define	M02		Mul_X
#define	M03		Mul_X

#define	M10		Mul_X
#define	M11		Mul_Y
#define	M12		Mul_Y
#define	M13		Mul_1

#define	M20		Mul_Y
#define	M21		Mul_X
#define	M22		Mul_1
#define	M23		Mul_Y

#define	M30		Mul_Y
#define	M31		Mul_1
#define	M32		Mul_Y
#define	M33		Mul_X

#define	Mul_1	Mx_1
#define	Mul_X	Mx_X
#define	Mul_Y	Mx_Y

/*	Define the fixed p0/p1 permutations used in keyed S-box lookup.  
 By changing the following constant definitions for P_ij, the S-boxes will
 automatically get changed in all the Twofish source code. Note that P_i0 is
 the "outermost" 8x8 permutation applied.  See the f32() function to see
 how these constants are to be  used.
 */
#define	P_00	1					/* "outermost" permutation */
#define	P_01	0
#define	P_02	0
#define	P_03	(P_01^1)			/* "extend" to larger key sizes */
#define	P_04	1

#define	P_10	0
#define	P_11	0
#define	P_12	1
#define	P_13	(P_11^1)
#define	P_14	0

#define	P_20	1
#define	P_21	1
#define	P_22	0
#define	P_23	(P_21^1)
#define	P_24	0

#define	P_30	0
#define	P_31	1
#define	P_32	1
#define	P_33	(P_31^1)
#define	P_34	1

#define	p8(N)	P8x8[P_##N]			/* some syntax shorthand */

/* fixed 8x8 permutation S-boxes */

/***********************************************************************
 *  07:07:14  05/30/98  [4x4]  TestCnt=256. keySize=128. CRC=4BD14D9E.
 * maxKeyed:  dpMax = 18. lpMax =100. fixPt =  8. skXor =  0. skDup =  6. 
 * log2(dpMax[ 6..18])=   --- 15.42  1.33  0.89  4.05  7.98 12.05
 * log2(lpMax[ 7..12])=  9.32  1.01  1.16  4.23  8.02 12.45
 * log2(fixPt[ 0.. 8])=  1.44  1.44  2.44  4.06  6.01  8.21 11.07 14.09 17.00
 * log2(skXor[ 0.. 0])
 * log2(skDup[ 0.. 6])=   ---  2.37  0.44  3.94  8.36 13.04 17.99
 ***********************************************************************/
 uint_8t P8x8[2][256]=
{
  /*  p0:   */
  /*  dpMax      = 10.  lpMax      = 64.  cycleCnt=   1  1  1  0.         */
  /* 817D6F320B59ECA4.ECB81235F4A6709D.BA5E6D90C8F32471.D7F4126E9B3085CA. */
  /* Karnaugh maps:
   *  0111 0001 0011 1010. 0001 1001 1100 1111. 1001 1110 0011 1110. 1101 0101 1111 1001. 
   *  0101 1111 1100 0100. 1011 0101 0010 0000. 0101 1000 1100 0101. 1000 0111 0011 0010. 
   *  0000 1001 1110 1101. 1011 1000 1010 0011. 0011 1001 0101 0000. 0100 0010 0101 1011. 
   *  0111 0100 0001 0110. 1000 1011 1110 1001. 0011 0011 1001 1101. 1101 0101 0000 1100. 
   */
	{
    0xA9, 0x67, 0xB3, 0xE8, 0x04, 0xFD, 0xA3, 0x76, 
    0x9A, 0x92, 0x80, 0x78, 0xE4, 0xDD, 0xD1, 0x38, 
    0x0D, 0xC6, 0x35, 0x98, 0x18, 0xF7, 0xEC, 0x6C, 
    0x43, 0x75, 0x37, 0x26, 0xFA, 0x13, 0x94, 0x48, 
    0xF2, 0xD0, 0x8B, 0x30, 0x84, 0x54, 0xDF, 0x23, 
    0x19, 0x5B, 0x3D, 0x59, 0xF3, 0xAE, 0xA2, 0x82, 
    0x63, 0x01, 0x83, 0x2E, 0xD9, 0x51, 0x9B, 0x7C, 
    0xA6, 0xEB, 0xA5, 0xBE, 0x16, 0x0C, 0xE3, 0x61, 
    0xC0, 0x8C, 0x3A, 0xF5, 0x73, 0x2C, 0x25, 0x0B, 
    0xBB, 0x4E, 0x89, 0x6B, 0x53, 0x6A, 0xB4, 0xF1, 
    0xE1, 0xE6, 0xBD, 0x45, 0xE2, 0xF4, 0xB6, 0x66, 
    0xCC, 0x95, 0x03, 0x56, 0xD4, 0x1C, 0x1E, 0xD7, 
    0xFB, 0xC3, 0x8E, 0xB5, 0xE9, 0xCF, 0xBF, 0xBA, 
    0xEA, 0x77, 0x39, 0xAF, 0x33, 0xC9, 0x62, 0x71, 
    0x81, 0x79, 0x09, 0xAD, 0x24, 0xCD, 0xF9, 0xD8, 
    0xE5, 0xC5, 0xB9, 0x4D, 0x44, 0x08, 0x86, 0xE7, 
    0xA1, 0x1D, 0xAA, 0xED, 0x06, 0x70, 0xB2, 0xD2, 
    0x41, 0x7B, 0xA0, 0x11, 0x31, 0xC2, 0x27, 0x90, 
    0x20, 0xF6, 0x60, 0xFF, 0x96, 0x5C, 0xB1, 0xAB, 
    0x9E, 0x9C, 0x52, 0x1B, 0x5F, 0x93, 0x0A, 0xEF, 
    0x91, 0x85, 0x49, 0xEE, 0x2D, 0x4F, 0x8F, 0x3B, 
    0x47, 0x87, 0x6D, 0x46, 0xD6, 0x3E, 0x69, 0x64, 
    0x2A, 0xCE, 0xCB, 0x2F, 0xFC, 0x97, 0x05, 0x7A, 
    0xAC, 0x7F, 0xD5, 0x1A, 0x4B, 0x0E, 0xA7, 0x5A, 
    0x28, 0x14, 0x3F, 0x29, 0x88, 0x3C, 0x4C, 0x02, 
    0xB8, 0xDA, 0xB0, 0x17, 0x55, 0x1F, 0x8A, 0x7D, 
    0x57, 0xC7, 0x8D, 0x74, 0xB7, 0xC4, 0x9F, 0x72, 
    0x7E, 0x15, 0x22, 0x12, 0x58, 0x07, 0x99, 0x34, 
    0x6E, 0x50, 0xDE, 0x68, 0x65, 0xBC, 0xDB, 0xF8, 
    0xC8, 0xA8, 0x2B, 0x40, 0xDC, 0xFE, 0x32, 0xA4, 
    0xCA, 0x10, 0x21, 0xF0, 0xD3, 0x5D, 0x0F, 0x00, 
    0x6F, 0x9D, 0x36, 0x42, 0x4A, 0x5E, 0xC1, 0xE0
	},
  /*  p1:   */
  /*  dpMax      = 10.  lpMax      = 64.  cycleCnt=   2  0  0  1.         */
  /* 28BDF76E31940AC5.1E2B4C376DA5F908.4C75169A0ED82B3F.B951C3DE647F208A. */
  /* Karnaugh maps:
   *  0011 1001 0010 0111. 1010 0111 0100 0110. 0011 0001 1111 0100. 1111 1000 0001 1100. 
   *  1100 1111 1111 1010. 0011 0011 1110 0100. 1001 0110 0100 0011. 0101 0110 1011 1011. 
   *  0010 0100 0011 0101. 1100 1000 1000 1110. 0111 1111 0010 0110. 0000 1010 0000 0011. 
   *  1101 1000 0010 0001. 0110 1001 1110 0101. 0001 0100 0101 0111. 0011 1011 1111 0010. 
   */
	{
    0x75, 0xF3, 0xC6, 0xF4, 0xDB, 0x7B, 0xFB, 0xC8, 
    0x4A, 0xD3, 0xE6, 0x6B, 0x45, 0x7D, 0xE8, 0x4B, 
    0xD6, 0x32, 0xD8, 0xFD, 0x37, 0x71, 0xF1, 0xE1, 
    0x30, 0x0F, 0xF8, 0x1B, 0x87, 0xFA, 0x06, 0x3F, 
    0x5E, 0xBA, 0xAE, 0x5B, 0x8A, 0x00, 0xBC, 0x9D, 
    0x6D, 0xC1, 0xB1, 0x0E, 0x80, 0x5D, 0xD2, 0xD5, 
    0xA0, 0x84, 0x07, 0x14, 0xB5, 0x90, 0x2C, 0xA3, 
    0xB2, 0x73, 0x4C, 0x54, 0x92, 0x74, 0x36, 0x51, 
    0x38, 0xB0, 0xBD, 0x5A, 0xFC, 0x60, 0x62, 0x96, 
    0x6C, 0x42, 0xF7, 0x10, 0x7C, 0x28, 0x27, 0x8C, 
    0x13, 0x95, 0x9C, 0xC7, 0x24, 0x46, 0x3B, 0x70, 
    0xCA, 0xE3, 0x85, 0xCB, 0x11, 0xD0, 0x93, 0xB8, 
    0xA6, 0x83, 0x20, 0xFF, 0x9F, 0x77, 0xC3, 0xCC, 
    0x03, 0x6F, 0x08, 0xBF, 0x40, 0xE7, 0x2B, 0xE2, 
    0x79, 0x0C, 0xAA, 0x82, 0x41, 0x3A, 0xEA, 0xB9, 
    0xE4, 0x9A, 0xA4, 0x97, 0x7E, 0xDA, 0x7A, 0x17, 
    0x66, 0x94, 0xA1, 0x1D, 0x3D, 0xF0, 0xDE, 0xB3, 
    0x0B, 0x72, 0xA7, 0x1C, 0xEF, 0xD1, 0x53, 0x3E, 
    0x8F, 0x33, 0x26, 0x5F, 0xEC, 0x76, 0x2A, 0x49, 
    0x81, 0x88, 0xEE, 0x21, 0xC4, 0x1A, 0xEB, 0xD9, 
    0xC5, 0x39, 0x99, 0xCD, 0xAD, 0x31, 0x8B, 0x01, 
    0x18, 0x23, 0xDD, 0x1F, 0x4E, 0x2D, 0xF9, 0x48, 
    0x4F, 0xF2, 0x65, 0x8E, 0x78, 0x5C, 0x58, 0x19, 
    0x8D, 0xE5, 0x98, 0x57, 0x67, 0x7F, 0x05, 0x64, 
    0xAF, 0x63, 0xB6, 0xFE, 0xF5, 0xB7, 0x3C, 0xA5, 
    0xCE, 0xE9, 0x68, 0x44, 0xE0, 0x4D, 0x43, 0x69, 
    0x29, 0x2E, 0xAC, 0x15, 0x59, 0xA8, 0x0A, 0x9E, 
    0x6E, 0x47, 0xDF, 0x34, 0x35, 0x6A, 0xCF, 0xDC, 
    0x22, 0xC9, 0xC0, 0x9B, 0x89, 0xD4, 0xED, 0xAB, 
    0x12, 0xA2, 0x0D, 0x52, 0xBB, 0x02, 0x2F, 0xA9, 
    0xD7, 0x61, 0x1E, 0xB4, 0x50, 0x04, 0xF6, 0xC2, 
    0x16, 0x25, 0x86, 0x56, 0x55, 0x09, 0xBE, 0x91
	}
};


/*
+*****************************************************************************
*			Constants/Macros/Tables
-****************************************************************************/

#define		VALIDATE_PARMS	1		/* nonzero --> check all parameters */
#define		FEISTEL			0		/* nonzero --> use Feistel version (slow) */

int  tabEnable=0;					/* are we gathering stats? */
uint_8t tabUsed[256];					/* one bit per table */

#define	P0_USED		0x01
#define	P1_USED		0x02
#define	B0_USED		0x04
#define	B1_USED		0x08
#define	B2_USED		0x10
#define	B3_USED		0x20
#define	ALL_USED	0x3F

/* number of rounds for various key sizes: 128, 192, 256 */
int			numRounds[4]= {0,ROUNDS_128,ROUNDS_192,ROUNDS_256};

#define	ROL(x,n) (((x) << ((n) & 0x1F)) | ((x) >> (32-((n) & 0x1F))))
#define	ROR(x,n) (((x) >> ((n) & 0x1F)) | ((x) << (32-((n) & 0x1F))))

#if PLATFORM_BYTE_ORDER == IS_LITTLE_ENDIAN
#define		Bswap(x)			(x)		/* NOP for little-endian machines */
#define		ADDR_XOR			0		/* NOP for little-endian machines */
#else
#define		Bswap(x)			((ROR(x,8) & 0xFF00FF00) | (ROL(x,8) & 0x00FF00FF))
#define		ADDR_XOR			3		/* convert uint_8t address in uint_32t */
#endif

/*	Macros for extracting bytes from dwords (correct for endianness) */
#define	_b(x,N)	(((uint_8t *)&x)[((N) & 3) ^ ADDR_XOR]) /* pick bytes out of a uint_32t */

#define		b0(x)			_b(x,0)		/* extract LSB of uint_32t */
#define		b1(x)			_b(x,1)
#define		b2(x)			_b(x,2)
#define		b3(x)			_b(x,3)		/* extract MSB of uint_32t */



/*
+*****************************************************************************
*
* Function Name:	f32
*
* Function:			Run four bytes through keyed S-boxes and apply MDS matrix
*
* Arguments:		x			=	input to f function
*					k32			=	pointer to key dwords
*					keyLen		=	total key length (k32 --> keyLey/2 bits)
*
* Return:			The output of the keyed permutation applied to x.
*
* Notes:
*	This function is a keyed 32-bit permutation.  It is the major building
*	block for the Twofish round function, including the four keyed 8x8 
*	permutations and the 4x4 MDS matrix multiply.  This function is used
*	both for generating round subkeys and within the round function on the
*	block being encrypted.  
*
*	This version is fairly slow and pedagogical, although a smartcard would
*	probably perform the operation exactly this way in firmware.   For
*	ultimate performance, the entire operation can be completed with four
*	lookups into four 256x32-bit tables, with three uint_32t xors.
*
*	The MDS matrix is defined in TABLE.H.  To multiply by Mij, just use the
*	macro Mij(x).
*
-****************************************************************************/
uint_32t f32(uint_32t x, uint_32t *k32,int keyLen)
{
	uint_8t  b[4];
	
	/* Run each uint_8t thru 8x8 S-boxes, xoring with key uint_8t at each stage. */
	/* Note that each uint_8t goes through a different combination of S-boxes.*/

	*((uint_32t *)b) = Bswap(x);	/* make b[0] = LSB, b[3] = MSB */
	switch (((keyLen + 63)/64) & 3)
  {
		case 0:		/* 256 bits of key */
			b[0] = p8(04)[b[0]] ^ b0(k32[3]);
			b[1] = p8(14)[b[1]] ^ b1(k32[3]);
			b[2] = p8(24)[b[2]] ^ b2(k32[3]);
			b[3] = p8(34)[b[3]] ^ b3(k32[3]);
			/* fall thru, having pre-processed b[0]..b[3] with k32[3] */
		case 3:		/* 192 bits of key */
			b[0] = p8(03)[b[0]] ^ b0(k32[2]);
			b[1] = p8(13)[b[1]] ^ b1(k32[2]);
			b[2] = p8(23)[b[2]] ^ b2(k32[2]);
			b[3] = p8(33)[b[3]] ^ b3(k32[2]);
			/* fall thru, having pre-processed b[0]..b[3] with k32[2] */
		case 2:		/* 128 bits of key */
			b[0] = p8(00)[p8(01)[p8(02)[b[0]] ^ b0(k32[1])] ^ b0(k32[0])];
			b[1] = p8(10)[p8(11)[p8(12)[b[1]] ^ b1(k32[1])] ^ b1(k32[0])];
			b[2] = p8(20)[p8(21)[p8(22)[b[2]] ^ b2(k32[1])] ^ b2(k32[0])];
			b[3] = p8(30)[p8(31)[p8(32)[b[3]] ^ b3(k32[1])] ^ b3(k32[0])];
  }

	if (tabEnable)
  {	/* we could give a "tighter" bound, but this works acceptably well */
		tabUsed[b0(x)] |= (P_00 == 0) ? P0_USED : P1_USED;
		tabUsed[b1(x)] |= (P_10 == 0) ? P0_USED : P1_USED;
		tabUsed[b2(x)] |= (P_20 == 0) ? P0_USED : P1_USED;
		tabUsed[b3(x)] |= (P_30 == 0) ? P0_USED : P1_USED;

		tabUsed[b[0] ] |= B0_USED;
		tabUsed[b[1] ] |= B1_USED;
		tabUsed[b[2] ] |= B2_USED;
		tabUsed[b[3] ] |= B3_USED;
  }

	/* Now perform the MDS matrix multiply inline. */
	return	((M00(b[0]) ^ M01(b[1]) ^ M02(b[2]) ^ M03(b[3]))	  ) ^
			((M10(b[0]) ^ M11(b[1]) ^ M12(b[2]) ^ M13(b[3])) <<  8) ^
			((M20(b[0]) ^ M21(b[1]) ^ M22(b[2]) ^ M23(b[3])) << 16) ^
			((M30(b[0]) ^ M31(b[1]) ^ M32(b[2]) ^ M33(b[3])) << 24) ;
}

/*
+*****************************************************************************
*
* Function Name:	RS_MDS_Encode
*
* Function:			Use (12,8) Reed-Solomon code over GF(256) to produce
*					a key S-box uint_32t from two key material dwords.
*
* Arguments:		k0	=	1st uint_32t
*					k1	=	2nd uint_32t
*
* Return:			Remainder polynomial generated using RS code
*
* Notes:
*	Since this computation is done only once per reKey per 64 bits of key,
*	the performance impact of this routine is imperceptible. The RS code
*	chosen has "simple" coefficients to allow smartcard/hardware implementation
*	without lookup tables.
*
-****************************************************************************/
uint_32t RS_MDS_Encode(uint_32t k0,uint_32t k1)
{
	int i,j;
	uint_32t r;

	for (i=r=0;i<2;i++)
	{
		r ^= (i) ? k0 : k1;			/* merge in 32 more key bits */
		for (j=0;j<4;j++)			/* shift one uint_8t at a time */
			RS_rem(r);				
	}
	return r;
}

/*
+*****************************************************************************
*
* Function Name:	reKey
*
* Function:			Initialize the Twofish key schedule from key32
*
* Arguments:		key			=	ptr to keyInstance to be initialized
*
* Return:			TRUE on success
*
* Notes:
*	Here we precompute all the round subkeys, although that is not actually
*	required.  For example, on a smartcard, the round subkeys can 
*	be generated on-the-fly	using f32()
*
-****************************************************************************/
int reKey(TwofishContextT *key)
{
	int		i,k64Cnt;
	int		keyLen	  = key->keyLen;
	int		subkeyCnt = ROUND_SUBKEYS + 2*key->numRounds;
	uint_32t	A,B;
	uint_32t	k32e[MAX_KEY_BITS/64],k32o[MAX_KEY_BITS/64]; /* even/odd key dwords */

	if( keyLen!=TWOFISH_KEY_SIZE )
		return BAD_KEY_INSTANCE;
  
	if( subkeyCnt>TOTAL_SUBKEYS )
		return BAD_KEY_INSTANCE;

	k64Cnt=keyLen/8;
	for( i=0;i<k64Cnt;i++ )
  {	
    /* split into even/odd key dwords */
		k32e[i]=key->key32[2*i  ];
		k32o[i]=key->key32[2*i+1];
		/* compute S-box keys using (12,8) Reed-Solomon code over GF(256) */
		key->sboxKeys[k64Cnt-1-i]=RS_MDS_Encode(k32e[i],k32o[i]); /* reverse order */
  }

	for (i=0;i<subkeyCnt/2;i++)					/* compute round subkeys for PHT */
  {
		A = f32(i*SK_STEP        ,k32e,keyLen*8);	/* A uses even key dwords */
		B = f32(i*SK_STEP+SK_BUMP,k32o,keyLen*8);	/* B uses odd  key dwords */
		B = ROL(B,8);
		key->subKeys[2*i  ] = A+  B;			/* combine with a PHT */
		key->subKeys[2*i+1] = ROL(A+2*B,SK_ROTL);
  }

	return TWOFISH_OK;
}



/**
 *
 */
int twofish_check(TwofishContextT ctx[1])
{ int result = TWOFISH_OK;
  
  if( ctx!=NULL && (ctx[0].magic0!=0xE7E7E7E7 || ctx[0].magic1!=0xC4C4C4C4) )
    result = TWOFISH_CORRUPTED;
  else if( ctx==NULL )
    result = TWOFISH_FAILURE;
  
  return result;
} /* of twofish_check() */

/**
 * key->length = 16(128bit),24(192bit),32(256bit)
 */
int twofish_begin  (TwofishContextT ctx[1],BufferT* key,BufferT* iv)
{ int result = TWOFISH_OK;
  
  if( ctx==NULL || key==NULL || (key->length!=TWOFISH_KEY_SIZE) )
    return TWOFISH_FAILURE;
  
  if( iv!=NULL && (iv->length!=TWOFISH_BLOCK_SIZE || iv->data==NULL) )
    return TWOFISH_FAILURE;
  
  memset(ctx,0xE7,sizeof(TwofishContextT));
  
	ctx->keyLen		  = key->length;
	ctx->numRounds	= numRounds[(key->length*8-1)/64];
 
  memset(ctx->key32, 0, TWOFISH_KEY_SIZE);
  memcpy(ctx->key32, key->data, key->length);

  if( iv!=NULL )
  { ctx->mode = MODE_CBC;
    
    memcpy(ctx->iv32,iv->data,iv->length);
  } /* of if */
  else
    ctx->mode = MODE_ECB;
  
  ctx[0].magic1 = 0xC4C4C4C4;

	result = reKey(ctx);
  
  return result;
} /* of twofish_begin() */

/*
 +*****************************************************************************
 *
 * Function Name:	twofish_encrypt
 *
 * Function:			Encrypt block(s) of data using Twofish
 *
 * Arguments:
 *
 * Return:	
 *
 * Notes: 
 *
 -****************************************************************************/
int twofish_encrypt(TwofishContextT ctx[1],BufferT* in,BufferT* out,int usePadding)
{ int result = twofish_check(ctx);
  
  if( result!=TWOFISH_OK )
    return result;

  if( in==NULL || out==NULL || in->length<=0 || out->length<=0 )
    return TWOFISH_FAILURE;

  int cipherBlocks = in->length/TWOFISH_BLOCK_SIZE;
  
  if( usePadding )
  { cipherBlocks++;

    if( out->length!=cipherBlocks*TWOFISH_BLOCK_SIZE )
      return TWOFISH_FAILURE;
  } /* of if */
  else if( out->length!=in->length || in->length%TWOFISH_BLOCK_SIZE!=0 )
    return TWOFISH_FAILURE;
  
	int      i,n,r,c;					/* loop variables */
	uint_32t x[TWOFISH_BLOCK_SIZE_DWORD];			/* block being encrypted */
	uint_32t t0,t1,tmp;				/* temp variables */
	int	     rounds=ctx->numRounds;	/* number of rounds */

  uint_8t* input = in->data;
  uint_8t  inputBuffer[TWOFISH_BLOCK_SIZE];
  uint_8t* outBuffer = out->data;
  
	/* here for ECB, CBC modes */
	for( c=0,n=0;c<cipherBlocks;c++,n+=TWOFISH_BLOCK_SIZE,input+=TWOFISH_BLOCK_SIZE,outBuffer+=TWOFISH_BLOCK_SIZE )
  {
    if( usePadding )
    { int sLen = in->length-n>=TWOFISH_BLOCK_SIZE ? TWOFISH_BLOCK_SIZE : in->length-n;
     
      if( sLen>0 )
        memcpy(inputBuffer, input, sLen);
      
      if( sLen<0 )
        return TWOFISH_FAILURE;
      else if( sLen<TWOFISH_BLOCK_SIZE )
        memset(inputBuffer+sLen,TWOFISH_BLOCK_SIZE-sLen,TWOFISH_BLOCK_SIZE-sLen);
    } /* of if */
    else 
      memcpy(inputBuffer, input, TWOFISH_BLOCK_SIZE);
    
    for (i=0;i<TWOFISH_BLOCK_SIZE_DWORD;i++)	/* copy in the block, add whitening */
    { x[i]=Bswap(((uint_32t *)inputBuffer)[i]) ^ ctx->subKeys[INPUT_WHITEN+i];
     
      if (ctx->mode == MODE_CBC)
        x[i] ^= ctx->iv32[i];
    } /* of for */
    
		for (r=0;r<rounds;r++)			/* main Twofish encryption loop */
    {	
#if FEISTEL
			t0	 = f32(ROR(x[0],  (r+1)/2),key->sboxKeys,ctx->keyLen*8);
			t1	 = f32(ROL(x[1],8+(r+1)/2),key->sboxKeys,ctx->keyLen*8);
      /* PHT, round keys */
			x[2]^= ROL(t0 +   t1 + key->subKeys[ROUND_SUBKEYS+2*r  ], r    /2);
			x[3]^= ROR(t0 + 2*t1 + key->subKeys[ROUND_SUBKEYS+2*r+1],(r+2) /2);
#else
			t0	 = f32(    x[0]   ,ctx->sboxKeys,ctx->keyLen*8);
			t1	 = f32(ROL(x[1],8),ctx->sboxKeys,ctx->keyLen*8);
      
			x[3] = ROL(x[3],1);
			x[2]^= t0 +   t1 + ctx->subKeys[ROUND_SUBKEYS+2*r  ]; /* PHT, round keys */
			x[3]^= t0 + 2*t1 + ctx->subKeys[ROUND_SUBKEYS+2*r+1];
			x[2] = ROR(x[2],1);
#endif
      
			if (r < rounds-1)						/* swap for next round */
      {	tmp = x[0]; x[0]= x[2]; x[2] = tmp;
				tmp = x[1]; x[1]= x[3]; x[3] = tmp;
      } /* of if */
    } /* of for */
    
#if FEISTEL
		x[0] = ROR(x[0],8);                     /* "final permutation" */
		x[1] = ROL(x[1],8);
		x[2] = ROR(x[2],8);
		x[3] = ROL(x[3],8);
#endif
		
    for (i=0;i<TWOFISH_BLOCK_SIZE_DWORD;i++)	/* copy out, with whitening */
    {	((uint_32t *)outBuffer)[i] = Bswap(x[i] ^ ctx->subKeys[OUTPUT_WHITEN+i]);
		
      if( ctx->mode==MODE_CBC )
				ctx->iv32[i] = Bswap(((uint_32t *)outBuffer)[i]);
    } /* of for */
  } /* of for */
  
  return twofish_check(ctx);
} /* of twofish_encrypt() */

/*
 +*****************************************************************************
 *
 * Function Name:	twofish_decrypt
 *
 * Function: Decrypt block(s) of data using Twofish
 *
 * Arguments:
 *
 * Return: errorCode
 *
 * Notes: 
 *
 -****************************************************************************/
int twofish_decrypt(TwofishContextT ctx[1],BufferT* in,BufferT* out,int usePadding)
{ int result = twofish_check(ctx);
  
  if( result!=TWOFISH_OK )
    return result;
  
  if( in==NULL || in->length<=0 || in->length%TWOFISH_BLOCK_SIZE!=0 || out==NULL )
    return TWOFISH_FAILURE;
  
 	int      i,n,r;					/* loop counters */
	uint_32t x[TWOFISH_BLOCK_SIZE_DWORD];			/* block being encrypted */
	uint_32t t0,t1;					/* temp variables */
	int      rounds=ctx->numRounds;	/* number of rounds */
  
  uint_8t* input     = in->data;
  uint_8t  outBuffer[TWOFISH_BLOCK_SIZE];
  
	/* here for ECB, CBC modes */
	for( n=0;n<in->length;n+=TWOFISH_BLOCK_SIZE,input+=TWOFISH_BLOCK_SIZE )
  {	
    for (i=0;i<TWOFISH_BLOCK_SIZE_DWORD;i++)	/* copy in the block, add whitening */
			x[i]=Bswap(((uint_32t *)input)[i]) ^ ctx->subKeys[OUTPUT_WHITEN+i];
    
		for(r=rounds-1;r>=0;r--)			/* main Twofish decryption loop */
    {
			t0	 = f32(    x[0]   ,ctx->sboxKeys,ctx->keyLen*8);
			t1	 = f32(ROL(x[1],8),ctx->sboxKeys,ctx->keyLen*8);
      
			x[2] = ROL(x[2],1);
			x[2]^= t0 +   t1 + ctx->subKeys[ROUND_SUBKEYS+2*r  ]; /* PHT, round keys */
			x[3]^= t0 + 2*t1 + ctx->subKeys[ROUND_SUBKEYS+2*r+1];
			x[3] = ROR(x[3],1);
      
			if (r)									/* unswap, except for last round */
			{	t0   = x[0]; x[0]= x[2]; x[2] = t0;	
				t1   = x[1]; x[1]= x[3]; x[3] = t1;
			} /* of if */
		} /* of for */
		
		for (i=0;i<TWOFISH_BLOCK_SIZE_DWORD;i++)	/* copy out, with whitening */
		{	x[i] ^= ctx->subKeys[INPUT_WHITEN+i];
		
      if( ctx->mode==MODE_CBC )
			{	x[i]         ^= ctx->iv32[i];
				ctx->iv32[i]  = Bswap(((uint_32t *)input)[i]);
			} /* of if */
      
			((uint_32t *)outBuffer)[i] = Bswap(x[i]);
		} /* of for */

    // last block, detect and remove padding
    if( usePadding && n+TWOFISH_BLOCK_SIZE>=in->length )
    { uint_8t padding = ((uint_8t*)outBuffer)[TWOFISH_BLOCK_SIZE-1];
      
      if( padding>TWOFISH_BLOCK_SIZE )
        return TWOFISH_FAILURE;
      
      uint_8t paddingBlock[TWOFISH_BLOCK_SIZE];
      memset(paddingBlock,0,TWOFISH_BLOCK_SIZE);
      memset(paddingBlock,padding,padding);
      
      if( memcmp(outBuffer+(TWOFISH_BLOCK_SIZE-padding), paddingBlock, padding)!=0 )
        return TWOFISH_FAILURE;
      
      if( out->length<n+(TWOFISH_BLOCK_SIZE-padding) )
        return TWOFISH_FAILURE;
      
      memcpy(out->data+n, outBuffer, TWOFISH_BLOCK_SIZE-padding);
      
      out->length -= padding;
    } /* of if */
    else 
      memcpy(out->data+n,outBuffer,TWOFISH_BLOCK_SIZE);
  } /* of for */
  
  return twofish_check(ctx);
} /* of twofish_decrypt() */

/**
 *
 */
int twofish_end(TwofishContextT ctx[1])
{ int result = twofish_check(ctx); 
  
  return result;
} /* of twofish_end() */
/*============================================================================END-OF-FILE============================================================================*/

