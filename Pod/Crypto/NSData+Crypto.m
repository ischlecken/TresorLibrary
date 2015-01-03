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
#import "NSData+Crypto.h"
#import "CryptoError.h"
#import "Macros.h"

#include "md5.h"
#include "sha1.h"
#include "sha2.h"
#include "aes.h"
#include "twofish.h"
#include "base64.h"
#include "commoncrypto.h"

@implementation NSData(TresorCrypto)

/**
 *
 */
-(NSData*) hashWithAlgorithm:(TresorCryptoHashAlgorithmT)algorithm error:(NSError **)outError
{ BufferT   data;
  NSData*   result          = nil;
  int       internalErrCode = 0;
  
  buffer_init(&data,(unsigned int)[self length],(unsigned char*)[self bytes]);
  
  switch( algorithm )
  { case hashAlgoMD5:
    case hashAlgoMD5CC:
      { BUFFER_T(MD5_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoMD5(&data,(BufferT*)&digest, algorithm==hashAlgoMD5CC );
        
        CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorHash,@"CommonCryptoMD5 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    case hashAlgoSHA1:
    case hashAlgoSHA1CC:
      { BUFFER_T(SHA1_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoSHA1(&data,(BufferT*)&digest, algorithm==hashAlgoSHA1CC);
        
        CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorHash,@"CommonCryptoSHA1 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    case hashAlgoSHA256:
    case hashAlgoSHA256CC:
      { BUFFER_T(SHA256_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoSHA256(&data,(BufferT*)&digest, algorithm==hashAlgoSHA256CC);
        
        CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorHash,@"CommonCryptoSHA256 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    case hashAlgoSHA512:
    case hashAlgoSHA512CC:
      { BUFFER_T(SHA512_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoSHA512(&data,(BufferT*)&digest, algorithm==hashAlgoSHA512CC);
        
        CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorHash,@"CommonCryptoSHA512 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    default:
      break;
  } // of switch

cleanUp:
  
  return result;
} /* of hashWithAlgorithm: */

/**
 *
 */
-(NSData*) encryptWithAlgorithm:(TresorCryptoAlgorithmT)algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError
{ NSData*     result          = nil;
  int         internalErrCode = 0;
  BufferT*    cryptResult     = NULL;
  
  CRYPTO_CHECK_ERROR( key==nil || iv==nil || [key length]==0 || [iv length]==0,CryptoErrorIllegalArgument,@"key and iv should not be nil",0 );
  
  BOOL     useCommonCrypto = FALSE;
  int      (*cryptFkt)(BufferT*,BufferT*,BufferT*,BufferT*,bool) = NULL;
  unsigned blockSize = 0;
  
  switch( algorithm )
  { case cryptAlgoAES128CC:
    case cryptAlgoAES192CC:
    case cryptAlgoAES256CC:
      useCommonCrypto = TRUE;
    case cryptAlgoAES192:
    case cryptAlgoAES256:
    case cryptAlgoAES128:
      blockSize       = AES_BLOCK_SIZE;
      cryptFkt        = CommonCryptoAES128Encrypt;
      break;
    case cryptAlgoCASTCC:
      useCommonCrypto = TRUE;
      blockSize       = CAST_BLOCK_SIZE;
      cryptFkt        = CommonCryptoCASTEncrypt;
      break;
    case cryptAlgoTWOFISH256:
      useCommonCrypto = FALSE;
      blockSize       = TWOFISH_BLOCK_SIZE;
      cryptFkt        = CommonCryptoTwofishEncrypt;
      break;
    default:
      break;
  } // of switch
  
  if( cryptFkt!=NULL && blockSize!=0 )
  { BufferT  keyBuffer;
    BufferT  ivBuffer;
    BufferT  selfBuffer;
    int      cryptResultLen = blockSize * ( (unsigned int)[self length]/blockSize + 1);
    
    cryptResult = buffer_alloc(cryptResultLen, NULL);
    CRYPTO_CHECK_ERROR( cryptResult==NULL,CryptoErrorBufferAlloc,@"buffer_alloc failed",0 );
    
    buffer_init(&keyBuffer , (unsigned int)[key  length], (unsigned char*)[key  bytes]);
    buffer_init(&ivBuffer  , (unsigned int)[iv   length], (unsigned char*)[iv   bytes]);
    buffer_init(&selfBuffer, (unsigned int)[self length], (unsigned char*)[self bytes]);
    
    internalErrCode = cryptFkt(&selfBuffer, &keyBuffer, &ivBuffer, cryptResult, useCommonCrypto);
    CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorCipher,@"encryption failed",internalErrCode );
    
    result = [[NSData alloc] initWithBytes:cryptResult->data length:cryptResult->length];
  } /* of if */
  
cleanUp:
  free(cryptResult);
  
  return result;  
} /* of encryptWithAlgorithm: */

/**
 *
 */
- (NSData*) decryptWithAlgorithm:(TresorCryptoAlgorithmT) algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError
{ NSData*     result          = nil;
  BufferT*    decryptResult   = NULL;
  int         internalErrCode = 0;
  
  CRYPTO_CHECK_ERROR( key==nil || iv==nil || [key length]==0 || [iv length]==0,CryptoErrorIllegalArgument,@"key and iv should not be nil",0 );
  
  BOOL     useCommonCrypto = FALSE;
  int      (*decryptFkt)(BufferT*,BufferT*,BufferT*,BufferT*,bool) = NULL;
  unsigned blockSize = 0;
  
  switch( algorithm )
  { case cryptAlgoAES128CC:
    case cryptAlgoAES192CC:
    case cryptAlgoAES256CC:
      useCommonCrypto = TRUE;
    case cryptAlgoAES128:
    case cryptAlgoAES192:
    case cryptAlgoAES256:
      blockSize       = AES_BLOCK_SIZE;
      decryptFkt      = CommonCryptoAES128Decrypt;
      break;
    case cryptAlgoCASTCC:
      useCommonCrypto = TRUE;
      blockSize       = CAST_BLOCK_SIZE;
      decryptFkt      = CommonCryptoCASTDecrypt;
      break;
    case cryptAlgoTWOFISH256:
      useCommonCrypto = FALSE;
      blockSize       = TWOFISH_BLOCK_SIZE;
      decryptFkt      = CommonCryptoTwofishDecrypt;
      break;
    default:
      break;
  } // of switch
  
  if( decryptFkt!=NULL && blockSize!=0 )
  { BufferT  keyBuffer;
    BufferT  ivBuffer;
    BufferT  selfBuffer;
    int      decryptResultLen = (unsigned int)[self length];
    
    CRYPTO_CHECK_ERROR( decryptResultLen%blockSize!=0,CryptoErrorPadding,@"invalid padding",0 );
    
    decryptResult = buffer_alloc(decryptResultLen, NULL);
    CRYPTO_CHECK_ERROR( decryptResult==NULL,CryptoErrorBufferAlloc,@"buffer_alloc failed",0 );
    
    buffer_init(&keyBuffer , (unsigned int)[key  length], (unsigned char*)[key  bytes]);
    buffer_init(&ivBuffer  , (unsigned int)[iv   length], (unsigned char*)[iv   bytes]);
    buffer_init(&selfBuffer, (unsigned int)[self length], (unsigned char*)[self bytes]);
    
    internalErrCode = decryptFkt(&selfBuffer, &keyBuffer, &ivBuffer, decryptResult, useCommonCrypto);
    CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorCipher,@"decryption failed",internalErrCode );
    
    result = [[NSData alloc] initWithBytes:decryptResult->data length:decryptResult->length];
  } /* of if */
  
cleanUp:  
  free(decryptResult);
  
  return result;  
} /* of decryptWithAlgorithm: */

/**
 *
 */
-(NSData*)   deriveKeyWithAlgorithm:(TresorCryptoDeriveKeyAlgorithmT)algorithm withLength:(NSUInteger)keyLength usingSalt:(NSData*)salt andIterations:(NSUInteger)iter error:(NSError **)outError
{ NSData*     result          = nil;
  BufferT*    keyResult       = NULL;
  int         internalErrCode = 0;
  
  CRYPTO_CHECK_ERROR( salt==nil || [salt length]==0,CryptoErrorIllegalArgument,@"salt should not be nil",0 );
  
  switch( algorithm )
  { case deriveKeyAlgoPBKDF2:
    case deriveKeyAlgoPBKDF2CC:
    { BufferT  selfBuffer;
      BufferT  saltBuffer;
      int      keyResultLen = (unsigned int)keyLength;
      
      keyResult = buffer_alloc(keyResultLen, NULL);
      CRYPTO_CHECK_ERROR( keyResult==NULL,CryptoErrorBufferAlloc,@"buffer_alloc failed",0 );
      
      buffer_init(&selfBuffer, (unsigned int)[self length], (unsigned char*)[self bytes]);
      buffer_init(&saltBuffer, (unsigned int)[salt length], (unsigned char*)[salt bytes]);
      
      internalErrCode = CommonCryptoDeriveKey(&selfBuffer,&saltBuffer,keyResult,(unsigned int)iter,algorithm==deriveKeyAlgoPBKDF2CC);
      CRYPTO_CHECK_ERROR( internalErrCode!=EXIT_SUCCESS,CryptoErrorCipher,@"CommonCryptoDeriveKey failed",internalErrCode );
      
      result = [[NSData alloc] initWithBytes:keyResult->data length:keyResult->length];
    }
      break;
    default:
      break;
  } // of switch
  
cleanUp:  
  free(keyResult);
  
  return result;  
} /* of deriveKeyWithAlgorithm: */

/**
 *
 */
-(NSData*) mirror
{ const UInt8*   bytes       = self.bytes;
  NSUInteger     bytesLength = self.length;
  UInt8*         data        = (UInt8*)calloc(bytesLength, 1);
  
  for( NSUInteger i=0;i<bytesLength;i++ )
    data[bytesLength-1-i] = bytes[i];
  
  return [[NSData alloc] initWithBytes:(const void*)data length:bytesLength];
}

/**
 *
 */
-(instancetype) initWithHexString:(const char*)hexString
{ if( hexString==NULL )
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"hexString should not be NULL" userInfo:nil];
  
  unsigned int   len    = (unsigned int)strlen(hexString);
  unsigned char* buffer = NULL;
  
  if( len%2!=0 )
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"hexString should have an even length" userInfo:nil];
  
  if( len>0 )
  { unsigned char digit[3];
    
    memset(digit,0,3);
    
    buffer = calloc(len/2+1,1);
    
    if( buffer!=NULL )
      for( int i=0;i<len/2;i++ )
      { digit[0]  = hexString[2*i];
        digit[1]  = hexString[2*i+1];
        buffer[i] = (unsigned char)strtol((char*)digit, NULL, 16);
      } /* of for */
  } /* of if */
  
  if( buffer!=NULL )
    self = [self initWithBytesNoCopy:buffer length:len/2];
  else 
    self = [self init];
  
  return self;
}

/**
 *
 */
-(instancetype) initWithUTF8String:(NSString*)string
{ const char* utf8Str = [string UTF8String];
  int         utf8Len = (unsigned int)strlen(utf8Str);
  
  if( utf8Str!=NULL )
    self = [self initWithBytes:utf8Str length:utf8Len];
  else 
    self = [self init];
  
  return self;
}

/**
 *
 */
-(instancetype) initWithRandom:(NSUInteger)length
{ if( length==0 )
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"length should not be 0" userInfo:nil];
  
  BufferT* randomBuffer = buffer_alloc((unsigned int)length, BUFFER_RANDOM);
  
  if( randomBuffer!=NULL )
    self = [self initWithBytes:randomBuffer->data length:randomBuffer->length];
  
  free(randomBuffer);
  
  if( randomBuffer==NULL )
    @throw [NSException exceptionWithName:NSMallocException reason:@"could not init random data" userInfo:nil];
  
  return self;
}


/**
 *
 */
+(NSData*) dataWithHexString:(const char*)hexString
{ return [[NSData alloc] initWithHexString:hexString]; }

/**
 *
 */
+(NSData*) dataWithUTF8String:(NSString*)string
{ return [[NSData alloc] initWithUTF8String:string]; }

/**
 *
 */
+(NSData*) dataWithRandom:(NSUInteger)length
{ return [[NSData alloc] initWithRandom:length]; }

/**
 *
 */
-(NSString*) hexStringValue
{ NSString*      result = nil; 
  int            bLen   = (unsigned int)[self length];
  unsigned char* buffer = (unsigned char*)[self bytes];
  char*          b      = NULL;
  
  if( bLen>0 )
  { b = calloc(bLen*2+1,1);
    if( b==NULL )
      goto cleanUp;
    
    for( int i=0;i<bLen;i++ )
    { unsigned char c = buffer[i];
      
      b[2*i]   = 0x30 + ((c>>4)&0x0f);
      if( b[2*i]>0x39 )
        b[2*i] = 'A' + ( b[2*i]-0x30-0xA );
      
      b[2*i+1] = 0x30 + (c&0x0f); 
      if( b[2*i+1]>0x39 )
        b[2*i+1] = 'A' + ( b[2*i+1]-0x30-0xA );
    } /* of for */
    
    result = [[NSString alloc] initWithUTF8String:b];
  } /* of if */
cleanUp:
  
  free(b);
  
  return result;
}

/**
 *
 */
+(PMKPromise*) generatePINWithLength:(NSUInteger)pinLength
{ _NSLOG_SELECTOR;
  
  PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject)
  {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^
    { _NSLOG(@"generatePINWithLength.start");
      
      NSData*    passwordData = [NSData dataWithRandom:pinLength];
      NSData*    salt         = [NSData dataWithRandom:pinLength];
      NSUInteger iter         = 2000000;
      NSError*   error        = nil;
      
#if TARGET_IPHONE_SIMULATOR
      iter *= 4;
#endif
      
      NSData*   derivedKey = [passwordData deriveKeyWithAlgorithm:deriveKeyAlgoPBKDF2CC
                                                       withLength:pinLength
                                                        usingSalt:salt
                                                    andIterations:iter
                                                            error:&error];
      
      NSString* pin        = [[derivedKey hexStringValue] substringToIndex:pinLength];
      _NSLOG(@"generatePINWithLength.stop:");
      
      if( derivedKey )
        fulfill(PMKManifold(pin,[NSNumber numberWithUnsignedInteger:iter],salt,@"PBKDF2CC"));
      else
        reject(error);
    });
  }];
  
  return result;
}

@end
/*====================================================END-OF-FILE==========================================================*/
