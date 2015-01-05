//
//  Key.m
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import "Key.h"
#import "Payload.h"
#import "MasterKey.h"
#import "TresorAlgorithmInfo.h"
#import "NSString+Crypto.h"

@implementation Key

@dynamic createts;
@dynamic cryptoalgorithm;
@dynamic cryptoiv;
@dynamic encryptedkey;
@dynamic payload;
@dynamic masterkeys;

#pragma mark dao extension


/**
 *
 */
-(NSString*) description
{ NSString* result = [NSString stringWithFormat:@"Key[]"];
  
  return result;
}

/**
 *
 */
+(Key*) keyWithEncryptedKey:(NSData*)encryptedKey andCryptoIV:(NSString*)cryptoIV andCryptoAlgorith:(NSString*)cryptoAlgorithm andError:(NSError**)error
{ Key* result = [NSEntityDescription insertNewObjectForEntityForName:@"Key" inManagedObjectContext:_MOC];
  
  result.createts        = [NSDate date];
  result.encryptedkey    = encryptedKey;
  result.cryptoiv        = cryptoIV;
  result.cryptoalgorithm = cryptoAlgorithm;
  
  _MOC_SAVERETURN;
}


/**
 *
 */
+(Key*) keyWithRandomKey:(NSData*)passwordKey andKeySize:(NSUInteger)keySize andError:(NSError**)error
{ Key* result = [NSEntityDescription insertNewObjectForEntityForName:@"Key" inManagedObjectContext:_MOC];
  
  TresorAlgorithmInfo*  vai          = [TresorAlgorithmInfo tresorAlgorithmInfoForType:tresorAlgorithmAES256];
  NSData*               decryptedKey = [NSData dataWithRandom:keySize];
  
  result.createts         = [NSDate date];
  result.cryptoiv         = [[NSData dataWithRandom:vai.blockSize] hexStringValue];
  result.cryptoalgorithm  = vai.name;
  result.encryptedkey     = [decryptedKey encryptWithAlgorithm:vai usingKey:passwordKey andIV:[result.cryptoiv hexString2RawValue] error:error];
  
  _MOC_SAVERETURN;
}

@end

