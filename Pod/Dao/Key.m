//
//  Key.m
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import "Key.h"
#import "Password.h"
#import "Payload.h"
#import "TresorUtilConstant.h"
#import "NSString+Crypto.h"

@implementation Key

@dynamic iv;
@dynamic payloadalgorithm;
@dynamic payloadiv;
@dynamic payloadkey;
@dynamic password;

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
+(Key*) keyWithIV:(NSString*)iv andPayloadKey:(NSData*)payloadKey andPayloadIV:(NSString*)payloadIV andPayloadAlgorith:(NSString*)payloadAlgorithm andError:(NSError**)error
{ Key* result = [NSEntityDescription insertNewObjectForEntityForName:@"Key" inManagedObjectContext:_MOC];
  
  result.iv               = iv;
  result.payloadkey       = payloadKey;
  result.payloadiv        = payloadIV;
  result.payloadalgorithm = payloadAlgorithm;
  
  _MOC_SAVERETURN;
}


/**
 *
 */
+(Key*) keyWithRandomKey:(NSData*)passwordKey andError:(NSError**)error
{ Key* result = [NSEntityDescription insertNewObjectForEntityForName:@"Key" inManagedObjectContext:_MOC];
  
  VaultAlgorithmT vat          = vaultAES256;
  AlgorithmInfoT  vai          = VaultAlgorithmInfo[vat];
  NSData*         decryptedKey = [NSData dataWithRandom:vai.keySize];
  
  result.iv                = [[NSData dataWithRandom:vai.blockSize] hexStringValue];
  result.payloadiv         = [[NSData dataWithRandom:vai.blockSize] hexStringValue];
  result.payloadalgorithm  = VaultAlgorithmString[vat];
  result.payloadkey        = [decryptedKey encryptWithAlgorithm:vai.cryptoAlgorithm usingKey:passwordKey andIV:[result.iv hexString2RawValue] error:error];
  
  _MOC_SAVERETURN;
}

@end

