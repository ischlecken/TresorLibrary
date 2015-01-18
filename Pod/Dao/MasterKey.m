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
#import "MasterKey.h"
#import "Vault.h"
#import "TresorAlgorithmInfo.h"
#import "NSString+Crypto.h"
#import "TresorModel.h"
#import "Macros.h"
#import "GCDQueue.h"
#import "SSKeychain.h"

#pragma mark - CreateMasterKeysParameter

@interface CreateMasterKeysParameter : NSObject
@property NSString*  keyChainID4EncryptedPinMasterKey;
@property NSData*    pinMasterCryptoIV;
@property NSData*    pinKDFSalt;

@property NSString*  keyChainID4EncryptedPUKMasterKey;
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
@dynamic keychainid4encryptedkey;
@dynamic cryptoiv;

@dynamic lockts;
@dynamic lockcount;
@dynamic failedauthentications;
@dynamic authentication;
@dynamic vault;

@dynamic kdfsalt;
@dynamic kdf;
@dynamic kdfiterations;

/**
 *
 */
+(PMKPromise*) masterKeyWithVaultParameter:(VaultParameter*)parameter
{ PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  {
    dispatch_async([[GCDQueue sharedInstance] serialBackgroundQueue], ^
    { _NSLOG(@"start");

      NSError*                   error = nil;
      CreateMasterKeysParameter* cmkp  = nil;
      
      { TresorAlgorithmInfo*  encryptAlgo  = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmAES256CC];
        TresorAlgorithmInfo*  deriveAlgo   = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmPBKDF2CC];
        NSData*               pinData      = [parameter.pin hexString2RawValue];
        NSData*               pukData      = [parameter.puk hexString2RawValue];
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
        
        /**
         * this is the master key that is used for the encryption of all other keys
         */
        NSData* masterCryptoKey1   = [masterCryptoKey0 deriveKeyWithAlgorithm:deriveAlgo
                                                                                        withLength:keySize
                                                                                         usingSalt:[NSData dataWithRandom:keySize]
                                                                                     andIterations:1000000
                                                                                             error:&error];
        
        if( masterCryptoKey1==nil )
          goto cleanup;
        
        parameter.masterCryptoKey = masterCryptoKey1;
        
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

        NSString* keyChainID4EncryptedPinMasterKey = [NSString stringUniqueID];
        NSString* keyChainID4EncryptedPUKMasterKey = [NSString stringUniqueID];
        
        [SSKeychain setAccessibilityType:kSecAttrAccessibleWhenUnlocked];
        
        if( ![SSKeychain setPassword:[pinMasterEncryptedKey hexStringValue]
                          forService:kTresorKeychainServiceName
                             account:keyChainID4EncryptedPinMasterKey
                               error:&error]
           )
          goto cleanup;

        if( ![SSKeychain setPassword:[pukMasterEncryptedKey hexStringValue]
                          forService:kTresorKeychainServiceName
                             account:keyChainID4EncryptedPUKMasterKey
                               error:&error]
           )
          goto cleanup;
        
        
        cmkp                                  = [CreateMasterKeysParameter new];
        
        cmkp.cryptoAlgorithm                  = encryptAlgo.name;
        cmkp.kdfAlgorithm                     = deriveAlgo.name;
        cmkp.kdfIterations                    = iterations;
        
        cmkp.keyChainID4EncryptedPinMasterKey = keyChainID4EncryptedPinMasterKey;
        cmkp.pinMasterCryptoIV                = pinMasterCryptoIV;
        cmkp.pinKDFSalt                       = pinKDFSalt;

        cmkp.keyChainID4EncryptedPUKMasterKey = keyChainID4EncryptedPUKMasterKey;
        cmkp.pukMasterCryptoIV                = pukMasterCryptoIV;
        cmkp.pukKDFSalt                       = pukKDFSalt;
      }
      
cleanup:
      if( cmkp )
        fulfiller(cmkp);
      else
        rejecter(error);
      
      _NSLOG(@"stop");
    });
  }]
  .then(^(CreateMasterKeysParameter* cmkp)
  { MasterKey* masterKeyPIN              = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];
    masterKeyPIN.createts                = [NSDate date];
    masterKeyPIN.keychainid4encryptedkey = cmkp.keyChainID4EncryptedPinMasterKey;
    masterKeyPIN.cryptoiv                = [cmkp.pinMasterCryptoIV hexStringValue];
    masterKeyPIN.cryptoalgorithm         = cmkp.cryptoAlgorithm;
    masterKeyPIN.authentication          = kMasterKeyPINAuthentication;
    masterKeyPIN.kdfiterations           = [NSNumber numberWithUnsignedInteger:cmkp.kdfIterations];
    masterKeyPIN.kdfsalt                 = [cmkp.pinKDFSalt hexStringValue];
    masterKeyPIN.kdf                     = cmkp.kdfAlgorithm;
    
    MasterKey* masterKeyPUK              = [NSEntityDescription insertNewObjectForEntityForName:@"MasterKey" inManagedObjectContext:_MOC];
    masterKeyPUK.createts                = masterKeyPIN.createts;
    masterKeyPUK.keychainid4encryptedkey = cmkp.keyChainID4EncryptedPUKMasterKey;
    masterKeyPUK.cryptoiv                = [cmkp.pukMasterCryptoIV hexStringValue];
    masterKeyPUK.cryptoalgorithm         = cmkp.cryptoAlgorithm;
    masterKeyPUK.authentication          = kMasterKeyPUKAuthentication;
    masterKeyPUK.kdfiterations           = [NSNumber numberWithUnsignedInteger:cmkp.kdfIterations];
    masterKeyPUK.kdfsalt                 = [cmkp.pukKDFSalt hexStringValue];
    masterKeyPUK.kdf                     = cmkp.kdfAlgorithm;
    
    return PMKManifold(masterKeyPIN,masterKeyPUK);
  });

  return result;
}

