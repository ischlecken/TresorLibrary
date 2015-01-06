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
#import "TresorError.h"
#import "Macros.h"
#import "JSONModel.h"
#import "NSString+Date.h"

#include "md5.h"
#include "sha1.h"
#include "sha2.h"
#include "aes.h"
#include "twofish.h"
#include "base64.h"
#include "commoncrypto.h"

#define kTagSize0     0x00
#define kTagSize8     0x01
#define kTagSize16    0x02
#define kTagSize32    0x03
#define kTagSizeMask  0x03

typedef NS_ENUM(UInt8, CryptoTagTypes)
{ CryptoTagDummy             = (0x00    <<2) + kTagSize0 , // 0x00
  CryptoTagRandomPadding     = (0x01    <<2) + kTagSize8 , // 0x05
  CryptoTagRandomPaddingHash = (0x02    <<2) + kTagSize8 , // 0x09
  CryptoTagPayload32         = (0x03    <<2) + kTagSize32, // 0x0F
  CryptoTagPayload16         = (0x04    <<2) + kTagSize16, // 0x12
  CryptoTagPayload8          = (0x05    <<2) + kTagSize8 , // 0x15

  CryptoTagPayloadClassName  = ((0x30+0)<<2) + kTagSize8 , // 0xC3
  CryptoTagPayloadNSString   = ((0x30+1)<<2) + kTagSize0 , // 0xC4
  CryptoTagPayloadNSData     = ((0x30+2)<<2) + kTagSize0   // 0xC8
};


#define _USE_JSONMODEL

@implementation JSONValueTransformer (CustomTransformer)

- (NSDate *)NSDateFromNSString:(NSString*)string
{ return [NSString rfc3339TimestampValue:string]; }

- (NSString *)JSONObjectFromNSDate:(NSDate *)date
{ return [NSString stringRFC3339TimestampForDate:date]; }

@end


@implementation GeneratedPIN
@end

@implementation NSData(TresorCrypto)

/**
 *
 */
