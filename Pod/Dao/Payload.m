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
 * Copyright (c) 2015 ischlecken.
 */

#import "Payload.h"
#import "Key.h"
#import "Commit.h"
#import "Vault.h"
#import "MasterKey.h"
#import "DecryptedObjectCache.h"
#import "CryptoService.h"
#import "TresorDaoCategories.h"
#import "TresorModel.h"
#import "NSString+Crypto.h"
#import "TresorAlgorithmInfo.h"
#import "TresorError.h"
#import "GCDQueue.h"
#import "Macros.h"


#pragma mark - CreatePayloadParameter

@interface CreatePayloadParameter : NSObject
@property NSString*  cryptoAlgorithm;

@property NSData*    keyCryptoIV;
@property NSData*    payloadCryptoIV;

@property NSData*    encryptedKey;
@property NSData*    encryptedPayload;
@end

@implementation CreatePayloadParameter
@end

#pragma mark - Payload

@implementation Payload

@dynamic createts;
@dynamic encryptedpayload;
@dynamic cryptoalgorithm;
@dynamic cryptoiv;
@dynamic key;
@dynamic commits;

#pragma mark dao extension


/**
 *
 */
-(id)  decryptedPayload
{ id obj = [[DecryptedObjectCache sharedInstance] decryptedObjectForUniqueId:[self uniqueObjectId]];
  
  return obj;
}

/**
 *
 */
-(BOOL) isPayloadItemList
{ id obj = [self decryptedPayload];
  
  return obj!=nil && [obj isKindOfClass:[PayloadItemList class]] ;
}

/**
 *
 */
-(PMKPromise*) acceptVisitor:(id)visitor
{
  PMKPromise* result = [[CryptoService sharedInstance] decryptPayload:self]
  .then(^(Payload* payload)
  {
    return [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
    {
      if( [visitor respondsToSelector:@selector(visitPayload:andState:)] )
        [visitor visitPayload:self andState:0];
      
      fulfiller(self);
    }];
  })
  .then(^(Payload* payload)
  { PMKPromise* result = nil;
  
    if( [payload isPayloadItemList] )
    { PayloadItemList* pil = [payload decryptedPayload];
      
      result = [pil acceptVisitor:visitor];
    } /* of if */
    
    return result;
  })
  .then(^()
  {
    if( [visitor respondsToSelector:@selector(visitPayload:andState:)] )
      [visitor visitPayload:self andState:1];
      
    return self;
  });

  return result;
}


/**
 *
 */
-(Vault*) vault
{ Vault* result = [[self.commits anyObject] vault];
  
  return result;
}

#pragma mark PayloadItemList protocol

/**
 *
 */
-(NSUInteger) count
{ id obj = [self decryptedPayload];
  
  return obj!=nil && [obj isKindOfClass:[PayloadItemList class]] ? [obj count] : 0;
}

/**
 *
 */
-(id) objectAtIndex:(NSUInteger)index
{ id obj = [self decryptedPayload];
  
  return obj!=nil && [obj isKindOfClass:[PayloadItemList class]] ? [obj objectAtIndex:index] : nil;
}


#pragma mark messages


/**
 *
 */
-(NSString*) description
{ id        decryptedPayload = [self decryptedPayload];
  NSString* result           = decryptedPayload ? [NSString stringWithFormat:@"Payload[createts:%@ key:%@ payload:%@]",self.createts,[self.key uniqueObjectId],self.decryptedPayload]
                                                : [NSString stringWithFormat:@"Payload[createts:%@ key:%@]",self.createts,[self.key uniqueObjectId]];
  
  return result;
}


/**
 *
 */
