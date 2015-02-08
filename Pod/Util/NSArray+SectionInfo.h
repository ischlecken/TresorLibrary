//
//  Created by Stefan Thomas on 15.01.2015.
//  Copyright (c) 2015 LSSi Europe. All rights reserved.
//
#import "SectionInfo.h"

@interface NSArray(SectionInfo)
-(SectionInfo*) findSectionInfo:(NSString*)title;
-(NSUInteger)   findSectionInfoIndex:(NSString*)title;
-(NSIndexPath*) findFirstSettingItemWithCellId:(NSString*)cellId;

@end
