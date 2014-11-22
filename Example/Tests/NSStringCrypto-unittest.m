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
#import "NSData+Crypto.h"
#import "NSString+Crypto.h"
#import "crypto.h"
#import "CryptoError.h"


@interface NSStringCrypto_unittest : XCTestCase
- (void) testHash;
- (void) testEncrypt;
- (void) testDecrypt;
@end


static const char *const hashTypeName[] = 
{ "md5","md5cc",
  "sha256","sha256cc",
  "sha512","sha512cc",
  "sha1","sha1cc",
  NULL
};

static const char *const crytoTypeName[] = 
{ "aes128","aes128cc","aes192","aes192cc","aes256","aes256cc","castcc","twofish256",
  NULL
};

#if 0
static const char *const derivekeyTypeName[] = 
{ "pbkdf2","pbkdf2cc",
  NULL
};
#endif

/*
 *
 */
int getEnumFromName(const char* const names[],const char* name)
{ int result = -1;
  
  for( int i=0;names[i]!=NULL;i++ )
    if( strcmp(names[i],name)==0 )
    { result = i;
 
      break;
    } /* of if */
  
  return result;
}

/* hashtype, value , hashvalue */
static const char *const hashTestdata[] = 
{ "md5", ""                                                                                , "D41D8CD98F00B204E9800998ECF8427E",
  "md5", "a"                                                                               , "0CC175B9C0F1B6A831C399E269772661",
  "md5", "abc"                                                                             , "900150983CD24FB0D6963F7D28E17F72",
  "md5", "message digest"                                                                  , "F96B697D7CB7938D525A2F31AAF161D0",
  "md5", "abcdefghijklmnopqrstuvwxyz"                                                      , "C3FCD3D76192E4007DFB496CCA67E13B",
  "md5", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"                  , "D174AB98D277D9F5A5611C2C9F419D9F",
  "md5", "12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57EDF4A22BE3C955AC49DA2E2107B67A"
};

/*
 * encrypt aes with openssl
 * echo -n "0123456789ABCDEF0123456789abcdef" | openssl enc -aes-128-cbc -K 000102030405060708090a0b0c0d0e0f -iv 00000000000000000000000000000000 | hexdump -e '16/1 "%02X"  "\n"'
 *
 * decrypt CAST with openssl
 * cat cast.raw | openssl enc -d -cast-cbc -K 0001020304050607 -iv ffffffffffffffff | hexdump -C
 */

