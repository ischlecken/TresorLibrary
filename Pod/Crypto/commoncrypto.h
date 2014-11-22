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
#ifndef COMMONCRYPTO_H
#define COMMONCRYPTO_H

#include "buffer.h"

int CommonCryptoMD5   (BufferT* in,BufferT* digest,bool useCommon);
int CommonCryptoSHA1  (BufferT* in,BufferT* digest,bool useCommon);
int CommonCryptoSHA256(BufferT* in,BufferT* digest,bool useCommon);
int CommonCryptoSHA512(BufferT* in,BufferT* digest,bool useCommon);

int CommonCryptoAES128Encrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon);
int CommonCryptoAES128Decrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon);
int CommonCryptoCASTEncrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon);
int CommonCryptoCASTDecrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon);
int CommonCryptoTwofishEncrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon);
int CommonCryptoTwofishDecrypt(BufferT* in,BufferT* key,BufferT* iv,BufferT* out,bool useCommon);
int CommonCryptoRandomData(BufferT* data);
int CommonCryptoDeriveKey(BufferT* pwd,BufferT* salt,BufferT* key,unsigned int iter,bool useCommon);
#endif
/*====================================================END-OF-FILE============================================*/
