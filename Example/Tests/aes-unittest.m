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
#include "aes.h"


@interface aes_unittest : XCTestCase
- (void) testAES;
- (void) testAESCBC;
@end


@implementation aes_unittest


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
- (void) testAES 
{ 
  static struct
  { unsigned char keyLen;
    unsigned char key[AES_KEY_SIZE];
  } key[] = 
  { {16, {0x00  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f}},
    {16, {0xff  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f}},
    {16, {0xff  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f}},
    
    {24, {0x00  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f,  
          0x10,  0x11,  0x12,  0x13,  0x14,  0x15,  0x16,  0x17}
         },
    {32, {0x00  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f,  
          0x10,  0x11,  0x12,  0x13,  0x14,  0x15,  0x16,  0x17,  0x18,  0x19,  0x1a,  0x1b,  0x1c,  0x1d,  0x1e,  0x1f
         }
    }
  };
  
  static unsigned char plain[][AES_BLOCK_SIZE] = 
  { {0x00  ,0x11  ,0x22  ,0x33  ,0x44  ,0x55  ,0x66  ,0x77  ,0x88  ,0x99  ,0xaa  ,0xbb  ,0xcc  ,0xdd  ,0xee  ,0xff},
    {0x00  ,0x11  ,0x22  ,0x33  ,0x44  ,0x55  ,0x66  ,0x77  ,0x88  ,0x99  ,0xaa  ,0xbb  ,0xcc  ,0xdd  ,0xee  ,0xff},
    {0x45  ,0x1e  ,0x58  ,0x1d  ,0xe5  ,0xdf  ,0xf6  ,0xf4  ,0xad  ,0x46  ,0x21  ,0x66  ,0x5c  ,0x9f  ,0xab  ,0x07},
    
    {0x00  ,0x11  ,0x22  ,0x33  ,0x44  ,0x55  ,0x66  ,0x77  ,0x88  ,0x99  ,0xaa  ,0xbb  ,0xcc  ,0xdd  ,0xee  ,0xff},
    {0x00  ,0x11  ,0x22  ,0x33  ,0x44  ,0x55  ,0x66  ,0x77  ,0x88  ,0x99  ,0xaa  ,0xbb  ,0xcc  ,0xdd  ,0xee  ,0xff}
  };
  
  static unsigned char crypt[][AES_BLOCK_SIZE] = 
  { {0x69  ,0xc4  ,0xe0  ,0xd8  ,0x6a  ,0x7b  ,0x04  ,0x30  ,0xd8  ,0xcd  ,0xb7  ,0x80  ,0x70  ,0xb4  ,0xc5  ,0x5a},    
    {0x45  ,0x1e  ,0x58  ,0x1d  ,0xe5  ,0xdf  ,0xf6  ,0xf4  ,0xad  ,0x46  ,0x21  ,0x66  ,0x5c  ,0x9f  ,0xab  ,0x07},
    {0x01  ,0x33  ,0xd1  ,0x2f  ,0x51  ,0xa7  ,0x51  ,0x40  ,0x0b  ,0x3d  ,0x6f  ,0xb5  ,0x9b  ,0x97  ,0x2f  ,0xec},
      
    {0xdd  ,0xa9  ,0x7c  ,0xa4  ,0x86  ,0x4c  ,0xdf  ,0xe0  ,0x6e  ,0xaf  ,0x70  ,0xa0  ,0xec  ,0x0d  ,0x71  ,0x91},
    {0x8e  ,0xa2  ,0xb7  ,0xca  ,0x51  ,0x67  ,0x45  ,0xbf  ,0xea  ,0xfc  ,0x49  ,0x90  ,0x4b  ,0x49  ,0x60  ,0x89}
  };

  for( int i=0;i<ARRAYSIZE(key);i++ )
  { AESContextT ctx0[1];
    AESContextT ctx1[1];
    BufferT     plainIn,cryptIn,keyBuffer;
    
    buffer_init(&keyBuffer,key[i].keyLen,key[i].key);
    buffer_init(&plainIn,AES_BLOCK_SIZE,plain[i]);
    buffer_init(&cryptIn,AES_BLOCK_SIZE,crypt[i]);

    BufferT* cryptOut = buffer_alloc(AES_BLOCK_SIZE,NULL);
    BufferT* plainOut = buffer_alloc(AES_BLOCK_SIZE,NULL);
    
    XCTAssertTrue( cryptOut!=NULL && plainOut!=NULL, @"could not allocate buffer" );
    
    XCTAssertTrue( aes_begin(ctx0,&keyBuffer,NULL)==AES_OK, @"aes_begin returned with error");
    XCTAssertTrue( aes_begin(ctx1,&keyBuffer,NULL)==AES_OK, @"aes_begin returned with error");
    XCTAssertTrue( aes_encrypt(ctx0, &plainIn,(BufferT*)cryptOut)==AES_OK, @"aes_encrypt returned with error");
    XCTAssertTrue( aes_decrypt(ctx1, &cryptIn,(BufferT*)plainOut)==AES_OK, @"aes_decrypt returned with error");
    
    XCTAssertTrue( memcmp(plain[i], plainOut->data, plainOut->length)==0, @"AES: Error in plain text");
    XCTAssertTrue( memcmp(crypt[i], cryptOut->data, cryptOut->length)==0, @"AES: Error in crypt text");
    
    XCTAssertTrue( aes_end(ctx0)==AES_OK, @"aes_end returned with error");
    XCTAssertTrue( aes_end(ctx1)==AES_OK, @"aes_end returned with error");
    
    free(cryptOut);
    free(plainOut);
  } /* of for */
} /* of testAES: */

/**
 *
 */
