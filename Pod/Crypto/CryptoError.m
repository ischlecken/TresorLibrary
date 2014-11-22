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
#import "CryptoError.h"

NSString *const CryptoErrorDomain     = @"CryptoErrorDomain";
NSString *const CryptoErrorCoreDomain = @"CryptoErrorCoreDomain";

/**
 *
 */
void createCryptoError(NSError** outError,int errCode,NSString* description,int internalErrCode)
{ if( outError!=nil )
  { NSString*     localizedDescription = NSLocalizedStringFromTable(description,@"cryptoErrors",@"");
    
    NSError* underlyingError = nil;
    NSArray* objArray        = nil;
    NSArray* keyArray        = nil;
    
    if( internalErrCode!=0 )
    { underlyingError = [[NSError alloc] initWithDomain:CryptoErrorCoreDomain code:internalErrCode userInfo:nil];
      objArray        = [NSArray      arrayWithObjects     :localizedDescription     ,underlyingError     ,nil];
      keyArray        = [NSArray      arrayWithObjects     :NSLocalizedDescriptionKey,NSUnderlyingErrorKey,nil];
    } /* of if */
    else
    { objArray        = [NSArray      arrayWithObjects     :localizedDescription     ,nil];
      keyArray        = [NSArray      arrayWithObjects     :NSLocalizedDescriptionKey,nil];
    } /* of if */
    
    NSDictionary* eDict = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    
    *outError = [[NSError alloc] initWithDomain:CryptoErrorDomain code:errCode userInfo:eDict];
  } /* of if */
} /* of createCryptoError() */
/*============================================================================END-OF-FILE============================================================================*/