-(PMKPromise*) decryptPayloadUsingDecryptedMasterKey:(NSData*)decryptedMasterKey
{ PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject)
  { NSError* error = nil;
    
    { if( self.key==nil )
      { error = _TRESORERROR(TresorErrorKeyForPayloadNotSet);
        
        goto cleanup0;
      } /* of if */
      
      MasterKey* masterKey = [[self vault] pinMasterKey];
      if( masterKey==nil )
      { error = _TRESORERROR(TresorErrorCouldNotFindPINMasterKey);
        
        goto cleanup0;
      } /* of if */
      
      dispatch_async([[GCDQueue sharedInstance] serialBackgroundQueue], ^
      { _NSLOG(@"start");

        NSError* error            = nil;
        NSData*  decryptedPayload = nil;
        
        {
          NSData* decryptedKey = [self.key.encryptedkey decryptPayloadUsingAlgorithm:[TresorAlgorithmInfo tresorAlgorithmInfoForName:self.key.cryptoalgorithm]
                                                                     andDecryptedKey:decryptedMasterKey
                                                                         andCryptoIV:[self.key.cryptoiv hexString2RawValue]
                                                                            andError:&error];
          
          if( decryptedKey==nil )
            goto  cleanup1;
          
          _NSLOG(@"decryptedPayloadKey:%@",[decryptedKey shortHexStringValue]);
          
          decryptedPayload = [self.encryptedpayload decryptPayloadUsingAlgorithm:[TresorAlgorithmInfo tresorAlgorithmInfoForName:self.cryptoalgorithm]
                                                                 andDecryptedKey:decryptedKey
                                                                     andCryptoIV:[self.cryptoiv hexString2RawValue]
                                                                        andError:&error];

          if( decryptedPayload==nil )
            goto cleanup1;
          
          _NSLOG(@"decryptedPayload   :{%@} %@",[decryptedPayload class],decryptedPayload);
          
          [[DecryptedObjectCache sharedInstance] setDecryptedObject:decryptedPayload forUniqueId:[self uniqueObjectId]];
        }
        
      cleanup1:
        if( decryptedPayload )
          fulfill(self);
        else
          reject(error);
        
        _NSLOG(@"stop");
      });
    }
    
  cleanup0:
      if( error )
        reject(error);
    
  }];
  
  return result;
}


/**
 *
 */
+(PMKPromise*) payloadWithObject:(id)object inCommit:(Commit*)commit usingDecryptedMasterKey:(NSData*)decryptedMasterKey
{ PMKPromise* result = nil;
  
  if( object && commit && commit.vault && decryptedMasterKey )
    result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
    {
      dispatch_async([[GCDQueue sharedInstance] serialBackgroundQueue], ^
      { _NSLOG(@"begin");
        
        NSError*                error            = nil;
        NSData*                 encryptedKey     = nil;
        NSData*                 encryptedPayload = nil;
        TresorAlgorithmInfo*    vai              = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmAES256CC];
        CreatePayloadParameter* cpp              = nil;
        
        { NSData* decryptedKey    = [NSData dataWithRandom:vai.keySize];
          NSData* keyCryptoIV     = [NSData dataWithRandom:vai.blockSize];
          NSData* payloadCryptoIV = [NSData dataWithRandom:vai.blockSize];
        
          _NSLOG(@"createPayloadKey");
          
          encryptedKey = [NSData encryptPayload:decryptedKey
                                 usingAlgorithm:vai
                                andDecryptedKey:decryptedMasterKey
                                    andCryptoIV:keyCryptoIV
                                       andError:&error];
          
          if( encryptedKey==nil )
            goto cleanup;
          
          _NSLOG(@"encryptPayload");
          
          encryptedPayload = [NSData encryptPayload:object
                                     usingAlgorithm:vai
                                    andDecryptedKey:decryptedKey
                                        andCryptoIV:payloadCryptoIV
                                           andError:&error];
          
          if( encryptedPayload==nil )
            goto cleanup;
          
          cpp = [CreatePayloadParameter new];
           
          cpp.cryptoAlgorithm  = vai.name;
          
          cpp.keyCryptoIV      = keyCryptoIV;
          cpp.encryptedKey     = encryptedKey;
          
          cpp.payloadCryptoIV  = payloadCryptoIV;
          cpp.encryptedPayload = encryptedPayload;
        }
        
      cleanup:
        if( cpp )
          fulfiller(cpp);
        else
          rejecter(error);
        
        _NSLOG(@"end");
      });
    }]
    .then(^(CreatePayloadParameter* cpp)
    { Payload* payload = [NSEntityDescription insertNewObjectForEntityForName:@"Payload" inManagedObjectContext:_MOC];
      Key*     key     = [NSEntityDescription insertNewObjectForEntityForName:@"Key"     inManagedObjectContext:_MOC];
      NSError* error   = nil;
      
      key.createts             = [NSDate date];
      key.cryptoiv             = [cpp.keyCryptoIV hexStringValue];
      key.cryptoalgorithm      = cpp.cryptoAlgorithm;
      key.encryptedkey         = cpp.encryptedKey;
      
      payload.createts         = key.createts;
      payload.cryptoiv         = [cpp.payloadCryptoIV hexStringValue];
      payload.cryptoalgorithm  = cpp.cryptoAlgorithm;
      payload.encryptedpayload = cpp.encryptedPayload;
      payload.key              = key;
      
      [payload addCommitsObject:commit];
      
      return payload && key && [_MOC save:&error] ? payload : error;
    });
  
  return result;
}

@end
