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
#import "NSString+Crypto.h"
#import "CryptoError.h"


@implementation NSString(TresorCrypto)

/**
 *
 */
-(NSData*) hashWithAlgorithm:(TresorAlgorithmInfo*) algorithm error:(NSError **)outError
{ NSData* result = [[NSData dataWithBytes:[self UTF8String] length:[self length]] hashWithAlgorithm:algorithm error:outError];
  
  return result;
} /* of hashWithAlgorithm: */

/**
 *
 */
-(NSData*) encryptWithAlgorithm:(TresorAlgorithmInfo*) algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError
{ NSData* result = [[NSData dataWithBytes:[self UTF8String] length:[self length]] encryptWithAlgorithm:algorithm usingKey:key andIV:iv error:outError];
  
  return result;
} /* of encryptWithAlgorithm: */

/**
 *
 */
-(NSData*) decryptWithAlgorithm:(TresorAlgorithmInfo*) algorithm usingKey:(NSData*)key andIV:(NSData*)iv error:(NSError **)outError
{ NSData* result = [[NSData dataWithBytes:[self UTF8String] length:[self length]] decryptWithAlgorithm:algorithm usingKey:key andIV:iv error:outError];
  
  return result; 
} /* of decryptWithAlgorithm: */

/**
 *
 */
-(NSData*)   hexString2RawValue
{ NSData*      result    = nil;
  const char*  hexString = [self UTF8String];
  unsigned int len       = (unsigned int)strlen(hexString);
  char*        buffer    = NULL;
  
  if( len%2!=0 )
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"hexString should have an even length" userInfo:nil];
  
  if( len>0 )
  { unsigned char digit[3];
    
    memset(digit,0,3);
    
    buffer = calloc(len/2+1,1);
    if( buffer==NULL )
      goto cleanUp;
    
    for( int i=0;i<len/2;i++ )
    { digit[0]  = hexString[2*i];
      digit[1]  = hexString[2*i+1];
      buffer[i] = (unsigned char)strtol((char*)digit, NULL, 16);
    } /* of for */
    
    result = [[NSData alloc] initWithBytes:buffer length:len/2 ];
  } /* of if */
cleanUp:
  free(buffer);
  
  return result;
}

/**
 *
 */
+(NSString*) stringUniqueID
{ CFUUIDRef   uuid;
  NSString*   result=nil;
 
  uuid = CFUUIDCreate(kCFAllocatorDefault);
  
  if( uuid!=NULL )
  { result = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  
    CFRelease(uuid);  
  } /* of if */
  
  return result;
}

/**
 *
 */
+(NSString*) stringPassword:(TresorCryptoPasswordT)passwordType withLength:(NSUInteger)length
{ unsigned char* buffer    = calloc(length+1, sizeof(unsigned char));
  int            bufferLen = 0;
  
  for( ;bufferLen<length; )
  { unsigned char ch = random()%256;
   
    switch( passwordType )
    {
      case NSStringPasswordDigit:
        if( isdigit(ch) )
          buffer[bufferLen++]=ch;
        break;
        
      case NSStringPasswordAlpha:
        if( isalpha(ch) )
          buffer[bufferLen++]=ch;
        break;
        
      case NSStringPasswordAlnum:
        if( isalnum(ch) )
          buffer[bufferLen++]=ch;
        break;
        
      default:
        break;
    } /* of switch */
  } /* of for */
  
  buffer[bufferLen++] = '\0';
  
  NSString* result = [NSString stringWithUTF8String:(char*)buffer];

  free(buffer);
  
  return result;
}
@end
/*=================================================END-OF-FILE============================================================================*/