- (void) testAESCBC
{
  static unsigned char key[] = {0x00  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f};
  static unsigned char iv [] = {0x00  ,0x01  ,0x02  ,0x03  ,0x04  ,0x05  ,0x06  ,0x07  ,0x08  ,0x09  ,0x0a  ,0x0b  ,0x0c  ,0x0d  ,0x0e  ,0x0f};
  
  static unsigned char plain[][AES_BLOCK_SIZE] = 
  { {0x00  ,0x11  ,0x22  ,0x33  ,0x44  ,0x55  ,0x66  ,0x77  ,0x88  ,0x99  ,0xaa  ,0xbb  ,0xcc  ,0xdd  ,0xee  ,0xff},
    {0x45  ,0x1e  ,0x58  ,0x1d  ,0xe5  ,0xdf  ,0xf6  ,0xf4  ,0xad  ,0x46  ,0x21  ,0x66  ,0x5c  ,0x9f  ,0xab  ,0x07}
  };
  
  static unsigned char crypt0[][AES_BLOCK_SIZE] = 
  { {0x69  ,0xc4  ,0xe0  ,0xd8  ,0x6a  ,0x7b  ,0x04  ,0x30  ,0xd8  ,0xcd  ,0xb7  ,0x80  ,0x70  ,0xb4  ,0xc5  ,0x5a},    
    {0x64  ,0x32  ,0x38  ,0xc0  ,0xc7  ,0x13  ,0xa7  ,0xc5  ,0x59  ,0x41  ,0x9a  ,0x2a  ,0x9f  ,0x5f  ,0x96  ,0x13}
  };
  
  static unsigned char crypt1[][AES_BLOCK_SIZE] = 
  { {0x76  ,0xd0  ,0x62  ,0x7d  ,0xa1  ,0xd2  ,0x90  ,0x43  ,0x6e  ,0x21  ,0xa4  ,0xaf  ,0x7f  ,0xca  ,0x94  ,0xb7},    
    {0x15  ,0x2b  ,0x54  ,0x0c  ,0x9c  ,0xfb  ,0x26  ,0x78  ,0x9f  ,0x51  ,0xc7  ,0xcb  ,0x6f  ,0xf1  ,0x48  ,0xcd}
  };
  
  BufferT     keyBuffer,ivBuffer,plainBuffer,cryptBuffer;
  AESContextT ctx0[1];
  BufferT*    cryptOut = buffer_alloc(AES_BLOCK_SIZE,NULL);
  
  BUFFER_T(AES_BLOCK_SIZE*2 + 1,hex1);
  BUFFER_T(AES_BLOCK_SIZE*2 + 1,hex2);
  
  XCTAssertTrue( cryptOut!=NULL , @"could not allocate buffer" );
  
  buffer_init(&keyBuffer,16,key);
  buffer_init(&ivBuffer ,16,iv );
  
  /*
   * first test in ECB mode
   */
  XCTAssertTrue( aes_begin(ctx0,&keyBuffer,NULL)==AES_OK, @"aes_begin returned with error");  
  for( int i=0;i<ARRAYSIZE(plain);i++ )
  { buffer_init(&plainBuffer,AES_BLOCK_SIZE,plain[i]);
    buffer_init(&cryptBuffer,AES_BLOCK_SIZE,crypt0[i]);
    
    XCTAssertTrue( aes_encrypt(ctx0, &plainBuffer,(BufferT*)cryptOut)==AES_OK, @"aes_encrypt returned with error");
    
    XCTAssertTrue( buffer_binary2hexstr(&cryptBuffer,(BufferT*)&hex1)==BUFFER_OK, @"buffer_binary2hexstr returned with error"); 
    XCTAssertTrue( buffer_binary2hexstr(cryptOut    ,(BufferT*)&hex2)==BUFFER_OK, @"buffer_binary2hexstr returned with error");
    
    XCTAssertTrue( memcmp(crypt0[i], cryptOut->data, cryptOut->length)==0, @"AES: Error in crypt text in ECB mode <%s>!=<%s>",hex1.data,hex2.data);
  } /* of for */
  XCTAssertTrue( aes_end(ctx0)==AES_OK, @"aes_end returned with error");  

  /*
   * first test in CBC mode
   */
  XCTAssertTrue( aes_begin(ctx0,&keyBuffer,&ivBuffer)==AES_OK, @"aes_begin returned with error");  
  for( int i=0;i<ARRAYSIZE(plain);i++ )
  { buffer_init(&plainBuffer,AES_BLOCK_SIZE,plain[i]);
    
    XCTAssertTrue( aes_encrypt(ctx0, &plainBuffer,(BufferT*)cryptOut)==AES_OK, @"aes_encrypt returned with error");
    XCTAssertTrue( memcmp(crypt1[i], cryptOut->data, cryptOut->length)==0, @"AES: Error in crypt text in CBC mode");
  } /* of for */
  XCTAssertTrue( aes_end(ctx0)==AES_OK, @"aes_end returned with error");

  /*
   * decrypt in CBC mode
   */
  XCTAssertTrue( aes_begin(ctx0,&keyBuffer,&ivBuffer)==AES_OK, @"aes_begin returned with error");  
  for( int i=0;i<ARRAYSIZE(plain);i++ )
  { buffer_init(&plainBuffer,AES_BLOCK_SIZE,crypt1[i]);
    
    XCTAssertTrue( aes_decrypt(ctx0, &plainBuffer,(BufferT*)cryptOut)==AES_OK, @"aes_encrypt returned with error");
    XCTAssertTrue( memcmp(plain[i], cryptOut->data, cryptOut->length)==0, @"AES: Error in crypt text in CBC mode");
  } /* of for */
  XCTAssertTrue( aes_end(ctx0)==AES_OK, @"aes_end returned with error");
  
  free(cryptOut);
} /* of testAESCBC: */


@end
