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
#import "Macros.h"

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
{ PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^
    {
      _NSLOG(@"masterKeyWithPin.start");

      VaultAlgorithmT vat          = vaultAES256;
      AlgorithmInfoT  vai          = VaultAlgorithmInfo[vat];
      NSData*         passwordData = [pin dataUsingEncoding:NSUTF8StringEncoding];
      NSUInteger      keySize      = vai.keySize;
      NSUInteger      iterations   = 2000000;
      
#if TARGET_IPHONE_SIMULATOR
      iterations *= 4;
#endif
      
      NSData*  kdfSalt    = [NSData dataWithRandom:keySize];
      NSError* error      = nil;
      NSData*  derivedKey = [passwordData deriveKeyWithAlgorithm:deriveKeyAlgoPBKDF2CC
                                                      withLength:keySize
                                                       usingSalt:kdfSalt
                                                   andIterations:iterations
                                                           error:&error];
      
      if( derivedKey )
      { NSData* masterCryptoKey    = [NSData dataWithRandom:keySize];
        NSData* masterCryptoIV     = [NSData dataWithRandom:vai.blockSize];
        
        NSData* masterEncryptedKey = [masterCryptoKey encryptWithAlgorithm:vai.cryptoAlgorithm
                                                               usingKey:derivedKey
                                                                  andIV:masterCryptoIV
                                                                  error:&error];
        if( masterEncryptedKey )
        { MasterKey* masterKey = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];
          
          masterKey.createts        = [NSDate date];
          masterKey.encryptedkey    = masterEncryptedKey;
          masterKey.cryptoiv        = [masterCryptoIV hexStringValue];
          masterKey.cryptoalgorithm = VaultAlgorithmString[vat];
          masterKey.authentication  = @"pin";
          masterKey.kdfiterations   = [NSNumber numberWithUnsignedInteger:iterations];
          masterKey.kdfsalt         = [kdfSalt hexStringValue];
          masterKey.kdf             = @"PBKDF2CC";

          fulfiller(masterKey);
        } /* of if */
        else
          rejecter(error);
      } /* of if */
      else
        rejecter(error);
      
      _NSLOG(@"masterKeyWithPin.stop");
    });
  }];

  return result;
}

@end
