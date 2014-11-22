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
#include "sha1.h"
#include "sha2.h"

@interface sha_unittest : XCTestCase
- (void) testSHA1;
- (void) testSHA256;
- (void) testSHA512;
@end

@implementation sha_unittest

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
- (void) testSHA1
{ static const char *const test[3*2] = 
  { ""                                                           , "da39a3ee5e6b4b0d3255bfef95601890afd80709",
    "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "68ac906495480a3404beee4874ed853a037a7a8f",
    "Frank jagt im komplett verwahrlosten Taxi quer durch Bayern", "d8e8ece39c437e515aa8997c1a1e94f1ed2a0e62"
  };
  
  BufferT* digest     = buffer_alloc(SHA1_DIGEST_SIZE,NULL);
  BufferT* digestHex  = buffer_alloc(SHA1_DIGEST_SIZE*2 + 1,NULL);
  
  BufferT* digest1    = buffer_alloc(SHA1_DIGEST_SIZE,NULL);
  BufferT* digest1Hex = buffer_alloc(SHA1_DIGEST_SIZE*2 + 1,NULL);
  
  XCTAssertTrue( digest!=NULL && digest1!=NULL && digestHex!=NULL && digest1Hex!=NULL, @"could not allocate digest buffer");
  
  for( int i=0;i<ARRAYSIZE(test);i+=2 ) 
  { SHA1ContextT ctx[1];
    BufferT      data;
    
    buffer_init(&data, (unsigned int)strlen(test[i]), ( unsigned char *)test[i]);
    
    XCTAssertTrue( sha1_begin(ctx)      ==SHA1_OK, @"sha1_begin returned with error");
    XCTAssertTrue( sha1_hash(ctx, &data)==SHA1_OK, @"sha1_hash returned with error");
    XCTAssertTrue( sha1_end(ctx,digest) ==SHA1_OK, @"sha1_end returned with error");
    
    XCTAssertTrue( buffer_binary2hexstr(digest,digestHex)==BUFFER_OK,@"buffer_binary2hexstr returned with error");    
    XCTAssertTrue( strcmp((char*)(digestHex->data), test[i + 1])==0, @"SHA1 (\"%s\") = <%s>, should be <%s>",test[i],digestHex->data,test[i+1]);
    
    XCTAssertTrue( CommonCryptoSHA1(&data, digest1,TRUE)==EXIT_SUCCESS,@"CommonCryptoSHA1 returned with error");

    XCTAssertTrue( buffer_binary2hexstr(digest1,digest1Hex)==BUFFER_OK,@"buffer_binary2hexstr returned with error");    
    XCTAssertTrue( memcmp(digest1->data,digest->data,SHA1_DIGEST_SIZE)==0, @"SHA1 (\"%s\") calculated by internal and CC function differs: <%s>!=<%s>",test[i],digestHex->data,digest1Hex->data);
} /* of for */
  
  free( digest     );
  free( digest1    );
  free( digestHex  );
  free( digest1Hex );
} /* of testSHA1: */

/**
 *
 */
- (void) testSHA256
{
  static const char *const test[3*2] = 
  { ""                                                           , "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "d32b568cd1b96d459e7291ebf4b25d007f275c9f13149beeb782fac0716613f8",
    "Frank jagt im komplett verwahrlosten Taxi quer durch Bayern", "78206a866dbb2bf017d8e34274aed01a8ce405b69d45db30bafa00f5eeed7d5e"
  };
  
  int i;
  
  for (i = 0; i < ARRAYSIZE(test); i += 2) 
  { SHA256ContextT ctx[1];
    
    BUFFER_T(SHA256_DIGEST_SIZE,digest);
    BUFFER_T(SHA256_DIGEST_SIZE*2 + 1,digestHex);
    BUFFER_STR(data,test[i]);
    
    sha256_begin(ctx);
    sha256_hash(ctx, &data);
    sha256_end(ctx,(BufferT*)&digest);
    
    buffer_binary2hexstr((BufferT*)&digest,(BufferT*)&digestHex);
    
    XCTAssertTrue( strcmp((char*)digestHex.data, test[i + 1])==0, @"SHA256 (\"%s\") = <%s>, should be <%s>",test[i],digestHex.data,test[i+1]);
  }
} /* of testSHA256: */

/**
 *
 */
- (void) testSHA512
{
  static const char *const test[3*2] = 
  { ""                                                           , "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e",
    "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "af9ed2de700433b803240a552b41b5a472a6ef3fe1431a722b2063c75e9f07451f67a28e37d09cde769424c96aea6f8971389db9e1993d6c565c3c71b855723c",
    "Frank jagt im komplett verwahrlosten Taxi quer durch Bayern", "90b30ef9902ae4c4c691d2d78c2f8fa0aa785afbc5545286b310f68e91dd2299c84a2484f0419fc5eaa7de598940799e1091c4948926ae1c9488dddae180bb80"
  };
  
  int i;
  
  for (i = 0; i < ARRAYSIZE(test); i += 2) 
  { SHA512ContextT ctx[1];
    
    BUFFER_T(SHA512_DIGEST_SIZE,digest);
    BUFFER_T(SHA512_DIGEST_SIZE*2 + 1,digestHex);
    BUFFER_STR(data,test[i]);
    
    sha512_begin(ctx);
    sha512_hash(ctx, &data);
    sha512_end(ctx,(BufferT*)&digest);
    
    buffer_binary2hexstr((BufferT*)&digest,(BufferT*)&digestHex);
    
    XCTAssertTrue( strcmp((char*)digestHex.data, test[i + 1])==0, @"SHA512 (\"%s\") = <%s>, should be <%s>",test[i],digestHex.data,test[i+1]);
  }
} /* of testSHA512: */



@end
