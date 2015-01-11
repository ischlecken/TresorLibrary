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
      { _NSLOG(@"decryptPayloadWithDecryptedMasterKey.start");

        NSError* error            = nil;
        NSData*  decryptedPayload = nil;
        
        { NSData* decryptedKey = [masterKey decryptKey:self.key.encryptedkey usingDecryptedMasterKey:decryptedMasterKey andError:&error];
        
          if( decryptedKey==nil )
            goto  cleanup1;
          
          decryptedPayload = [self.key decryptPayload:self.encryptedpayload usingDecryptedKey:decryptedKey andError:&error];
          
          if( decryptedPayload==nil )
            goto cleanup1;
          
          [[DecryptedObjectCache sharedInstance] setDecryptedObject:decryptedPayload forUniqueId:[self uniqueObjectId]];
        }
        
      cleanup1:
        if( decryptedPayload )
          fulfill(self);
        else
          reject(error);
        
        _NSLOG(@"decryptPayloadWithDecryptedMasterKey.stop");
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
+(Payload*) payloadWithRandomKey:(NSError**)error
{ Payload*              result = nil;
  TresorAlgorithmInfo*  vai    = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmAES256];
  Key*                  key    = [Key keyWithRandomKey:_DUMMYPASSWORD andKeySize:vai.keySize andError:error];
  
  if( key )
  { result = [NSEntityDescription insertNewObjectForEntityForName:@"Payload" inManagedObjectContext:_MOC];
  
    result.createts         = [NSDate date];
    result.cryptoiv         = [[NSData dataWithRandom:vai.blockSize] hexStringValue];
    result.cryptoalgorithm  = vai.name;
    
    key.payload = result;
  } /* of if */
  
  return result;
}

/**
 *
 */
+(PMKPromise*) payloadWithObject:(id)object
{ PMKPromise* promise = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  { NSError*    error   = nil;
    PMKPromise* promise = nil;
    Payload*    payload = [Payload payloadWithRandomKey:&error];
     
    if( payload )
      promise = [[CryptoService sharedInstance] encryptPayload:payload forObject:object];
    
    if( promise )
    { //_NSLOG(@"new payload:%@",payload.uniqueObjectId);
      
      fulfiller(promise);
    } /* of if */
    else
      rejecter(error);
  }];
  
  return promise;
}

@end
