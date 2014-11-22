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
#import <XCTest/XCTest.h>
#include "commoncrypto.h"
#include "md5.h"

@interface commoncrypto_unittest : XCTestCase
-(void) testMD5;
-(void) testDeriveKey;
-(void) testRandomData;
@end

@implementation commoncrypto_unittest

/**
 *
 */
-(void) setUp
{ [super setUp]; }

/**
 *
 */
-(void) tearDown
{ [super tearDown]; }

/**
 *
 */
-(void) testMD5
{
  static const char *const test[7*2] = 
  { ""                                                                                , "d41d8cd98f00b204e9800998ecf8427e",
    "a"                                                                               , "0cc175b9c0f1b6a831c399e269772661",
    "abc"                                                                             , "900150983cd24fb0d6963f7d28e17f72",
    "message digest"                                                                  , "f96b697d7cb7938d525a2f31aaf161d0",
    "abcdefghijklmnopqrstuvwxyz"                                                      , "c3fcd3d76192e4007dfb496cca67e13b",
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"                  , "d174ab98d277d9f5a5611c2c9f419d9f",
    "12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57edf4a22be3c955ac49da2e2107b67a"
  };
  
  BufferT* digest = buffer_alloc(MD5_DIGEST_SIZE,NULL);
  XCTAssertTrue( digest!=NULL, @"could not allocate digest buffer");
  
  BufferT* digest1 = buffer_alloc(MD5_DIGEST_SIZE,NULL);
  XCTAssertTrue( digest1!=NULL, @"could not allocate digest1 buffer");
  
  BUFFER_T(MD5_DIGEST_SIZE*2 + 1,digestHex);
  BUFFER_T(MD5_DIGEST_SIZE*2 + 1,digestHex1);
  
  for( int i=0;i<ARRAYSIZE(test);i+=2 ) 
  { BufferT data;
    
    buffer_init(&data, (unsigned int)strlen(test[i]), (unsigned char *)test[i]);
    
    XCTAssertTrue( CommonCryptoMD5(&data, digest1,true)==EXIT_SUCCESS, @"CommonCryptoMD5 returned with error");
    
    XCTAssertTrue( buffer_check(digest1)==BUFFER_OK, @"buffer_check returned with error");    
    XCTAssertTrue( buffer_binary2hexstr(digest1,(BufferT*)&digestHex1)==BUFFER_OK, @"buffer_binary2hexstr returned with error");
    
    XCTAssertTrue( strcmp((char*)digestHex1.data,test[i+1])==0, @"CommonCrypto/CommonDigest/MD5 (\"%s\") != <%s>",digestHex1.data,digestHex.data);
  } /* of for */
  
  free(digest1);
  free(digest);
} /* of testMD5: */

/**
 *
 */
-(void) testDeriveKey
{
  static const char *const test1[1*3] = 
  { "password" , "f96b697d7cb7938d525a2f31aaf161d0", "B6F13BD399ABA1EF0F60BB53BCB82063"  
  };
  
  for( int i=0;i<ARRAYSIZE(test1);i+=3 ) 
  { BufferT password;
    BufferT salt;
    BufferT key;
    
    buffer_init(&password, (unsigned int)strlen(test1[i])  , (unsigned char *)test1[i]  );
    buffer_init(&salt    , (unsigned int)strlen(test1[i+1]), (unsigned char *)test1[i+1]);
    buffer_init(&key     , (unsigned int)strlen(test1[i+2]), (unsigned char *)test1[i+2]);
    
    BufferT* salt1 = buffer_alloc(salt.length/2,NULL);
    BufferT* key1  = buffer_alloc(key.length/2, NULL);
    BufferT* key2  = buffer_alloc(key.length/2, NULL);
    
    XCTAssertTrue( buffer_hexstr2binary(&salt, salt1)==BUFFER_OK, @"buffer_hexstr2binary returned with error");    
    XCTAssertTrue( buffer_hexstr2binary(&key, key1)==BUFFER_OK, @"buffer_hexstr2binary returned with error");    
    
    XCTAssertTrue( CommonCryptoDeriveKey(&password, salt1, key2, 10000,true)==EXIT_SUCCESS, @"CommonCryptoDeriveKey returned with error");
    
    XCTAssertTrue( memcmp(key1->data, key2->data,key1->length)==0, @"CommonCryptoDeriveKey returned with error");
    
    free(salt1);
    free(key1);
    free(key2);
  } /* of for */
  
} /* of testDeriveKey: */

/**
 *
 */
-(void) testRandomData
{
  int length = 128;
  
  BufferT* random = buffer_alloc(length,NULL);
  
  XCTAssertTrue( CommonCryptoRandomData(random)==EXIT_SUCCESS, @"CommonCryptoRandomData returned with error");
  
  free(random);
} /* of testRandomData: */
@end
