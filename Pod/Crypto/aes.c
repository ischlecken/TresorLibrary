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
#include <stdlib.h>
#include <string.h>
#include "aes.h"

// The number of columns comprising a (ctx[0].state) (ctx[0].in) AES. This is a constant (ctx[0].in) AES. Value=4
#define Nb 4

static int aes_getSBoxValue(int num)
{
  int sbox[256] =   
  {
    //0     1    2      3     4    5     6     7      8    9     A      B    C     D     E     F
    0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76, //0
    0xca, 0x82, 0xc9, 0x7d, 0xfa, 0x59, 0x47, 0xf0, 0xad, 0xd4, 0xa2, 0xaf, 0x9c, 0xa4, 0x72, 0xc0, //1
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1, 0x71, 0xd8, 0x31, 0x15, //2
    0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a, 0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, //3
    0x09, 0x83, 0x2c, 0x1a, 0x1b, 0x6e, 0x5a, 0xa0, 0x52, 0x3b, 0xd6, 0xb3, 0x29, 0xe3, 0x2f, 0x84, //4
    0x53, 0xd1, 0x00, 0xed, 0x20, 0xfc, 0xb1, 0x5b, 0x6a, 0xcb, 0xbe, 0x39, 0x4a, 0x4c, 0x58, 0xcf, //5
    0xd0, 0xef, 0xaa, 0xfb, 0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8, //6
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21, 0x10, 0xff, 0xf3, 0xd2, //7
    0xcd, 0x0c, 0x13, 0xec, 0x5f, 0x97, 0x44, 0x17, 0xc4, 0xa7, 0x7e, 0x3d, 0x64, 0x5d, 0x19, 0x73, //8
    0x60, 0x81, 0x4f, 0xdc, 0x22, 0x2a, 0x90, 0x88, 0x46, 0xee, 0xb8, 0x14, 0xde, 0x5e, 0x0b, 0xdb, //9
    0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c, 0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, //A
    0xe7, 0xc8, 0x37, 0x6d, 0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08, //B
    0xba, 0x78, 0x25, 0x2e, 0x1c, 0xa6, 0xb4, 0xc6, 0xe8, 0xdd, 0x74, 0x1f, 0x4b, 0xbd, 0x8b, 0x8a, //C
    0x70, 0x3e, 0xb5, 0x66, 0x48, 0x03, 0xf6, 0x0e, 0x61, 0x35, 0x57, 0xb9, 0x86, 0xc1, 0x1d, 0x9e, //D
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9, 0xce, 0x55, 0x28, 0xdf, //E
    0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16  //F
  }; 
  
  return sbox[num];
}

