//
//  Created by Stefan Thomas on 15.01.2015.
//  Copyright (c) 2015 LSSi Europe. All rights reserved.
//
#import "NSArray+SectionInfo.h"
#import "SettingsItem.h"

@implementation NSArray(SectionInfo)


/**
 *
 */
-(SectionInfo*) findSectionInfo:(NSString*)title
{ SectionInfo* result    = nil;
  
  for( NSInteger sectionNo=0;sectionNo<[self count];sectionNo++ )
    if( [[self[sectionNo] title] caseInsensitiveCompare:title]==NSOrderedSame )
    { result = self[sectionNo];
      break;
    } /* of if */
  
  return result;
}

/**
 *
 */
-(NSUInteger) findSectionInfoIndex:(NSString*)title
{ NSUInteger result = NSUIntegerMax;
  
  for( NSInteger sectionNo=0;sectionNo<[self count];sectionNo++ )
    if( [[self[sectionNo] title] caseInsensitiveCompare:title]==NSOrderedSame )
    { result = sectionNo;
      break;
    } /* of if */
  
  return result;
}

/**
 *
 */
-(NSIndexPath*) findFirstSettingItemWithCellId:(NSString*)cellId
{ NSIndexPath* result = nil;
  
  for( NSUInteger section=0;section<self.count;section++ )
  { SectionInfo* si = self[section];
    
    for( NSUInteger row=0;row<si.items.count;row++ )
    { SettingsItem* setting = si.items[row];
      NSIndexPath*  ip      = [NSIndexPath indexPathForRow:row inSection:section];
      
      if( [setting.cellId isEqualToString:cellId] )
      { result = ip;
        break;
      } /* of if */
    } /* of for */
  } /* of for */

  return result;
}


@end
