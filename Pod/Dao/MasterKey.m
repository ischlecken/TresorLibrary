//
//  MasterKey.m
//  Pods
//
//  Created by Feldmaus on 11.12.14.
//
//

#import "MasterKey.h"
#import "TresorUtilConstant.h"
#import "NSString+Crypto.h"
#import "TresorModel.h"

@implementation MasterKey

@dynamic createts;
@dynamic cryptoalgorithm;
@dynamic encryptedkey;
@dynamic cryptoiv;

@dynamic lockts;
@dynamic lockcount;
@dynamic failedauthentications;
@dynamic authentication;
@dynamic keys;

@dynamic kdfsalt;
@dynamic kdf;
@dynamic kdfiterations;

/**
 *
 */
+(PMKPromise*) masterKeyWithPin:(NSString*)pin
{ MasterKey*      masterKey    = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];

  VaultAlgorithmT vat          = vaultAES256;
  AlgorithmInfoT  vai          = VaultAlgorithmInfo[vat];
  NSData*         passwordData = [pin dataUsingEncoding:NSUTF8StringEncoding];
  NSUInteger      keySize      = vai.keySize;

#if TARGET_IPHONE_SIMULATOR
  NSUInteger      iterations   = 4000000;
#else
  NSUInteger      iterations   = 1000000;
#endif

  masterKey.createts        = [NSDate date];
  masterKey.encryptedkey    = nil;
  masterKey.cryptoiv        = [[NSData dataWithRandom:vai.blockSize] hexStringValue];
  masterKey.cryptoalgorithm = VaultAlgorithmString[vat];
  masterKey.authentication  = @"pin";
  masterKey.kdfiterations   = [NSNumber numberWithUnsignedInteger:iterations];
  masterKey.kdfsalt         = [[NSData dataWithRandom:keySize] hexStringValue];
  masterKey.kdf             = @"PBKDF2CC";
  
  PMKPromise*     result       = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  { fulfiller(masterKey);
  }]
  .thenOn(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^(MasterKey* mk)
  { NSError* error      = nil;
    NSData*  derivedKey = [passwordData deriveKeyWithAlgorithm:deriveKeyAlgoPBKDF2CC
                                                    withLength:keySize
                                                     usingSalt:[mk.kdfsalt hexString2RawValue]
                                                 andIterations:iterations
                                                         error:&error];
    
    return derivedKey ? (id)derivedKey : (id)error;
  })
  .thenOn(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^(NSData* derivedKey)
  { NSError* error          = nil;
    NSData* masterCryptoKey = [NSData dataWithRandom:keySize];
    
    masterKey.encryptedkey  = [masterCryptoKey encryptWithAlgorithm:vai.cryptoAlgorithm
                                                             usingKey:derivedKey
                                                                andIV:[masterKey.cryptoiv hexString2RawValue]
                                                                error:&error];
    return masterKey.encryptedkey ? (id)masterKey.encryptedkey : (id)error;
  });

  return result;
}

@end
