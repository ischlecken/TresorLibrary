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

#include "pwd2key.h"

@interface pwd2key_unittest : XCTestCase
- (void) testDeriveKey;
@end

@implementation pwd2key_unittest

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
- (void) testDeriveKey
{
  
  struct
  { unsigned int    pwd_len;
    unsigned int    salt_len;
    unsigned int    it_count;
    unsigned char   *pwd;
    unsigned char   salt[32];
    unsigned char   key[32];
  } tests[] =
  {
    {   8, 4, 5, (unsigned char*)"password",
      {   
        0x12, 0x34, 0x56, 0x78 
      },
      {   
        0x5c, 0x75, 0xce, 0xf0, 0x1a, 0x96, 0x0d, 0xf7,
        0x4c, 0xb6, 0xb4, 0x9b, 0x9e, 0x38, 0xe6, 0xb5 
      }
    },
    {   8, 8, 5, (unsigned char*)"password",
      {   
        0x12, 0x34, 0x56, 0x78, 0x78, 0x56, 0x34, 0x12 
      },
      {   
        0xd1, 0xda, 0xa7, 0x86, 0x15, 0xf2, 0x87, 0xe6,
        0xa1, 0xc8, 0xb1, 0x20, 0xd7, 0x06, 0x2a, 0x49 
      }
    },
    {   8, 21, 1, (unsigned char*)"password",
      {
        "ATHENA.MIT.EDUraeburn"
      },
      {
        0xcd, 0xed, 0xb5, 0x28, 0x1b, 0xb2, 0xf8, 0x01,
        0x56, 0x5a, 0x11, 0x22, 0xb2, 0x56, 0x35, 0x15
      }
    },
    {   8, 21, 2, (unsigned char*)"password",
      {
        "ATHENA.MIT.EDUraeburn"
      },
      {
        0x01, 0xdb, 0xee, 0x7f, 0x4a, 0x9e, 0x24, 0x3e, 
        0x98, 0x8b, 0x62, 0xc7, 0x3c, 0xda, 0x93, 0x5d
      }
    },
    {   8, 21, 1200, (unsigned char*)"password",
      {
        "ATHENA.MIT.EDUraeburn"
      },
      {
        0x5c, 0x08, 0xeb, 0x61, 0xfd, 0xf7, 0x1e, 0x4e, 
        0x4e, 0xc3, 0xcf, 0x6b, 0xa1, 0xf5, 0x51, 0x2b
      }
    }
  };
  
  unsigned int    i;
  unsigned char   key[256];
  
  BufferT  pwd;
  BufferT  salt;
  BufferT  keyBuffer;
  BufferT* hexOutput = buffer_alloc(256*2+1, NULL);
  
  buffer_init(&keyBuffer,ARRAYSIZE(key),key);
  
  for(i = 0; i < 5; ++i)
  { buffer_init(&pwd , tests[i].pwd_len , tests[i].pwd);
    buffer_init(&salt, tests[i].salt_len, tests[i].salt);
    
    XCTAssertTrue( deriveKey(&pwd,&salt,&keyBuffer, tests[i].it_count)==DERIVEKEY_OK, @"deriveKey returnd with error");
    
    buffer_binary2hexstr(&keyBuffer,hexOutput);
    
    XCTAssertTrue( memcmp(tests[i].key, key, 16)==0, @"%s: <%s>",tests[i].pwd,hexOutput->data);
  } /* of for */
  
  free( hexOutput );
} /* of testDeriveKey: */

@end