/* cryptotype, key, iv, plaintext , crypto */
static const char *const cryptoTestdata[] = 
{ "aes128cc", "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "Nikolaus"                                                   , "86CE2705F51244B6ACEC0A143C2C39A4",
  "aes128"  , "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "Nikolaus"                                                   , "86CE2705F51244B6ACEC0A143C2C39A4",


  "aes128cc", "000102030405060708090a0b0c0d0e0f", "ff000000000000000000000000000000", "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "6FC9FEBA2D60176759D9399F36BDFB79"
                                                                                                                                                     "8D1AA0DFE8A4DD99DF9AD2AD80E89C21" 
                                                                                                                                                     "F1C55E717CA19B5DFCA4B08CAC7063CA" 
                                                                                                                                                     "BF8BA5820153FC4D67A91C370F5B74EF",

  "aes128"  , "000102030405060708090a0b0c0d0e0f", "ff000000000000000000000000000000", "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "6FC9FEBA2D60176759D9399F36BDFB79"
                                                                                                                                                     "8D1AA0DFE8A4DD99DF9AD2AD80E89C21" 
                                                                                                                                                     "F1C55E717CA19B5DFCA4B08CAC7063CA" 
                                                                                                                                                     "BF8BA5820153FC4D67A91C370F5B74EF",
  
  "aes128"  , "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "5B198DC540CD6EEC23C5978AA51BD5E1"
                                                                                                                                                     "C6A89855B60C84856B2DF714FEED008D"
                                                                                                                                                     "44779FA003C3D3522F4CFA3D7B904B11"
                                                                                                                                                     "7140C90E15EFC117AFB674E9B78B7091",

  "aes128cc", "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "5B198DC540CD6EEC23C5978AA51BD5E1"
                                                                                                                                                     "C6A89855B60C84856B2DF714FEED008D"
                                                                                                                                                     "44779FA003C3D3522F4CFA3D7B904B11"
                                                                                                                                                     "7140C90E15EFC117AFB674E9B78B7091",

  "aes128cc", "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "0123456789ABCDEF"                                           , "A5BA2B6280D433BCCFE6A0461CB88C4E"
                                                                                                                                                     "46D28E7802BC3348D62F098128FC8218",
  
  "aes128"  , "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "0123456789ABCDEF"                                           , "A5BA2B6280D433BCCFE6A0461CB88C4E"
                                                                                                                                                     "46D28E7802BC3348D62F098128FC8218",

  "aes128cc", "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "0123456789ABCDEF0123456789abcdef"                           , "A5BA2B6280D433BCCFE6A0461CB88C4E"
                                                                                                                                                     "6BE6007A475DD1A3FB1F6EDF98B58643"
                                                                                                                                                     "A230E4D93C45BF86005E59034096E021",
                                                                                                                                                  
  "aes128"  , "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", "0123456789ABCDEF0123456789abcdef"                           , "A5BA2B6280D433BCCFE6A0461CB88C4E"
                                                                                                                                                     "6BE6007A475DD1A3FB1F6EDF98B58643"
                                                                                                                                                     "A230E4D93C45BF86005E59034096E021",
                                                                                                                                                  
  
  
  "aes128"  , "000102030405060708090a0b0c0d0e0f", NULL                              , "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "D41D8CD98F00B204E9800998ECF8427E",
  "aes128"  , NULL                              , NULL                              , "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "D41D8CD98F00B204E9800998ECF8427E",
  "aes128"  , NULL                              , "00000000000000000000000000000000", "Franz jagt im komplett verwahrlosten Taxi quer durch Bayern", "D41D8CD98F00B204E9800998ECF8427E",
  "aes128"  , "000102030405060708090a0b0c0d0e0f", "00000000000000000000000000000000", NULL                                                         , NULL                              ,
  
  
  "castcc"  , "0001020304050607"                , "0000000000000000"                , "nikolau"                                                    , "A00860B94E7584AD"                ,
  
  "twofish256","0123456789abcdeffedcba987654321000112233445566778899aabbccddeeff",  "00000000000000000000000000000000",  "0123456789ABCDEF0123456789abcdef",  "EEAD2C2A76A5BB7647173F298ADABD56"
                                                                                                                                                              "0F21AE56BC7B2CA6234FB2FD6C2E14C2"
                                                                                                                                                              "BD9B1721AC87B833BB80FCF1D7B6BF40"

};


/*
 *
 */
@implementation NSStringCrypto_unittest


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
-(void) testHash
{ for( int i=0;i<ARRAYSIZE(hashTestdata);i+=3 )
  { NSError*    error               = nil;
    const char* hashName            = hashTestdata[i+0];
    int         hashType            = getEnumFromName(hashTypeName, hashName);
    const char* value               = hashTestdata[i+1];
    const char* hashValue           = hashTestdata[i+2];
    NSData*     calculatedHashValue = [[NSString stringWithCString:value encoding:NSISOLatin1StringEncoding] hashWithAlgorithm:hashType error:&error];
    
    XCTAssertTrue( error==nil, @"an error %@ happend in hashWithAlgorithm:%s",error,hashName );
    
    const char* calcHexHashValue    = [[calculatedHashValue hexStringValue] UTF8String];
    
    XCTAssertTrue( strcmp(calcHexHashValue,hashValue)==0,@"%s hash [%s] for [%s] is not equal to expected value [%s]",hashName,hashValue,value,calcHexHashValue );
  } /* of for */    
}


/**
 *
 */
