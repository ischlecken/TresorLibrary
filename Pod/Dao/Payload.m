//
//  Payload.m
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import "Payload.h"
#import "Key.h"
#import "Commit.h"  
#import "DecryptedObjectCache.h"
#import "CryptoService.h"
#import "TresorDaoCategories.h"
#import "TresorModel.h"
#import "NSString+Crypto.h"
#import "TresorUtilConstant.h"

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
+(Payload*) payloadWithRandomKey:(NSError**)error
{ Payload*        result = nil;
  VaultAlgorithmT vat    = vaultAES256;
  AlgorithmInfoT  vai    = VaultAlgorithmInfo[vat];
  Key*            key    = [Key keyWithRandomKey:_DUMMYPASSWORD andKeySize:vai.keySize andError:error];
  
  if( key )
  { result = [NSEntityDescription insertNewObjectForEntityForName:@"Payload" inManagedObjectContext:_MOC];
  
    result.createts         = [NSDate date];
    result.cryptoiv         = [[NSData dataWithRandom:vai.blockSize] hexStringValue];
    result.cryptoalgorithm  = VaultAlgorithmString[vat];
    
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