static int aes_getSBoxInvert(int num)
{
  int rsbox[256] = 
  {
    0x52, 0x09, 0x6a, 0xd5, 0x30, 0x36, 0xa5, 0x38, 0xbf, 0x40, 0xa3, 0x9e, 0x81, 0xf3, 0xd7, 0xfb,
    0x7c, 0xe3, 0x39, 0x82, 0x9b, 0x2f, 0xff, 0x87, 0x34, 0x8e, 0x43, 0x44, 0xc4, 0xde, 0xe9, 0xcb,
    0x54, 0x7b, 0x94, 0x32, 0xa6, 0xc2, 0x23, 0x3d, 0xee, 0x4c, 0x95, 0x0b, 0x42, 0xfa, 0xc3, 0x4e,
    0x08, 0x2e, 0xa1, 0x66, 0x28, 0xd9, 0x24, 0xb2, 0x76, 0x5b, 0xa2, 0x49, 0x6d, 0x8b, 0xd1, 0x25,
    0x72, 0xf8, 0xf6, 0x64, 0x86, 0x68, 0x98, 0x16, 0xd4, 0xa4, 0x5c, 0xcc, 0x5d, 0x65, 0xb6, 0x92,
    0x6c, 0x70, 0x48, 0x50, 0xfd, 0xed, 0xb9, 0xda, 0x5e, 0x15, 0x46, 0x57, 0xa7, 0x8d, 0x9d, 0x84,
    0x90, 0xd8, 0xab, 0x00, 0x8c, 0xbc, 0xd3, 0x0a, 0xf7, 0xe4, 0x58, 0x05, 0xb8, 0xb3, 0x45, 0x06,
    0xd0, 0x2c, 0x1e, 0x8f, 0xca, 0x3f, 0x0f, 0x02, 0xc1, 0xaf, 0xbd, 0x03, 0x01, 0x13, 0x8a, 0x6b,
    0x3a, 0x91, 0x11, 0x41, 0x4f, 0x67, 0xdc, 0xea, 0x97, 0xf2, 0xcf, 0xce, 0xf0, 0xb4, 0xe6, 0x73,
    0x96, 0xac, 0x74, 0x22, 0xe7, 0xad, 0x35, 0x85, 0xe2, 0xf9, 0x37, 0xe8, 0x1c, 0x75, 0xdf, 0x6e,
    0x47, 0xf1, 0x1a, 0x71, 0x1d, 0x29, 0xc5, 0x89, 0x6f, 0xb7, 0x62, 0x0e, 0xaa, 0x18, 0xbe, 0x1b,
    0xfc, 0x56, 0x3e, 0x4b, 0xc6, 0xd2, 0x79, 0x20, 0x9a, 0xdb, 0xc0, 0xfe, 0x78, 0xcd, 0x5a, 0xf4,
    0x1f, 0xdd, 0xa8, 0x33, 0x88, 0x07, 0xc7, 0x31, 0xb1, 0x12, 0x10, 0x59, 0x27, 0x80, 0xec, 0x5f,
    0x60, 0x51, 0x7f, 0xa9, 0x19, 0xb5, 0x4a, 0x0d, 0x2d, 0xe5, 0x7a, 0x9f, 0x93, 0xc9, 0x9c, 0xef,
    0xa0, 0xe0, 0x3b, 0x4d, 0xae, 0x2a, 0xf5, 0xb0, 0xc8, 0xeb, 0xbb, 0x3c, 0x83, 0x53, 0x99, 0x61,
    0x17, 0x2b, 0x04, 0x7e, 0xba, 0x77, 0xd6, 0x26, 0xe1, 0x69, 0x14, 0x63, 0x55, 0x21, 0x0c, 0x7d 
  };
  
  return rsbox[num];
}

// The round constant word array, aes_Rcon[i], contains the values given by 
// x to th e power (i-1) being powers of x (x is denoted as {02}) (ctx[0].in) the field GF(28)
// Note that i starts at 1, not 0).
static int aes_Rcon[255] = 
{
  0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 
  0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 
  0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 
  0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 
  0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 
  0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 
  0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 
  0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 
  0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 
  0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 
  0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 0xc6, 0x97, 0x35, 
  0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 0x61, 0xc2, 0x9f, 
  0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb, 0x8d, 0x01, 0x02, 0x04, 
  0x08, 0x10, 0x20, 0x40, 0x80, 0x1b, 0x36, 0x6c, 0xd8, 0xab, 0x4d, 0x9a, 0x2f, 0x5e, 0xbc, 0x63, 
  0xc6, 0x97, 0x35, 0x6a, 0xd4, 0xb3, 0x7d, 0xfa, 0xef, 0xc5, 0x91, 0x39, 0x72, 0xe4, 0xd3, 0xbd, 
  0x61, 0xc2, 0x9f, 0x25, 0x4a, 0x94, 0x33, 0x66, 0xcc, 0x83, 0x1d, 0x3a, 0x74, 0xe8, 0xcb  
};