/**
 *
 */
-(PMKPromise*) decryptedMasterKeyUsingPIN:(NSString*)pin
{ PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfill, PMKPromiseRejecter reject)
  { dispatch_async([[GCDQueue sharedInstance] serialBackgroundQueue], ^
    { _NSLOG(@"start");
      
      NSError* error              = nil;
      NSData*  decryptedMasterKey = nil;
      
      { TresorAlgorithmInfo*  encryptAlgo   = [TresorAlgorithmInfo tresorAlgorithmInfoForName:self.cryptoalgorithm];
        TresorAlgorithmInfo*  deriveAlgo    = [TresorAlgorithmInfo tresorAlgorithmInfoForName:self.kdf];
        NSData*               pinData       = [pin hexString2RawValue];
        NSUInteger            keySize       = encryptAlgo.keySize;
        NSUInteger            iterations    = [self.kdfiterations unsignedIntegerValue];
        NSData*               pinKDFSalt    = [self.kdfsalt hexString2RawValue];
        NSData*               pinDerivedKey = [pinData deriveKeyWithAlgorithm:deriveAlgo
                                                                   withLength:keySize
                                                                    usingSalt:pinKDFSalt
                                                                andIterations:iterations
                                                                        error:&error];
        if( pinDerivedKey==nil )
          goto cleanup;
        
        NSString* encryptedKeyString = [SSKeychain passwordForService:kTresorKeychainServiceName
                                                              account:self.keychainid4encryptedkey
                                                                error:&error];
        
        if( encryptedKeyString==nil )
          goto cleanup;
        
        NSData* encryptedKey = [encryptedKeyString hexString2RawValue];
        
        decryptedMasterKey = [NSData decryptPayload:encryptedKey
                                     usingAlgorithm:encryptAlgo
                                    andDecryptedKey:pinDerivedKey
                                        andCryptoIV:[self.cryptoiv hexString2RawValue]
                                           andError:&error];
      }
      
    cleanup:
      if( decryptedMasterKey )
      { //_NSLOG(@"decryptedMasterKey:%@",[decryptedMasterKey hexStringValue]);
        
        fulfill(decryptedMasterKey);
      } /* of if */
      else
        reject(error);
      
      _NSLOG(@"stop");
    });
  }];
  
  return result;
}


@end
