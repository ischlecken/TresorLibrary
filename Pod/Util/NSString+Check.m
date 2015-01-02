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
#import "NSString+Check.h"

@implementation NSString(Check)


/**
 *
 */
-(BOOL) containsOnlyCharacter:(unichar)character
{ BOOL result = NO;
  
  if( self.length>0 )
  { result = YES;
    
    for( NSUInteger i=0;i<self.length;i++ )
    { unichar ch = [self characterAtIndex:i];
      
      if( ch!=character )
      { result = NO;
        
        break;
      } /* of if */
    } /* of for */
  } /* of if */
  
  return result;
}


@end
/*=================================================END-OF-FILE============================================================================*/