// This function produces Nb(ctx[0].Nr+1) round keys. The round keys are used (ctx[0].in) each round to encrypt the states. 
static void aes_KeyExpansion(AESContextT ctx[1],BufferT* key)
{ int i,j;
  unsigned char temp[4],k;
  
  // The first round key is the key itself.
  for(i=0;i<ctx[0].Nk;i++)
  {
    (ctx[0].RoundKey)[i*4]=(key->data)[i*4];
    (ctx[0].RoundKey)[i*4+1]=(key->data)[i*4+1];
    (ctx[0].RoundKey)[i*4+2]=(key->data)[i*4+2];
    (ctx[0].RoundKey)[i*4+3]=(key->data)[i*4+3];
  } // of for
  
  // All other round keys are found from the previous round keys.
  while (i < (Nb * (ctx[0].Nr+1)))
  {
    for(j=0;j<4;j++)
      temp[j]=(ctx[0].RoundKey)[(i-1) * 4 + j];
    
    if (i % ctx[0].Nk == 0)
    {
      // This function rotates the 4 bytes (ctx[0].in) a word to the left once.
      // [a0,a1,a2,a3] becomes [a1,a2,a3,a0]
      
      // Function RotWord()
      {
        k = temp[0];
        temp[0] = temp[1];
        temp[1] = temp[2];
        temp[2] = temp[3];
        temp[3] = k;
      }
      
      // SubWord() is a function that takes a four-byte input word and 
      // applies the S-box to each of the four bytes to produce an output word.
      
      // Function Subword()
      {
        temp[0]=aes_getSBoxValue(temp[0]);
        temp[1]=aes_getSBoxValue(temp[1]);
        temp[2]=aes_getSBoxValue(temp[2]);
        temp[3]=aes_getSBoxValue(temp[3]);
      }
      
      temp[0] =  temp[0] ^ aes_Rcon[i/ctx[0].Nk];
    } // of if
    else if (ctx[0].Nk > 6 && i % ctx[0].Nk == 4)
    {
      // Function Subword()
      {
        temp[0]=aes_getSBoxValue(temp[0]);
        temp[1]=aes_getSBoxValue(temp[1]);
        temp[2]=aes_getSBoxValue(temp[2]);
        temp[3]=aes_getSBoxValue(temp[3]);
      }
    } // of else if
    
    (ctx[0].RoundKey)[i*4+0] = (ctx[0].RoundKey)[(i-ctx[0].Nk)*4+0] ^ temp[0];
    (ctx[0].RoundKey)[i*4+1] = (ctx[0].RoundKey)[(i-ctx[0].Nk)*4+1] ^ temp[1];
    (ctx[0].RoundKey)[i*4+2] = (ctx[0].RoundKey)[(i-ctx[0].Nk)*4+2] ^ temp[2];
    (ctx[0].RoundKey)[i*4+3] = (ctx[0].RoundKey)[(i-ctx[0].Nk)*4+3] ^ temp[3];
    i++;
  }
} // of aes_KeyExpansion()

// This function adds the round key to (ctx[0].state).
// The round key is added to the (ctx[0].state) by an XOR function.
static void aes_AddRoundKey(AESContextT ctx[1],int round) 
{ int i,j;
  
  for(i=0;i<4;i++)
    for(j=0;j<4;j++)
      (ctx[0].state)[j][i] ^= (ctx[0].RoundKey)[round * Nb * 4 + i * Nb + j];
} // of aes_AddRoundKey()


// The aes_SubBytes Function Substitutes the values (ctx[0].in) the
// (ctx[0].state) matrix with values (ctx[0].in) an S-box.
static void aes_SubBytes(AESContextT ctx[1])
{ int i,j;
  
  for(i=0;i<4;i++)
    for(j=0;j<4;j++)
      (ctx[0].state)[i][j] = aes_getSBoxValue((ctx[0].state)[i][j]);
} // of aes_SubBytes()

// The aes_ShiftRows() function shifts the rows (ctx[0].in) the (ctx[0].state) to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
static void aes_ShiftRows(AESContextT ctx[1])
{ unsigned char temp;
  
  // Rotate first row 1 columns to left    
  temp=(ctx[0].state)[1][0];
  (ctx[0].state)[1][0]=(ctx[0].state)[1][1];
  (ctx[0].state)[1][1]=(ctx[0].state)[1][2];
  (ctx[0].state)[1][2]=(ctx[0].state)[1][3];
  (ctx[0].state)[1][3]=temp;
  
  // Rotate second row 2 columns to left    
  temp=(ctx[0].state)[2][0];
  (ctx[0].state)[2][0]=(ctx[0].state)[2][2];
  (ctx[0].state)[2][2]=temp;
  
  temp=(ctx[0].state)[2][1];
  (ctx[0].state)[2][1]=(ctx[0].state)[2][3];
  (ctx[0].state)[2][3]=temp;
  
  // Rotate third row 3 columns to left
  temp=(ctx[0].state)[3][0];
  (ctx[0].state)[3][0]=(ctx[0].state)[3][3];
  (ctx[0].state)[3][3]=(ctx[0].state)[3][2];
  (ctx[0].state)[3][2]=(ctx[0].state)[3][1];
  (ctx[0].state)[3][1]=temp;
} // of aes_ShiftRows()

