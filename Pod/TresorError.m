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
#import "TresorError.h"


/**
 *
 */
void createTresorError(NSError** outError,int errCode,NSString* description,int internalErrCode)
{ if( outError!=nil )
  { NSString*            localizedDescription = NSLocalizedStringFromTable(description,@"TresorError",@"");
    NSMutableDictionary* userInfo             = [[NSMutableDictionary alloc] initWithCapacity:2];
    
    [userInfo setObject:localizedDescription forKey:NSLocalizedDescriptionKey];
    
    if( internalErrCode!=0 )
    { NSError* underlyingError = [[NSError alloc] initWithDomain:kTresorErrorCoreDomain code:internalErrCode userInfo:nil];
      
      [userInfo setObject:underlyingError forKey:NSUnderlyingErrorKey];
    } /* of if */
    
    *outError = [[NSError alloc] initWithDomain:kTresorErrorDomain code:errCode userInfo:userInfo];
  } /* of if */
} /* of createTresorError() */

/*=================================================END-OF-FILE==================================================*/
