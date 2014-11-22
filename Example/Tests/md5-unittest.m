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

@interface md5_unittest : XCTestCase
- (void) testMD5;
@end


@implementation md5_unittest

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
- (void) testMD5
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
  { MD5ContextT ctx[1];
    BufferT     data;
    
    buffer_init(&data, (unsigned int)strlen(test[i]), (unsigned char *)test[i]);
    
    XCTAssertTrue( md5_begin(ctx)==MD5_OK, @"md5_begin returned with error");
    XCTAssertTrue( md5_hash(ctx, &data)==MD5_OK, @"md5_hash returned with error");
    XCTAssertTrue( md5_end(ctx,(BufferT*)digest)==MD5_OK, @"md5_end returned with error");
    
    XCTAssertTrue( buffer_check(digest)==BUFFER_OK, @"buffer_check returned with error");   
    XCTAssertTrue( buffer_binary2hexstr(digest,(BufferT*)&digestHex)==BUFFER_OK, @"buffer_binary2hexstr returned with error");   
    
    XCTAssertTrue( strcmp((char*)digestHex.data, test[i + 1])==0, @"MD5 (\"%s\") = <%s>, should be <%s>",test[i],digestHex.data,test[i+1]);
    
    XCTAssertTrue( CommonCryptoMD5(&data, digest1,true)==EXIT_SUCCESS, @"CommonCryptoMD5 returned with error");
    
    XCTAssertTrue( buffer_check(digest1)==BUFFER_OK, @"buffer_check returned with error");    
    XCTAssertTrue( buffer_binary2hexstr(digest1,(BufferT*)&digestHex1)==BUFFER_OK, @"buffer_binary2hexstr returned with error");
    
    XCTAssertTrue( strcmp((char*)digestHex1.data,(char*)digestHex.data)==0, @"CommonCrypto/CommonDigest/MD5 (\"%s\") != <%s>",digestHex1.data,digestHex.data);
  } /* of for */
  
  free(digest1);
  free(digest);
} /* of testMD5: */

@end
