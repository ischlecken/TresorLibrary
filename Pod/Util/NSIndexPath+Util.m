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
#import "NSIndexPath+Util.h"

@implementation NSIndexPath(TresorUtil)


/**
 *
 */
+(NSIndexPath*) indexPathFromStringPath:(NSString*)stringPath
{ NSIndexPath* result = nil;
  
  if( stringPath && stringPath.length>0 )
  { NSArray* components = [stringPath componentsSeparatedByString:@"."];
    
    NSUInteger  indexArrayLength = components.count;
    NSUInteger* indexArray       = calloc(sizeof(NSUInteger), indexArrayLength);
    
    for( int i=0;i<indexArrayLength;i++ )
      indexArray[i] = [components[i] intValue];
    
    result = [[NSIndexPath alloc] initWithIndexes:indexArray length:indexArrayLength];
    
    free(indexArray);
  } /* of if */
  else
    result = [NSIndexPath new];
  
  return result;
}

@end
/*=================================================END-OF-FILE============================================================================*/
