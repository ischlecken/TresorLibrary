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
 * Copyright (c) 2014 ischlecken.
 */
#import "CryptoService.h"
#import "DecryptedObjectCache.h"
#import "TresorModel.h"
 
#import "TresorDaoCategories.h"
#import "JSONModel.h"
#import "NSString+Date.h"
#import "NSData+Crypto.h"
#import "TresorUtilConstant.h"
#import "NSString+Crypto.h"

typedef NS_ENUM(UInt32, CryptoServiceTagTypes)
{ CryptoServiceTagDummy=0,
  CryptoServiceTagPayloadClassName=1,
  CryptoServiceTagPayload=2,
  CryptoServiceTagPayloadHash=3
};

//#define _USE_CRYPTO
#define _USE_JSONMODEL

@implementation JSONValueTransformer (CustomTransformer)

- (NSDate *)NSDateFromNSString:(NSString*)string
{ return [NSString rfc3339TimestampValue:string]; }

- (NSString *)JSONObjectFromNSDate:(NSDate *)date
{ return [NSString stringRFC3339TimestampForDate:date]; }

@end


@implementation CryptoService

/**
 *
 */
+(CryptoService*) sharedInstance
{ static CryptoService*   _inst = nil;
  static dispatch_once_t  oncePredicate;
  
  dispatch_once(&oncePredicate, ^{ _inst = [self new]; });
  
  return _inst;
}


/**
 *
 */
+(id) decryptPayloadUsing:(NSData*)payload usingKey:(Key*)keyForPayload andDecryptedKey:(NSData*)decryptedKey andError:(NSError**)error
{ id result = nil;
  
  if( payload && keyForPayload )
  {
#ifdef _USE_CRYPTO
    VaultAlgorithmT vat               = getVaultAlgorithm(keyForPayload.payloadalgorithm);
    AlgorithmInfoT  vai               = VaultAlgorithmInfo[vat];
    NSData*         decryptedPayload  = [payload decryptWithAlgorithm:vai.cryptoAlgorithm usingKey:decryptedKey andIV:[keyForPayload.payloadiv hexString2RawValue] error:error];
#else
    NSData*         decryptedPayload  = payload;
#endif
    
    if( decryptedPayload )
    {
      decryptedPayload = [decryptedPayload mirror];
      
#ifdef _USE_JSONMODEL
      const void* rawData          = [decryptedPayload bytes];
      NSUInteger  rawDataSize      = [decryptedPayload length];
      NSUInteger  i                = 0;
      NSString*   payloadClassName = nil;
      NSData*     payloadData      = nil;
      
      while( i<rawDataSize )
      { UInt32      tag     = CFSwapInt32LittleToHost( *((UInt32*)(rawData+i))                  );
        UInt32      tagSize = CFSwapInt32LittleToHost( *((UInt32*)(rawData+i+1*sizeof(UInt32))) );
        const void* tagData =                                     (rawData+i+2*sizeof(UInt32));
        
        //NSLog(@"tag[%d,%d]",(unsigned int)tag,(unsigned int)tagSize);
        
        if( tag==CryptoServiceTagPayloadClassName )
          payloadClassName = [[NSString alloc] initWithBytes:tagData length:tagSize encoding:NSUTF8StringEncoding];
        else if( tag==CryptoServiceTagPayload )
          payloadData = [NSData dataWithBytes:tagData length:tagSize];
        
        i += tagSize+sizeof(UInt32)+sizeof(UInt32);
      } /* of while */
      
      if( payloadClassName && payloadData )
      { //NSLog(@"payloadClassName:%@ payloadData=<%@>",payloadClassName,[[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding]);
        
        Class    payloadClass = NSClassFromString(payloadClassName);
        NSError* error        = nil;
        
        if( [payloadClass isSubclassOfClass:[NSString class]] )
          result = [[NSString alloc] initWithData:payloadData encoding:NSUTF8StringEncoding];
        else if( [payloadClass isSubclassOfClass:[JSONModel class]] )
          result = [[payloadClass alloc] initWithData:payloadData error:&error];
        else
          result = payloadData;
        
        if( error )
          NSLog(@"error=%@",error);
      } /* of if */
#else
      result = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedPayload];
#endif
      
    } /* of if */
  } /* of if */
  
  return result;
}

/**
 *
 */
+(void) addTag:(UInt32)tagType andData:(NSData*)tagData toResult:(NSMutableData*)result
{ UInt32  tag     = CFSwapInt32HostToLittle( tagType        );
  UInt32  tagSize = CFSwapInt32HostToLittle( (UInt32)tagData.length );
  
  [result appendBytes:&tag     length:sizeof(tag)];
  [result appendBytes:&tagSize length:sizeof(tagSize)];
  [result appendData:tagData];
}

/**
 *
 */
+(void) addTag:(UInt32)tagType andString:(NSString*)tagString toResult:(NSMutableData*)result
{ NSData* tagData = [tagString dataUsingEncoding:NSUTF8StringEncoding];
  
  [CryptoService addTag:tagType andData:tagData toResult:result];
}

/**
 *
 */