-(void) testEncrypt
{ 
  for( int i=0;i<ARRAYSIZE(cryptoTestdata);i+=5 )
  { NSError*    error                 = nil;
    const char* cryptoName            = cryptoTestdata[i+0];
    int         cryptoType            = getEnumFromName(crytoTypeName, cryptoName);
    const char* keyValue              = cryptoTestdata[i+1];
    const char* ivValue               = cryptoTestdata[i+2];
    const char* plainValue            = cryptoTestdata[i+3];
    const char* cryptoValue           = cryptoTestdata[i+4];
    
    NSString*   plainValueStr         = plainValue==NULL ? nil : [NSString stringWithCString:plainValue encoding:NSISOLatin1StringEncoding];    
    NSData*     keyData               = keyValue==NULL   ? nil : [NSData dataWithHexString:keyValue];
    NSData*     ivData                = ivValue==NULL    ? nil : [NSData dataWithHexString:ivValue];
    NSData*     cryptoValueData       = [plainValueStr encryptWithAlgorithm:cryptoType usingKey:keyData andIV:ivData error:&error];
    
    if( keyValue==NULL || ivValue==NULL )
      XCTAssertTrue( error!=nil && [error code]==CryptoErrorIllegalArgument && [[error domain] isEqualToString:CryptoErrorDomain], @"unexcepted error for encryptWithAlgorithm" );
    else
    { XCTAssertTrue( error==nil, @"an error %@ happend in encryptWithAlgorithm:%s",error,cryptoName );
    
      if( error==nil && plainValue!=NULL )
      { const char* hexCryptoValueData    = [[cryptoValueData hexStringValue] UTF8String];
      
        XCTAssertTrue( strcmp(hexCryptoValueData,cryptoValue)==0,@"%s crypto [%s] for [%s] is not equal to expected value [%s]",cryptoName,hexCryptoValueData,plainValue,cryptoValue);
      } /* of if */
    } /* of else */
  } /* of for */ 
} /* of testEncryt: */

/**
 *
 */
-(void) testDecrypt
{ 
  for( int i=0;i<ARRAYSIZE(cryptoTestdata);i+=5 )
  { NSError*    error                 = nil;
    const char* cryptoName            = cryptoTestdata[i+0];
    int         cryptoType            = getEnumFromName(crytoTypeName, cryptoName);
    const char* keyValue              = cryptoTestdata[i+1];
    const char* ivValue               = cryptoTestdata[i+2];
    const char* plainValue            = cryptoTestdata[i+3];
    const char* cryptoValue           = cryptoTestdata[i+4];
    
    NSData*     cryptoData            = cryptoValue==NULL ? nil : [NSData dataWithHexString:cryptoValue];
    NSData*     keyData               = keyValue==NULL    ? nil : [NSData dataWithHexString:keyValue];
    NSData*     ivData                = ivValue==NULL     ? nil : [NSData dataWithHexString:ivValue];
    
    NSData*     plainValueData        = [cryptoData decryptWithAlgorithm:cryptoType usingKey:keyData andIV:ivData error:&error];
    
    if( keyValue==NULL || ivValue==NULL )
      XCTAssertTrue( error!=nil && [error code]==CryptoErrorIllegalArgument && [[error domain] isEqualToString:CryptoErrorDomain], @"unexcepted error for decryptWithAlgorithm" );
    else
    { XCTAssertTrue( error==nil, @"an error %@ happend in decryptWithAlgorithm:%s",error,cryptoName );
      
      if( error==nil && cryptoValue!=NULL )
      { NSString* plainStr = [[NSString alloc] initWithBytes:[plainValueData bytes] length:[plainValueData length] encoding:NSISOLatin1StringEncoding];
        
        XCTAssertTrue( memcmp([plainValueData bytes],plainValue,strlen(plainValue))==0,@"%s plain text [%s] for [%s] is not equal to expected value [%@]",cryptoName,plainValue,cryptoValue,plainStr);
      } /* of if */
    } /* of else */
  } /* of for */ 
} /* of testDecryt: */
@end
/*============================================================================END-OF-FILE============================================================================*/
