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
 *
 * Copyright (c) 2014 ischlecken.
 */
#import "Macros.h"
#import "SectionInfo.h"
#import "TresorUtil.h"

@implementation SectionInfo

/**
 *
 */
+(SectionInfo*) sectionWithTitle:(NSString*)title andItems:(NSArray*)items
{ SectionInfo* result = [[SectionInfo alloc] init];
  
  result.title = title;
  result.items = items;

  return result;
}

+(SectionInfo*) sectionWithTitle:(NSString*)title andItems:(NSArray*)items andImageName:(NSString*)imageName
{ SectionInfo* result = [[SectionInfo alloc] init];
  
  result.title     = title;
  result.items     = items;
  result.imageName = imageName;
  
  return result;
}

/**
 *
 */
-(UIImage*) image
{ UIImage* result = nil;
  
  if( self.imageName )
    result = [UIImage imageNamed:self.imageName];
  
  return result;
}

/**
 *
 */
-(UIImage*) tintedImage
{ UIImage* result = nil;
  
  if( self.imageName )
    result = [TresorUtil tintedImage:self.imageName];
  
  return result;
}
@end

@implementation MutableSectionInfo

@dynamic items;

/**
 *
 */
+(MutableSectionInfo*) mutableSectionWithTitle:(NSString*)title
{ MutableSectionInfo* result = [[MutableSectionInfo alloc] init];
  
  result.title = title;
  result.items = [[NSMutableArray alloc] initWithCapacity:13];
  
  _NSLOG(@"title=%@",title);
  
  return result;
}

/**
 *
 */
+(MutableSectionInfo*) mutableSectionWithTitle:(NSString*)title andItems:(NSArray*)items
{ MutableSectionInfo* result = [[MutableSectionInfo alloc] init];
  
  result.title = title;
  result.items = [[NSMutableArray alloc] initWithArray:items];
  
  return result;
}

/**
 *
 */
+(MutableSectionInfo*) mutableSectionWithTitle:(NSString*)title andItems:(NSArray*)items andImageName:(NSString *)imageName
{ MutableSectionInfo* result = [[MutableSectionInfo alloc] init];
  
  result.title     = title;
  result.items     = [[NSMutableArray alloc] initWithArray:items];
  result.imageName = imageName;
  
  return result;
}


@end

@implementation SectionItem

/**
 *
 */
+(SectionItem*) sectionItemWithIndex:(int)index
{ SectionItem* result = [[SectionItem alloc] init];
  
  result.index          = index;
  result.height         = 44.0f;
  result.cellIdentifier = @"Cell";
  
  return result;
}

/**
 *
 */
+(SectionItem*) sectionItemWithIndex:(int)index andHeight:(CGFloat)height
{ SectionItem* result = [[SectionItem alloc] init];
  
  result.index          = index;
  result.height         = height;
  result.cellIdentifier = @"Cell";
  
  return result;
}

/**
 *
 */
+(SectionItem*) sectionItemWithIndex:(int)index andHeight:(CGFloat)height andCellIdentifier:(NSString*)cellIdentifier
{ SectionItem* result = [[SectionItem alloc] init];
  
  result.index          = index;
  result.height         = height;
  result.cellIdentifier = cellIdentifier;
  
  return result;
}

@end