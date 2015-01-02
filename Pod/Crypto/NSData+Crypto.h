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

/* CC == CommonCrypto */
typedef enum 
{ hashAlgoMD5      = 0,
  hashAlgoMD5CC    = 1,
  hashAlgoSHA256   = 2,
  hashAlgoSHA256CC = 3,
  hashAlgoSHA512   = 4,
  hashAlgoSHA512CC = 5,
  hashAlgoSHA1     = 6,
  hashAlgoSHA1CC   = 7
} TresorCryptoHashAlgorithmT;

typedef enum 
{ cryptAlgoAES128     = 0,
  cryptAlgoAES128CC   = 1,
  cryptAlgoAES192     = 2,
  cryptAlgoAES192CC   = 3,
  cryptAlgoAES256     = 4,
  cryptAlgoAES256CC   = 5,
  cryptAlgoCASTCC     = 6,
  cryptAlgoTWOFISH256 = 7
} TresorCryptoAlgorithmT;

typedef enum 
{ deriveKeyAlgoPBKDF2   = 0,
  deriveKeyAlgoPBKDF2CC = 1
} TresorCryptoDeriveKeyAlgorithmT;


@interface NSData(TresorCrypto)
-(NSData*)      hashWithAlgorithm:(TresorCryptoHashAlgorithmT)algorithm error:(NSError **)outError;
-(NSData*)      encryptWithAlgorithm:(TresorCryptoAlgorithmT)algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError;
-(NSData*)      decryptWithAlgorithm:(TresorCryptoAlgorithmT)algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError;

-(NSData*)      deriveKeyWithAlgorithm:(TresorCryptoDeriveKeyAlgorithmT)algorithm withLength:(NSUInteger)keyLength usingSalt:(NSData*)salt andIterations:(NSUInteger)iter error:(NSError **)outError;

-(NSData*)      mirror;

-(instancetype) initWithHexString:(const char*)hexString;
-(instancetype) initWithUTF8String:(NSString*)string;
-(instancetype) initWithRandom:(NSUInteger)length;

-(NSString*)    hexStringValue;

+(NSData*)      dataWithHexString:(const char*)hexString;
+(NSData*)      dataWithUTF8String:(NSString*)string;
+(NSData*)      dataWithRandom:(NSUInteger)length;

+(PMKPromise*)  generatePINWithLength:(NSUInteger)pinLength usingIterations:(NSUInteger)iterations;

@end
/*==================================END-OF-FILE==========================================*/
