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
#import "NSSensitiveData.h"
#import "TresorError.h"
#import "NSData+Crypto.h"

@interface NSSensitiveData ()
{ NSData* _data;
  NSData* _key;
}
@end


@implementation NSSensitiveData

/**
 *
 */
-(NSData*) encode:(NSData*)dataBuffer
{ NSData*        result = [[NSData alloc] initWithData:dataBuffer];
  unsigned char* rData  = (unsigned char*)[result bytes];
  int            len    = (int)[dataBuffer length];
  unsigned char* data   = (unsigned char*)[dataBuffer bytes];
  int            keyLen = (unsigned int)[_key length];
  unsigned char* keyData= (unsigned char*)[_key bytes];
  
  for( int i=0;i<len;i++ )
  { unsigned char byte        = data[i];
    unsigned char key         = keyData[i%keyLen] ^ (0xff & i);
    unsigned char encodedByte = byte ^ key;
    
    rData[i] = encodedByte;
  } /* of for */
  
  return result;
}


/**
 *
 */
-(id) initWithData:(NSData *)data
{ self = [self init];
  
  if( self )
  { self->_key  = [[NSData alloc] initWithRandom:32];
    self->_data = [self encode:data];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(NSData*) sensitiveData
{ return [self encode:_data]; }
@end
/*====================================================END-OF-FILE==========================================================*/
