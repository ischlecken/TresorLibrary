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

extern NSString* const CryptoErrorDomain;
extern NSString* const CryptoErrorCoreDomain;


enum
{ CryptoErrorUnknown         = -1,
  CryptoErrorPadding         = -2,
  CryptoErrorBufferAlloc     = -3,
  CryptoErrorBuffer          = -4,
  CryptoErrorHash            = -5,
  CryptoErrorBase64          = -6,
  CryptoErrorCipher          = -7,
  CryptoErrorIllegalArgument = -8,
  CryptoErrorKeyRequest      = -9
};

#define CRYPTO_CHECK_ERROR( condition,errCode,description,intErrCode ) \
  if( condition ) \
  { createCryptoError(outError, errCode, description,intErrCode); \
    \
    goto cleanUp; \
  }

void createCryptoError(NSError** outError,int errCode,NSString* description,int internalErrCode);
/*============================================================================END-OF-FILE============================================================================*/
