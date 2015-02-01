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
#import "Macros.h"

@implementation Key

@dynamic createts;
@dynamic cryptoalgorithm;
@dynamic cryptoiv;
@dynamic encryptedkey;
@dynamic payload;

#pragma mark dao extension


/**
 *
 */
-(NSString*) description
{ NSString* result = [NSString stringWithFormat:@"Key[cryptoiv:%@ encryptedkey:%@]",self.cryptoiv,[self.encryptedkey shortHexStringValue]];
  
  return result;
}

@end

