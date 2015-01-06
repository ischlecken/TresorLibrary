//
//  MasterKey.m
//  Pods
//
//  Created by Feldmaus on 11.12.14.
//
//
#import "MasterKey.h"
#import "Vault.h"
#import "TresorAlgorithmInfo.h"
#import "NSString+Crypto.h"
#import "TresorModel.h"
#import "Macros.h"

#pragma mark - CreateMasterKeysParameter

#if 0
masterKeyPIN.createts        = [NSDate date];
masterKeyPIN.encryptedkey    = pinMasterEncryptedKey;
masterKeyPIN.cryptoiv        = [pinMasterCryptoIV hexStringValue];
masterKeyPIN.cryptoalgorithm = VaultAlgorithmString[vat];
masterKeyPIN.authentication  = @"pin";
masterKeyPIN.kdfiterations   = [NSNumber numberWithUnsignedInteger:iterations];
masterKeyPIN.kdfsalt         = [pinKDFSalt hexStringValue];
masterKeyPIN.kdf             = @"PBKDF2CC";

masterKeyPUK = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];
masterKeyPUK.createts        = masterKeyPIN.createts;
masterKeyPUK.encryptedkey    = pukMasterEncryptedKey;
masterKeyPUK.cryptoiv        = [pukMasterCryptoIV hexStringValue];
masterKeyPUK.cryptoalgorithm = VaultAlgorithmString[vat];
masterKeyPUK.authentication  = @"pin";
masterKeyPUK.kdfiterations   = [NSNumber numberWithUnsignedInteger:iterations];
masterKeyPUK.kdfsalt         = [pukKDFSalt hexStringValue];
masterKeyPUK.kdf             = @"PBKDF2CC";
}
#endif

@interface CreateMasterKeysParameter : NSObject
@property NSData*    pinMasterEncryptedKey;
@property NSData*    pinMasterCryptoIV;
@property NSData*    pinKDFSalt;

@property NSData*    pukMasterEncryptedKey;
@property NSData*    pukMasterCryptoIV;
@property NSData*    pukKDFSalt;

@property NSString*  cryptoAlgorithm;

@property NSString*  kdfAlgorithm;
@property NSUInteger kdfIterations;
@end

@implementation CreateMasterKeysParameter
@end

#pragma mark - Masterkey

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
@dynamic vault;

@dynamic kdfsalt;
@dynamic kdf;
@dynamic kdfiterations;

/**
 *
 */