+(NSData*) encryptPayload:(id)payloadObject usingKey:(Key*)keyForPayload andDecryptedKey:(NSData*)decryptedKey andError:(NSError**)error
{ NSData* result = nil;
  
  if( payloadObject )
  { NSData* rawPayload = nil;
    
#ifdef _USE_JSONMODEL
    NSMutableData* rw                          = [[NSMutableData alloc] initWithCapacity:1024];
    Class          payloadObjectClass          = [payloadObject class];
    NSString*      payloadStringRepresentation = [payloadObject description];
    
    if( [payloadObject isKindOfClass:[JSONModel class]] )
      payloadStringRepresentation = [payloadObject toJSONString];
    else if( [payloadObject isKindOfClass:[NSString class]] )
    { payloadObjectClass = [NSString class];
      
      payloadStringRepresentation = (NSString*)payloadObject;
    } /* of else if */
    
    if( payloadStringRepresentation==nil )
      [NSException raise:@"EncryptPayloadException" format:@"could not serialize payloadObject"];
       
    //NSLog(@"payload[%@]:%@",payloadObjectClass,payloadStringRepresentation);
    
    [CryptoService addTag:CryptoServiceTagPayloadClassName andString:NSStringFromClass(payloadObjectClass) toResult:rw];
    [CryptoService addTag:CryptoServiceTagPayload          andString:payloadStringRepresentation           toResult:rw];
    [CryptoService addTag:CryptoServiceTagDummy            andData:[NSData dataWithRandom:63]              toResult:rw];
    
    rawPayload = [rw mirror];
#else
    rawPayload = [NSKeyedArchiver archivedDataWithRootObject:payloadObject];
#endif
    
    if( rawPayload )
    {
#ifdef _USE_CRYPTO
      VaultAlgorithmT  vat        = vaultAES256;
      AlgorithmInfoT   vai        = VaultAlgorithmInfo[vat];
      NSString*        payloadIV  = [[NSData dataWithRandom:vai.keySize] hexStringValue];
      VaultAlgorithmT  payloadVAT = getVaultAlgorithm(keyForPayload.payloadalgorithm);
      AlgorithmInfoT   payloadVAI = VaultAlgorithmInfo[payloadVAT];

      result = [rawPayload encryptWithAlgorithm:payloadVAI.cryptoAlgorithm usingKey:decryptedKey andIV:[payloadIV hexString2RawValue] error:error];
#else
      result = rawPayload;
#endif
    } /* of if */
  } /* of if */
  
  return result;
}

/**
 *
 */
-(PMKPromise*) decryptPayload:(Payload*)payload
{ PMKPromise* result = nil;
  
  if( self.delegate==nil )
    @throw [NSException exceptionWithName:@"DelegateNotSetException" reason:nil userInfo:nil];
  
  id decryptedPayload = [[DecryptedObjectCache sharedInstance] decryptedObjectForUniqueId:[payload uniqueObjectId]];
  
  if( decryptedPayload )
    result = [PMKPromise promiseWithValue:payload];
  else
  { PMKPromise* decryptedPayloadKey = [self.delegate decryptedPayloadKeyPromiseForPayload:payload];
    
    if( decryptedPayloadKey )
      result = decryptedPayloadKey
      .then(^(NSData* passwordKey)
      { NSError* error = nil;
        Key*     key   = [payload.keys anyObject];
        
        if( key==nil )
          return (id)error;
        
        id decryptedPayload = [CryptoService decryptPayloadUsing:payload.encryptedpayload usingKey:key andDecryptedKey:passwordKey andError:&error];
        
        [[DecryptedObjectCache sharedInstance] setDecryptedObject:decryptedPayload forUniqueId:[payload uniqueObjectId]];
        
        /*
        if( decryptedPayload )
          _NSLOG(@"payload %@ decrypted:[%@]",[payload uniqueObjectId],decryptedPayload);
        */
        
        return decryptedPayload ? (id) payload : (id)error;
      });
  } /* of else */
  
  return result;
}

/**
 *
 */
-(PMKPromise*) encryptPayload:(Payload*)payload forObject:(id)object
{ PMKPromise* result = nil;
  
  if( self.delegate==nil )
    @throw [NSException exceptionWithName:@"DelegateNotSetException" reason:nil userInfo:nil];
  
  PMKPromise* decryptedPayloadKey = [self.delegate decryptedPayloadKeyPromiseForPayload:payload];
  
  if( decryptedPayloadKey )
    result = decryptedPayloadKey
    .then(^(NSData* passwordKey)
    { NSError* error = nil;
      Key*     key   = [payload.keys anyObject];
      
      if( key==nil )
        return (id)error;
      
      payload.encryptedpayload = [CryptoService encryptPayload:object usingKey:key andDecryptedKey:passwordKey andError:&error];
      
      if( payload.encryptedpayload )
        [_MOC save:&error];
      
      /*
      if( payload.encryptedpayload )
        _NSLOG(@"payload %@ encrypted.",[payload uniqueObjectId]);
      */
      
      return payload.encryptedpayload ? (id)payload : (id)error;
    });
  
  return result;
}

@end