-(NSData*) hashWithAlgorithm:(TresorAlgorithmInfo*)algorithm error:(NSError **)outError
{ BufferT   data;
  NSData*   result          = nil;
  int       internalErrCode = 0;
  
  buffer_init(&data,(unsigned int)[self length],(unsigned char*)[self bytes]);
  
  switch( algorithm.type )
  { case tresorAlgorithmMD5:
    case tresorAlgorithmMD5CC:
      { BUFFER_T(MD5_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoMD5(&data,(BufferT*)&digest, algorithm.type==tresorAlgorithmMD5CC );
        
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoMD5 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    case tresorAlgorithmSHA1:
    case tresorAlgorithmSHA1CC:
      { BUFFER_T(SHA1_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoSHA1(&data,(BufferT*)&digest, algorithm.type==tresorAlgorithmSHA1CC);
        
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoSHA1 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    case tresorAlgorithmSHA256:
    case tresorAlgorithmSHA256CC:
      { BUFFER_T(SHA256_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoSHA256(&data,(BufferT*)&digest, algorithm.type==tresorAlgorithmSHA256CC);
        
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoSHA256 failed",internalErrCode );
        
        result = [[NSData alloc] initWithBytes:digest.data length:digest.length];
      }
      break;
    case tresorAlgorithmSHA512:
    case tresorAlgorithmSHA512CC:
      { BUFFER_T(SHA512_DIGEST_SIZE,digest);
        
        internalErrCode = CommonCryptoSHA512(&data,(BufferT*)&digest, algorithm.type==tresorAlgorithmSHA512CC);
        
        TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorHash,@"CommonCryptoSHA512 failed",internalErrCode );
        
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
-(NSData*) encryptWithAlgorithm:(TresorAlgorithmInfo*)algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError
{ NSData*     result          = nil;
  int         internalErrCode = 0;
  BufferT*    cryptResult     = NULL;
  
  TRESOR_CHECKERROR( key==nil || iv==nil || [key length]==0 || [iv length]==0,TresorErrorIllegalArgument,@"key and iv should not be nil",0 );
  
  BOOL     useCommonCrypto = FALSE;
  int      (*cryptFkt)(BufferT*,BufferT*,BufferT*,BufferT*,bool) = NULL;
  unsigned blockSize = 0;
  
  switch( algorithm.type )
  { case tresorAlgorithmAES128CC:
    case tresorAlgorithmAES192CC:
    case tresorAlgorithmAES256CC:
      useCommonCrypto = TRUE;
    case tresorAlgorithmAES192:
    case tresorAlgorithmAES256:
    case tresorAlgorithmAES128:
      blockSize       = algorithm.blockSize;
      cryptFkt        = CommonCryptoAES128Encrypt;
      break;
    case tresorAlgorithmCASTCC:
      useCommonCrypto = TRUE;
      blockSize       = algorithm.blockSize;
      cryptFkt        = CommonCryptoCASTEncrypt;
      break;
    case tresorAlgorithmTwofish256:
      useCommonCrypto = FALSE;
      blockSize       = algorithm.blockSize;
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
    TRESOR_CHECKERROR( cryptResult==NULL,TresorErrorBufferAlloc,@"buffer_alloc failed",0 );
    
    buffer_init(&keyBuffer , (unsigned int)[key  length], (unsigned char*)[key  bytes]);
    buffer_init(&ivBuffer  , (unsigned int)[iv   length], (unsigned char*)[iv   bytes]);
    buffer_init(&selfBuffer, (unsigned int)[self length], (unsigned char*)[self bytes]);
    
    internalErrCode = cryptFkt(&selfBuffer, &keyBuffer, &ivBuffer, cryptResult, useCommonCrypto);
    TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorCipher,@"encryption failed",internalErrCode );
    
    result = [[NSData alloc] initWithBytes:cryptResult->data length:cryptResult->length];
  } /* of if */
  
cleanUp:
  free(cryptResult);
  
  return result;  
} /* of encryptWithAlgorithm: */

/**
 *
 */
- (NSData*) decryptWithAlgorithm:(TresorAlgorithmInfo*) algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError
{ NSData*     result          = nil;
  BufferT*    decryptResult   = NULL;
  int         internalErrCode = 0;
  
  TRESOR_CHECKERROR( key==nil || iv==nil || [key length]==0 || [iv length]==0,TresorErrorIllegalArgument,@"key and iv should not be nil",0 );
  
  BOOL     useCommonCrypto = FALSE;
  int      (*decryptFkt)(BufferT*,BufferT*,BufferT*,BufferT*,bool) = NULL;
  unsigned blockSize = 0;
  
  switch( algorithm.type )
  { case tresorAlgorithmAES128CC:
    case tresorAlgorithmAES192CC:
    case tresorAlgorithmAES256CC:
      useCommonCrypto = TRUE;
    case tresorAlgorithmAES128:
    case tresorAlgorithmAES192:
    case tresorAlgorithmAES256:
      blockSize       = algorithm.blockSize;
      decryptFkt      = CommonCryptoAES128Decrypt;
      break;
    case tresorAlgorithmCASTCC:
      useCommonCrypto = TRUE;
      blockSize       = algorithm.blockSize;
      decryptFkt      = CommonCryptoCASTDecrypt;
      break;
    case tresorAlgorithmTwofish256:
      useCommonCrypto = FALSE;
      blockSize       = algorithm.blockSize;
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
    
    TRESOR_CHECKERROR( decryptResultLen%blockSize!=0,TresorErrorPadding,@"invalid padding",0 );
    
    decryptResult = buffer_alloc(decryptResultLen, NULL);
    TRESOR_CHECKERROR( decryptResult==NULL,TresorErrorBufferAlloc,@"buffer_alloc failed",0 );
    
    buffer_init(&keyBuffer , (unsigned int)[key  length], (unsigned char*)[key  bytes]);
    buffer_init(&ivBuffer  , (unsigned int)[iv   length], (unsigned char*)[iv   bytes]);
    buffer_init(&selfBuffer, (unsigned int)[self length], (unsigned char*)[self bytes]);
    
    internalErrCode = decryptFkt(&selfBuffer, &keyBuffer, &ivBuffer, decryptResult, useCommonCrypto);
    TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorCipher,@"decryption failed",internalErrCode );
    
    result = [[NSData alloc] initWithBytes:decryptResult->data length:decryptResult->length];
  } /* of if */
  
cleanUp:  
  free(decryptResult);
  
  return result;  
} /* of decryptWithAlgorithm: */

/**
 *
 */
-(NSData*)   deriveKeyWithAlgorithm:(TresorAlgorithmInfo*)algorithm withLength:(NSUInteger)keyLength usingSalt:(NSData*)salt andIterations:(NSUInteger)iter error:(NSError **)outError
{ NSData*     result          = nil;
  BufferT*    keyResult       = NULL;
  int         internalErrCode = 0;
  
  TRESOR_CHECKERROR( salt==nil || [salt length]==0,TresorErrorIllegalArgument,@"salt should not be nil",0 );
  
  switch( algorithm.type )
  { case tresorAlgorithmPBKDF2:
    case tresorAlgorithmPBKDF2CC:
    { BufferT  selfBuffer;
      BufferT  saltBuffer;
      int      keyResultLen = (unsigned int)keyLength;
      
      keyResult = buffer_alloc(keyResultLen, NULL);
      TRESOR_CHECKERROR( keyResult==NULL,TresorErrorBufferAlloc,@"buffer_alloc failed",0 );
      
      buffer_init(&selfBuffer, (unsigned int)[self length], (unsigned char*)[self bytes]);
      buffer_init(&saltBuffer, (unsigned int)[salt length], (unsigned char*)[salt bytes]);
      
      internalErrCode = CommonCryptoDeriveKey(&selfBuffer,&saltBuffer,keyResult,(unsigned int)iter,algorithm.type==tresorAlgorithmPBKDF2CC);
      TRESOR_CHECKERROR( internalErrCode!=EXIT_SUCCESS,TresorErrorCipher,@"CommonCryptoDeriveKey failed",internalErrCode );
      
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
      
      NSData*   derivedKey = [passwordData deriveKeyWithAlgorithm:[TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmPBKDF2CC]
                                                       withLength:pinLength
                                                        usingSalt:salt
                                                    andIterations:iter
                                                            error:&error];
      
      NSString* pin        = [[derivedKey hexStringValue] substringToIndex:pinLength];
      _NSLOG(@"generatePINWithLength.stop:");
      
      if( derivedKey )
      { GeneratedPIN* result = [GeneratedPIN new];
        
        result.pin        = pin;
        result.salt       = salt;
        result.algorithm  = @"PBKDF2CC";
        result.iterations = iter;
        
        fulfill(result);
      } /* of if */
      else
        reject(error);
    });
  }];
  
  return result;
}

#pragma mark payload encryption decryption

/**
 *
 */
+(id) decryptPayload:(NSData*)payload usingAlgorithm:(TresorAlgorithmInfo*)algorithm andDecryptedKey:(NSData*)decryptedKey andCryptoIV:(NSData*)cryptoIV andError:(NSError**)error
{ id result = nil;
  
  if( algorithm )
  { NSData* decryptedPayload  = [payload decryptWithAlgorithm:algorithm usingKey:decryptedKey andIV:cryptoIV error:error];
    
    if( decryptedPayload )
    { decryptedPayload = [decryptedPayload mirror];
      
      const void* rawData           = [decryptedPayload bytes];
      NSUInteger  rawDataSize       = [decryptedPayload length];
      const void* rawDataEnd        = rawData+rawDataSize;
      NSString*   payloadClassName  = nil;
      NSData*     payloadData       = nil;
      NSData*     randomPadding     = nil;
      NSData*     randomPaddingHash = nil;
      
      while( rawData<rawDataEnd )
      { UInt8       tag           = *((UInt8*)rawData);
        UInt8       tagSizeLength = tag & kTagSizeMask;
        UInt32      tagSize       = 0;
        const void* tagData       = nil;
        
        rawData++;
        
        switch ( tagSizeLength )
        { case kTagSize0:
            break;
          case kTagSize8:
            tagSize  = *((UInt8*)rawData);
            rawData += sizeof(UInt8);
            break;
          case kTagSize16:
            tagSize  = CFSwapInt16LittleToHost( *((UInt16*)rawData) );
            rawData += sizeof(UInt16);
            break;
          case kTagSize32:
            tagSize  = CFSwapInt32LittleToHost( *((UInt32*)rawData) );
            rawData += sizeof(UInt32);
            break;
          default:
            break;
        } /* of switch */
        
        tagData  = rawData;
        rawData += tagSize;

        NSLog(@"tag[%d,%d]",(unsigned int)tag,(unsigned int)tagSize);
        
        switch( tag )
        { case CryptoTagPayloadClassName:
            payloadClassName = [[NSString alloc] initWithBytes:tagData length:tagSize encoding:NSUTF8StringEncoding];
            break;
          case CryptoTagPayloadNSData:
            payloadClassName = @"NSData";
            break;
          case CryptoTagPayloadNSString:
            payloadClassName = @"NSString";
            break;
          case CryptoTagPayload32:
          case CryptoTagPayload16:
          case CryptoTagPayload8:
            payloadData = [NSData dataWithBytes:tagData length:tagSize];
            break;
          case CryptoTagRandomPadding:
            randomPadding = [NSData dataWithBytes:tagData length:tagSize];
            break;
          case CryptoTagRandomPaddingHash:
            randomPaddingHash = [NSData dataWithBytes:tagData length:tagSize];
            break;
        } /* of switch */
      } /* of while */
      
      if( randomPadding==nil || randomPaddingHash==nil )
      { *error = _TRESORERROR(TresorErrorNoPaddingFound);
        
        goto cleanup;
      } /* of if */

      if( payloadClassName==nil )
      { *error = _TRESORERROR(TresorErrorNoPayloadClassNameFound);
        
        goto cleanup;
      } /* of if */

      if( payloadData==nil )
      { *error = _TRESORERROR(TresorErrorNoPayloadDataFound);
        
        goto cleanup;
      } /* of if */

      NSData* calcRandomPaddingHash = [randomPadding hashWithAlgorithm:[TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmSHA256CC] error:error];
      
      if( calcRandomPaddingHash==nil || ![calcRandomPaddingHash isEqualToData:randomPaddingHash] )
      { *error = _TRESORERROR(TresorErrorPaddingHashMismatch);
        
        goto cleanup;
      } /* of if */
      
      if( payloadClassName && payloadData )
      { //NSLog(@"payloadClassName:%@ payloadData=<%@>",payloadClassName,[[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding]);
        
        Class payloadClass = NSClassFromString(payloadClassName);
        
        if( [payloadClass isSubclassOfClass:[NSString class]] )
          result = [[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding];
        else if( [payloadClass isSubclassOfClass:[NSData class]] )
          result = payloadData;
        else if( [payloadClass isSubclassOfClass:[JSONModel class]] )
          result = [[payloadClass alloc] initWithData:payloadData error:error];
        
        if( result==nil )
        { *error = _TRESORERROR(TresorErrorCouldNotDeserializePayload);
          
          goto cleanup;
        } /* of if */
        
      } /* of if */
    } /* of if */
  } /* of if */
  
cleanup:
  
  return result;
}


/**
 *
 */
+(NSData*) encryptPayload:(id)payloadObject usingAlgorithm:(TresorAlgorithmInfo*)algorithm andDecryptedKey:(NSData*)decryptedKey andCryptoIV:(NSData*)cryptoIV andError:(NSError**)error
{ NSData* result = nil;
  
  if( payloadObject )
  { NSData* rawPayload = nil;
    
    NSMutableData* rw                 = [[NSMutableData alloc] initWithCapacity:1024];
    Class          payloadObjectClass = [payloadObject class];
    NSData*        payloadObjectData  = nil;
    
    if( [payloadObject isKindOfClass:[NSString class]] )
    { payloadObjectClass = [NSString class];
      payloadObjectData  = [(NSString*)payloadObject dataUsingEncoding:NSUTF8StringEncoding];
    } /* of else if */
    else if( [payloadObject isKindOfClass:[NSData class]] )
    { payloadObjectClass = [NSData class];
      payloadObjectData  = payloadObject;
    } /* of else if */
    else if( [payloadObject isKindOfClass:[JSONModel class]] )
      payloadObjectData = [[payloadObject toJSONString] dataUsingEncoding:NSUTF8StringEncoding];
    
    if( payloadObjectData==nil )
    { *error = _TRESORERROR(TresorErrorCouldNotSerializePayload);
      
      goto cleanup;
    } /* of if */
    
    NSLog(@"payload[%@]:%@",payloadObjectClass,[payloadObjectData hexStringValue]);
    
    NSData* randomPadding     = [NSData dataWithRandom:127];
    NSLog(@"randomPadding[%@]",[randomPadding hexStringValue]);
    
    NSData* randomPaddingHash = [randomPadding hashWithAlgorithm:[TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmSHA256CC] error:error];
    NSLog(@"randomPaddingHash[%@]",[randomPaddingHash hexStringValue]);
    
    if( randomPaddingHash )
    { [NSData addTag:CryptoTagPayloadClassName  andClass:payloadObjectClass toResult:rw];
      [NSData addTag:CryptoTagPayload32         andData:payloadObjectData   toResult:rw];
      [NSData addTag:CryptoTagRandomPaddingHash andData:randomPaddingHash   toResult:rw];
      [NSData addTag:CryptoTagRandomPadding     andData:randomPadding       toResult:rw];
      
      rawPayload = [rw mirror];
      NSLog(@"rawPayload[%@]",[rawPayload hexStringValue]);
      
      if( rawPayload )
      { result = [rawPayload encryptWithAlgorithm:algorithm usingKey:decryptedKey andIV:cryptoIV error:error];
      
        NSLog(@"result[%@]",[result hexStringValue]);
      } /* of if */
    } /* of if */
  } /* of if */
  
cleanup:
  
  return result;
}

/**
 *
 */
+(void) addTag:(UInt8)tag andData:(NSData*)tagData toResult:(NSMutableData*)result
{ UInt32  tagSize32 = 0;
  UInt16  tagSize16 = 0;
  UInt8   tagSize8  = 0;
  
  if( tag==CryptoTagPayload32 && tagData )
  {
    if( tagData.length<256 )
      tag = CryptoTagPayload8;
    else if( tagData.length<65536 )
      tag = CryptoTagPayload16;
  } /* of if */

  [result appendBytes:&tag length:sizeof(tag)];
  
  if( tagData )
  { UInt8 tagSize = tag&kTagSizeMask;
    
    switch( tagSize )
    {
      case kTagSize0:
        break;
      case kTagSize8:
        tagSize8 = (UInt8)tagData.length;
        [result appendBytes:&tagSize8 length:sizeof(tagSize8)];
        break;
      case kTagSize16:
        tagSize16 = CFSwapInt16HostToLittle( (UInt16)tagData.length );
        [result appendBytes:&tagSize16 length:sizeof(tagSize16)];
        break;
      case kTagSize32:
        tagSize32 = CFSwapInt32HostToLittle( (UInt32)tagData.length );
        [result appendBytes:&tagSize32 length:sizeof(tagSize32)];
        break;
    } /* of switch */
  
    [result appendData:tagData];
  } /* of if */
}

/**
 *
 */
+(void) addTag:(UInt32)tag andString:(NSString*)tagString toResult:(NSMutableData*)result
{ NSData* tagData = [tagString dataUsingEncoding:NSUTF8StringEncoding];
  
  [NSData addTag:tag andData:tagData toResult:result];
}

/**
 *
 */
+(void) addTag:(UInt32)tag andClass:(Class)classObject toResult:(NSMutableData*)result
{ NSData* tagData = nil;
  
  if( [classObject isSubclassOfClass:[NSString class]] )
    tag = CryptoTagPayloadNSString;
  else if( [classObject isSubclassOfClass:[NSData class]] )
    tag = CryptoTagPayloadNSData;
  else
    tagData = [NSStringFromClass(classObject) dataUsingEncoding:NSUTF8StringEncoding];
  
  [NSData addTag:tag andData:tagData toResult:result];
}

@end
/*====================================================END-OF-FILE==========================================================*/