+(PMKPromise*) masterKeyWithPin:(NSString*)pin andPUK:(NSString*)puk
{ PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^
    { _NSLOG(@"masterKeyWithPin.start");

      NSError*                   error = nil;
      CreateMasterKeysParameter* cmkp  = nil;
      
      { TresorAlgorithmInfo*  encryptAlgo  = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmAES256];
        TresorAlgorithmInfo*  deriveAlgo   = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmPBKDF2CC];
        NSData*               pinData      = [pin hexString2RawValue];
        NSData*               pukData      = [puk hexString2RawValue];
        NSUInteger            keySize      = encryptAlgo.keySize;
        NSUInteger            iterations   = 2000000;
        
  #if TARGET_IPHONE_SIMULATOR
        iterations *= 4;
  #endif
        
        NSData*  pinKDFSalt    = [NSData dataWithRandom:keySize];
        NSData*  pinDerivedKey = [pinData deriveKeyWithAlgorithm:deriveAlgo
                                                        withLength:keySize
                                                         usingSalt:pinKDFSalt
                                                     andIterations:iterations
                                                             error:&error];
        if( pinDerivedKey==nil )
          goto cleanup;

        NSData*  pukKDFSalt    = [NSData dataWithRandom:keySize];
        NSData*  pukDerivedKey = [pukData deriveKeyWithAlgorithm:deriveAlgo
                                                      withLength:keySize
                                                       usingSalt:pukKDFSalt
                                                   andIterations:iterations
                                                           error:&error];
        if( pukDerivedKey==nil )
          goto cleanup;
        
        NSData* masterCryptoKey0   = [NSData dataWithRandom:keySize];
        _NSLOG(@"masterCryptoKey0:%@",[masterCryptoKey0 hexStringValue]);
        
        NSData* masterCryptoKey1   = [masterCryptoKey0 deriveKeyWithAlgorithm:deriveAlgo
                                                                                        withLength:keySize
                                                                                         usingSalt:[NSData dataWithRandom:keySize]
                                                                                     andIterations:1000000
                                                                                             error:&error];
        
        if( masterCryptoKey1==nil )
          goto cleanup;
        
        _NSLOG(@"masterCryptoKey1:%@",[masterCryptoKey1 hexStringValue]);
        
        NSData* pinMasterCryptoIV     = [NSData dataWithRandom:encryptAlgo.blockSize];
        NSData* pinMasterEncryptedKey = [NSData encryptPayload:masterCryptoKey1
                                                usingAlgorithm:encryptAlgo
                                               andDecryptedKey:pinDerivedKey
                                                   andCryptoIV:pinMasterCryptoIV
                                                      andError:&error];
        
        if( pinMasterEncryptedKey==nil )
          goto cleanup;

        _NSLOG(@"pinMasterEncryptedKey:%@",[pinMasterEncryptedKey hexStringValue]);

        NSData* pukMasterCryptoIV     = [NSData dataWithRandom:encryptAlgo.blockSize];
        NSData* pukMasterEncryptedKey = [NSData encryptPayload:masterCryptoKey1
                                                usingAlgorithm:encryptAlgo
                                               andDecryptedKey:pukDerivedKey
                                                   andCryptoIV:pukMasterCryptoIV
                                                      andError:&error];
        
        if( pukMasterEncryptedKey==nil )
          goto cleanup;
        
        _NSLOG(@"pukMasterEncryptedKey:%@",[pukMasterEncryptedKey hexStringValue]);
        
        cmkp                       = [CreateMasterKeysParameter new];
        
        cmkp.cryptoAlgorithm       = encryptAlgo.name;
        cmkp.kdfAlgorithm          = deriveAlgo.name;
        cmkp.kdfIterations         = iterations;
        
        cmkp.pinMasterEncryptedKey = pinMasterEncryptedKey;
        cmkp.pinMasterCryptoIV     = pinMasterCryptoIV;
        cmkp.pinKDFSalt            = pinKDFSalt;

        cmkp.pukMasterEncryptedKey = pukMasterEncryptedKey;
        cmkp.pukMasterCryptoIV     = pukMasterCryptoIV;
        cmkp.pukKDFSalt            = pukKDFSalt;
      }
      
cleanup:
      if( cmkp )
        fulfiller(cmkp);
      else
        rejecter(error);
      
      _NSLOG(@"masterKeyWithPin.stop");
    });
  }]
  .then(^(CreateMasterKeysParameter* cmkp)
  { MasterKey* masterKeyPIN = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];
    masterKeyPIN.createts        = [NSDate date];
    masterKeyPIN.encryptedkey    = cmkp.pinMasterEncryptedKey;
    masterKeyPIN.cryptoiv        = [cmkp.pinMasterCryptoIV hexStringValue];
    masterKeyPIN.cryptoalgorithm = cmkp.cryptoAlgorithm;
    masterKeyPIN.authentication  = @"pin";
    masterKeyPIN.kdfiterations   = [NSNumber numberWithUnsignedInteger:cmkp.kdfIterations];
    masterKeyPIN.kdfsalt         = [cmkp.pinKDFSalt hexStringValue];
    masterKeyPIN.kdf             = cmkp.kdfAlgorithm;
    
    MasterKey* masterKeyPUK = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];
    masterKeyPUK.createts        = masterKeyPIN.createts;
    masterKeyPUK.encryptedkey    = cmkp.pukMasterEncryptedKey;
    masterKeyPUK.cryptoiv        = [cmkp.pukMasterCryptoIV hexStringValue];
    masterKeyPUK.cryptoalgorithm = cmkp.cryptoAlgorithm;
    masterKeyPUK.authentication  = @"puk";
    masterKeyPUK.kdfiterations   = [NSNumber numberWithUnsignedInteger:cmkp.kdfIterations];
    masterKeyPUK.kdfsalt         = [cmkp.pukKDFSalt hexStringValue];
    masterKeyPUK.kdf             = cmkp.kdfAlgorithm;
    
    return PMKManifold(masterKeyPIN,masterKeyPUK);
  });

  return result;
}

/**
 *
 */
-(PMKPromise*) decryptedMasterKeyUsingPIN:(NSString*)pin
{ PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject)
  { dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^
    { _NSLOG(@"decryptedMasterKeyUsingPIN.start");
      
      NSData* decryptedKey = [NSData new];
      
      fulfill(decryptedKey);
      
      _NSLOG(@"decryptedMasterKeyUsingPIN.stop");
    });
  }];
  
  return result;
}

@end