// The aes_SubBytes Function Substitutes the values (ctx[0].in) the
// (ctx[0].state) matrix with values (ctx[0].in) an S-box.
static void aes_InvSubBytes(AESContextT ctx[1])
{ int i,j;
  
  for(i=0;i<4;i++)
    for(j=0;j<4;j++)
      (ctx[0].state)[i][j] = aes_getSBoxInvert((ctx[0].state)[i][j]);      
} // of aes_InvSubBytes()

// The aes_ShiftRows() function shifts the rows (ctx[0].in) the (ctx[0].state) to the left.
// Each row is shifted with different offset.
// Offset = Row number. So the first row is not shifted.
static void aes_InvShiftRows(AESContextT ctx[1])
{ unsigned char temp;
  
  // Rotate first row 1 columns to right   
  temp=(ctx[0].state)[1][3];
  (ctx[0].state)[1][3]=(ctx[0].state)[1][2];
  (ctx[0].state)[1][2]=(ctx[0].state)[1][1];
  (ctx[0].state)[1][1]=(ctx[0].state)[1][0];
  (ctx[0].state)[1][0]=temp;
  
  // Rotate second row 2 columns to right   
  temp=(ctx[0].state)[2][0];
  (ctx[0].state)[2][0]=(ctx[0].state)[2][2];
  (ctx[0].state)[2][2]=temp;
  
  temp=(ctx[0].state)[2][1];
  (ctx[0].state)[2][1]=(ctx[0].state)[2][3];
  (ctx[0].state)[2][3]=temp;
  
  // Rotate third row 3 columns to right
  temp=(ctx[0].state)[3][0];
  (ctx[0].state)[3][0]=(ctx[0].state)[3][1];
  (ctx[0].state)[3][1]=(ctx[0].state)[3][2];
  (ctx[0].state)[3][2]=(ctx[0].state)[3][3];
  (ctx[0].state)[3][3]=temp;
} // of aes_InvShiftRows()

// xtime is a macro that finds the product of {02} and the argument to xtime modulo {1b}  
#define xtime(x)   ((x<<1) ^ (((x>>7) & 1) * 0x1b))

// Multiplty is a macro used to multiply numbers (ctx[0].in) the field GF(2^8)
#define Multiply(x,y) (((y & 1) * x) ^ ((y>>1 & 1) * xtime(x)) ^ ((y>>2 & 1) * xtime(xtime(x))) ^ ((y>>3 & 1) * xtime(xtime(xtime(x)))) ^ ((y>>4 & 1) * xtime(xtime(xtime(xtime(x))))))

// aes_MixColumns function mixes the columns of the (ctx[0].state) matrix
// The method used may look complicated, but it is easy if you know the underlying theory.
// Refer the documents specified above.
static void aes_MixColumns(AESContextT ctx[1])
{ int           i;
  unsigned char Tmp,Tm,t;
  
  for(i=0;i<4;i++)
  {    
    t=(ctx[0].state)[0][i];
    Tmp = (ctx[0].state)[0][i] ^ (ctx[0].state)[1][i] ^ (ctx[0].state)[2][i] ^ (ctx[0].state)[3][i] ;
    Tm  = (ctx[0].state)[0][i] ^ (ctx[0].state)[1][i] ; Tm = xtime(Tm); (ctx[0].state)[0][i] ^= Tm ^ Tmp ;
    Tm  = (ctx[0].state)[1][i] ^ (ctx[0].state)[2][i] ; Tm = xtime(Tm); (ctx[0].state)[1][i] ^= Tm ^ Tmp ;
    Tm  = (ctx[0].state)[2][i] ^ (ctx[0].state)[3][i] ; Tm = xtime(Tm); (ctx[0].state)[2][i] ^= Tm ^ Tmp ;
    Tm  = (ctx[0].state)[3][i] ^ t ; Tm = xtime(Tm); (ctx[0].state)[3][i] ^= Tm ^ Tmp ;
  } // of for
} // of aes_MixColumns()

