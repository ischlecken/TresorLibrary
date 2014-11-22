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
#import  <XCTest/XCTest.h>
#import  "crypto.h"
#import  "base64.h"
#include "buffer.h"

@interface buffer_unittest : XCTestCase
- (void) testHexConversion;
- (void) testRandomBuffer;
- (void) testBase64Conversion;
@end


@implementation buffer_unittest

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
- (void) testHexConversion
{
  static const char *const test[] = 
  { "d4",
    "d4ef",
    "0cc",
    "900150983cd24fb0d6963f7d28e17f722",
    "f96b697d7cb7938d525a2f31aaf161d0",
    "c3fcd3d76192e4007dfb496cca67e13b",
    "d174ab98d277d9f5a5611c2c9f419d9f",
    "57edf4a22be3c955ac49da2e2107b67a"
  };
  
  for( int i=0;i<ARRAYSIZE(test);i++ ) 
  { BufferT  data0;
    int      slen  = (int)strlen(test[i]);
    BufferT* data1 = buffer_alloc(slen/2,NULL);
    BufferT* data2 = buffer_alloc(slen+1,NULL);
    
    buffer_init(&data0, slen, (unsigned char *)test[i]);
    
    XCTAssertTrue( data1!=NULL && data2!=NULL, @"buffer data1 or data2 could not be allocated");
    
    XCTAssertTrue( buffer_hexstr2binary(&data0, data1)==BUFFER_OK, @"buffer_hexstr2binary() failed" );
    XCTAssertTrue( buffer_binary2hexstr(data1, data2)==BUFFER_OK , @"buffer_binary2hexstr() failed" );
    
    XCTAssertTrue( memcmp(data0.data, data2->data, slen & 0xFFFFFFFE )==0, @"strings <%s>:<%s> are not identical",data0.data,data2->data);
    
    free(data1);
    free(data2);
  } /* of for */
} /* of testHexConversion: */


/**
 *
 */
- (void) testBase64Conversion
{
  static const char *const test[] = 
  { "d",
    "d4",
    "0cc",
    "d4ef",
    "Das äöpß098!\"§$%",
    "Das ist das Haus vom Nikolaus",
    "test the quick brown fox jumps over the lazy dog 0123456890.test the quick brown fox jumps over the lazy dog 0123456890.test the quick brown fox jumps over the lazy dog 0123456890."
  };
  
  for( int i=0;i<ARRAYSIZE(test);i++ ) 
  { BufferT  data0;
    int      slen = (int)strlen(test[i]);    
    
    buffer_init(&data0, slen, (unsigned char *)test[i]);
    
    BufferT* data1 = buffer_alloc(base64_encode_length(slen,0),NULL);
    
    XCTAssertTrue( data1!=NULL , @"buffer data1 could not be allocated");
    
    XCTAssertTrue( buffer_binary2base64(&data0, data1)==BUFFER_OK , @"buffer_binary2base64() failed" );
    
    BufferT* data2 = buffer_alloc(base64_decode_length(data1->length,0),NULL);
    
    XCTAssertTrue( data2!=NULL , @"buffer data2 could not be allocated");
    
    XCTAssertTrue( buffer_base642binary(data1, data2)==BUFFER_OK , @"buffer_base642binary() failed" );
    
    XCTAssertTrue( memcmp(data0.data, data2->data, slen )==0, @"strings <%s>:<%s> are not identical",data0.data,data2->data);
    
    free(data1);
    free(data2);
  } /* of for */
} /* of testBase64Conversion: */


/**
 *
 */
- (void)testRandomBuffer
{
  BufferT* buffer = buffer_alloc(16,BUFFER_RANDOM);
  
  XCTAssertTrue( buffer!=NULL , @"buffer could not be allocated");
  
  free(buffer);
}

@end
