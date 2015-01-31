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
#import "TresorAlgorithmInfo.h"
#include "crypto.h"

NSArray* gTresorAlgorithmInfos = nil;

@implementation TresorAlgorithmInfo

/**
 *
 */
+(void) initialize
{ //NSLog(@"initialize TresorAlgorithmInfo");
 
  if( self==[TresorAlgorithmInfo class] )
  {
    if( gTresorAlgorithmInfos==nil )
      gTresorAlgorithmInfos = @[ [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_aes128"    andType:tresorAlgorithmAES128     andBlockSize:AES_BLOCK_SIZE     andKeySize:AES128_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_aes192"    andType:tresorAlgorithmAES192     andBlockSize:AES_BLOCK_SIZE     andKeySize:AES192_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_aes256"    andType:tresorAlgorithmAES256     andBlockSize:AES_BLOCK_SIZE     andKeySize:AES256_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"aes128"     andType:tresorAlgorithmAES128CC   andBlockSize:AES_BLOCK_SIZE     andKeySize:AES128_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"aes192"     andType:tresorAlgorithmAES192CC   andBlockSize:AES_BLOCK_SIZE     andKeySize:AES192_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"aes256"     andType:tresorAlgorithmAES256CC   andBlockSize:AES_BLOCK_SIZE     andKeySize:AES256_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"cast"       andType:tresorAlgorithmCASTCC     andBlockSize:CAST_BLOCK_SIZE    andKeySize:CAST16_KEY_SIZE],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"twofish256" andType:tresorAlgorithmTwofish256 andBlockSize:TWOFISH_BLOCK_SIZE andKeySize:TWOFISH_KEY_SIZE],
                                
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_pbkdf2"    andType:tresorAlgorithmPBKDF2     andBlockSize:0                  andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"pbkdf2"     andType:tresorAlgorithmPBKDF2CC   andBlockSize:0                  andKeySize:0],
                                
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_md5"       andType:tresorAlgorithmMD5        andBlockSize:MD5_DIGEST_SIZE    andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"md5"        andType:tresorAlgorithmMD5CC      andBlockSize:MD5_DIGEST_SIZE    andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_sha256"    andType:tresorAlgorithmSHA256     andBlockSize:SHA256_DIGEST_SIZE andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"sha256"     andType:tresorAlgorithmSHA256CC   andBlockSize:SHA256_DIGEST_SIZE andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_sha512"    andType:tresorAlgorithmSHA512     andBlockSize:SHA512_DIGEST_SIZE andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"sha512"     andType:tresorAlgorithmSHA512CC   andBlockSize:SHA512_DIGEST_SIZE andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"_sha1"      andType:tresorAlgorithmSHA1       andBlockSize:SHA1_DIGEST_SIZE   andKeySize:0],
                                [TresorAlgorithmInfo tresorAlgorithmInfoWithName:@"sha1"       andType:tresorAlgorithmSHA1CC     andBlockSize:SHA1_DIGEST_SIZE   andKeySize:0]
                              ];
  } /* of if */
}

/**
 *
 */
-(instancetype) initWithName:(NSString*)name andType:(TresorAlgorithmT)type andBlockSize:(NSUInteger)blockSize andKeySize:(NSUInteger)keySize
{ self = [super init];
 
  if( self )
  { self.name      = name;
    self.type      = type;
    self.blockSize = blockSize;
    self.keySize   = keySize;
  } /* of if */
  
  return self;
}

/**
 *
 */
+(TresorAlgorithmInfo*) tresorAlgorithmInfoWithName:(NSString*)name andType:(TresorAlgorithmT)type andBlockSize:(NSUInteger)blockSize andKeySize:(NSUInteger)keySize
{ TresorAlgorithmInfo* result = [[TresorAlgorithmInfo alloc] initWithName:name andType:type andBlockSize:blockSize andKeySize:keySize];
  
  return result;
}

/**
 *
 */
+(TresorAlgorithmInfo*) tresorAlgorithmInfoForName:(NSString*)name
{ TresorAlgorithmInfo* result = nil;
  
  for( TresorAlgorithmInfo* v in gTresorAlgorithmInfos )
    if( [v.name isEqualToString:name] )
    { result = v;
      
      break;
    } /* of if */
  
  return result;
}

/**
 *
 */
+(TresorAlgorithmInfo*) tresorAlgorithmInfoForType:(TresorAlgorithmT)type
{ TresorAlgorithmInfo* result = nil;

  for( TresorAlgorithmInfo* v in gTresorAlgorithmInfos )
    if( v.type==type )
    { result = v;
      
      break;
    } /* of if */

  return result;
}
@end
/*====================================================END-OF-FILE==========================================================*/