// aes_Cipher is the main function that encrypts the PlainText.
static void aes_Cipher(AESContextT ctx[1])
{ int i,j,round=0;
  
  //Copy the input PlainText to (ctx[0].state) array.
  for(i=0;i<4;i++)
    for(j=0;j<4;j++)
      (ctx[0].state)[j][i] = (ctx[0].in)[i*4 + j];
  
  // Add the First round key to the (ctx[0].state) before starting the rounds.
  aes_AddRoundKey(ctx,0); 
  
  // There will be ctx[0].Nr rounds.
  // The first ctx[0].Nr-1 rounds are identical.
  // These ctx[0].Nr-1 rounds are executed (ctx[0].in) the loop below.
  for(round=1;round<ctx[0].Nr;round++)
  { aes_SubBytes(ctx);
    aes_ShiftRows(ctx);
    aes_MixColumns(ctx);
    aes_AddRoundKey(ctx,round);
  } // of for
  
  // The last round is given below.
  // The aes_MixColumns function is not here (ctx[0].in) the last round.
  aes_SubBytes(ctx);
  aes_ShiftRows(ctx);
  aes_AddRoundKey(ctx,ctx[0].Nr);
} // of aes_Cipher()

// aes_MixColumns function mixes the columns of the (ctx[0].state) matrix.
// The method used to multiply may be difficult to understand for beginners.
// Please use the references to gain more information.
static void aes_InvMixColumns(AESContextT ctx[1])
{ int           i;
  unsigned char a,b,c,d;
  
  for(i=0;i<4;i++)
  { a = (ctx[0].state)[0][i];
    b = (ctx[0].state)[1][i];
    c = (ctx[0].state)[2][i];
    d = (ctx[0].state)[3][i];
    
    (ctx[0].state)[0][i] = Multiply(a, 0x0e) ^ Multiply(b, 0x0b) ^ Multiply(c, 0x0d) ^ Multiply(d, 0x09);
    (ctx[0].state)[1][i] = Multiply(a, 0x09) ^ Multiply(b, 0x0e) ^ Multiply(c, 0x0b) ^ Multiply(d, 0x0d);
    (ctx[0].state)[2][i] = Multiply(a, 0x0d) ^ Multiply(b, 0x09) ^ Multiply(c, 0x0e) ^ Multiply(d, 0x0b);
    (ctx[0].state)[3][i] = Multiply(a, 0x0b) ^ Multiply(b, 0x0d) ^ Multiply(c, 0x09) ^ Multiply(d, 0x0e);
  } // of for
} // of aes_InvMixColumns()

// aes_InvCipher is the main function that decrypts the CipherText.
static void aes_InvCipher(AESContextT ctx[1])
{ int i,j,round=0;
  
  //Copy the input CipherText to (ctx[0].state) array.
  for(i=0;i<4;i++)
    for(j=0;j<4;j++)
      (ctx[0].state)[j][i] = (ctx[0].in)[i*4 + j];
  
  // Add the First round key to the (ctx[0].state) before starting the rounds.
  aes_AddRoundKey(ctx,ctx[0].Nr);
  
  // There will be ctx[0].Nr rounds.
  // The first ctx[0].Nr-1 rounds are identical.
  // These ctx[0].Nr-1 rounds are executed (ctx[0].in) the loop below.
  for(round=ctx[0].Nr-1;round>0;round--)
  {  aes_InvShiftRows(ctx);
    aes_InvSubBytes(ctx);
    aes_AddRoundKey(ctx,round);
    aes_InvMixColumns(ctx);
  } // of for
  
  // The last round is given below.
  // The aes_MixColumns function is not here (ctx[0].in) the last round.
  aes_InvShiftRows(ctx);
  aes_InvSubBytes(ctx);
  aes_AddRoundKey(ctx,0);
} // of aes_InvCipher()


/**
 *
 */
