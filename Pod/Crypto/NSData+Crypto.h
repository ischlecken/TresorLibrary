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
#import "PromiseKit.h"
#import "TresorAlgorithmInfo.h"

@interface GeneratedPIN : NSObject 
@property NSString*  pin;
@property NSData*    salt;
@property NSUInteger iterations;
@property NSString*  algorithm;
@end

@interface NSData(TresorCrypto)
-(NSData*)      hashWithAlgorithm:(TresorAlgorithmInfo*)algorithm error:(NSError **)outError;
-(NSData*)      encryptWithAlgorithm:(TresorAlgorithmInfo*)algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError;
-(NSData*)      decryptWithAlgorithm:(TresorAlgorithmInfo*)algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError;

-(NSData*)      deriveKeyWithAlgorithm:(TresorAlgorithmInfo*)algorithm withLength:(NSUInteger)keyLength usingSalt:(NSData*)salt andIterations:(NSUInteger)iter error:(NSError **)outError;

-(NSData*)      mirror;

-(instancetype) initWithHexString:(const char*)hexString;
-(instancetype) initWithUTF8String:(NSString*)string;
-(instancetype) initWithRandom:(NSUInteger)length;

-(NSString*)    hexStringValue;

+(NSData*)      dataWithHexString:(const char*)hexString;
+(NSData*)      dataWithUTF8String:(NSString*)string;
+(NSData*)      dataWithRandom:(NSUInteger)length;

+(PMKPromise*)  generatePINWithLength:(NSUInteger)pinLength;

+(id)           decryptPayload:(NSData*)payload
                usingAlgorithm:(TresorAlgorithmInfo*)algorithm
               andDecryptedKey:(NSData*)decryptedKey
                   andCryptoIV:(NSData*)cryptoIV
                      andError:(NSError**)error;

+(NSData*)      encryptPayload:(id)payloadObject
                usingAlgorithm:(TresorAlgorithmInfo*)algorithm
               andDecryptedKey:(NSData*)decryptedKey
                   andCryptoIV:(NSData*)cryptoIV
                      andError:(NSError**)error;

@end
/*==================================END-OF-FILE==========================================*/
