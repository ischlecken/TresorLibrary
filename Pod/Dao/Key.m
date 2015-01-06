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