int aes_check(AESContextT ctx[1])
{ int result = AES_OK;
  
  if( ctx!=NULL && (ctx[0].magic0!=0xE7E7E7E7 || ctx[0].magic1!=0xC4C4C4C4) )
    result = AES_CORRUPTED;
  else if( ctx==NULL )
    result = AES_FAILURE;
  
  return result;
} /* of aes_check() */

/**
 * key->length = 16(128bit),24(192bit),32(256bit)
 */
int aes_begin  (AESContextT ctx[1],BufferT* key,BufferT* iv)
{ int result = AES_OK;
  
  if( ctx!=NULL && key!=NULL && (key->length==16 || key->length==24 || key->length==32) )
  { memset(ctx,0xE7,sizeof(AESContextT));
    
    // Calculate ctx[0].Nk and ctx[0].Nr from the received value.
    ctx[0].Nk = key->length / 4;
    ctx[0].Nr = ctx[0].Nk + 6;
    
    ctx[0].use_iv = 0;
    
    if( iv!=NULL && iv->length==AES_BLOCK_SIZE )
    { memcpy(ctx[0].iv0,iv->data  ,iv->length);
      memcpy(ctx[0].iv ,ctx[0].iv0,AES_BLOCK_SIZE);
      ctx[0].use_iv = 1;
    } /* of if */

    //The (key)-Expansion routine must be called before the decryption routine.
    aes_KeyExpansion(ctx,key);

    ctx[0].magic1 = 0xC4C4C4C4;
  } // of if
  else
    result = AES_FAILURE;
  
  return result;
} /* of aes_begin() */

/**
 *
 */
int aes_encrypt(AESContextT ctx[1],BufferT* in,BufferT* out)
{ int result = aes_check(ctx);
  
  if( result!=AES_OK )
    return result;
  
  if( in==NULL || in->length<AES_BLOCK_SIZE || out==NULL || out->length<AES_BLOCK_SIZE )
    return AES_FAILURE;
  
  memcpy(ctx[0].in,in->data  ,AES_BLOCK_SIZE);  
  
  if( ctx[0].use_iv )
  { for( int x=0;x<AES_BLOCK_SIZE;x++ )
      ctx[0].in[x] ^= ctx[0].iv[x];
  } /* of if */
  
  // The next function call encrypts the PlainText with the (key) using AES algorithm.
  aes_Cipher(ctx);
  
  if( ctx[0].use_iv )
  { for(int i=0;i<4;i++)
      for(int j=0;j<4;j++)
        ctx[0].iv[i*4+j]=(ctx[0].state)[j][i];
  } /* of if */
  
  for(int i=0;i<4;i++)
    for(int j=0;j<4;j++)
      out->data[i*4+j]=(ctx[0].state)[j][i];
  
  return aes_check(ctx);
} /* of aes_encrypt() */

/**
 *
 */
int aes_decrypt(AESContextT ctx[1],BufferT* in,BufferT* out)
{ int result = aes_check(ctx);
  
  if( result!=AES_OK )
    return result;
  
  if( in==NULL || in->length<AES_BLOCK_SIZE || out==NULL || out->length<AES_BLOCK_SIZE )
    return AES_FAILURE;
  
  memcpy(ctx[0].in,in->data  ,AES_BLOCK_SIZE);
  
  // The next function call decrypts the CipherText with the (key) using AES algorithm.
  aes_InvCipher(ctx);

  if( ctx[0].use_iv )
  { for(int i=0;i<4;i++)
      for(int j=0;j<4;j++)
        (ctx[0].state)[j][i] ^= ctx[0].iv[i*4+j];
  
    memcpy(ctx[0].iv,ctx[0].in,AES_BLOCK_SIZE);
  } /* of if */

  for(int i=0;i<4;i++)
    for(int j=0;j<4;j++)
      out->data[i*4+j]=(ctx[0].state)[j][i];
  
  return aes_check(ctx);
} /* of aes_decrypt() */

/**
 *
 */
int aes_end(AESContextT ctx[1])
{ int result =aes_check(ctx); 
  
  return result;
} /* of aes_end() */
/*============================================================================END-OF-FILE============================================================================*/



