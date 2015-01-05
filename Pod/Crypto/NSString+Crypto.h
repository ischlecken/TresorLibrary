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
 */
#import "NSData+Crypto.h"
#import "TresorAlgorithmInfo.h"

typedef NS_ENUM(UInt8,TresorCryptoPasswordT)
{ NSStringPasswordDigit = 0,
  NSStringPasswordAlpha = 1,
  NSStringPasswordAlnum = 2
};

@interface NSString(TresorCrypto)
-(NSData*)   hashWithAlgorithm:(TresorAlgorithmInfo*) algorithm error:(NSError **)outError;

-(NSData*)   encryptWithAlgorithm:(TresorAlgorithmInfo*) algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError;
-(NSData*)   decryptWithAlgorithm:(TresorAlgorithmInfo*) algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError;

-(NSData*)   hexString2RawValue;

+(NSString*) stringUniqueID;

+(NSString*) stringPassword:(TresorCryptoPasswordT)passwordType withLength:(NSUInteger)length;
@end
/*===============================================END-OF-FILE=================================================*/
