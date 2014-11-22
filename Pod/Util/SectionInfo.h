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

@interface SectionInfo : NSObject
@property(strong,nonatomic         ) NSString* title;
@property(strong,nonatomic         ) NSString* imageName;
@property(strong,nonatomic         ) NSArray*  items;
@property(strong,nonatomic,readonly) UIImage*  image;
@property(strong,nonatomic,readonly) UIImage*  tintedImage;

+(SectionInfo*) sectionWithTitle:(NSString*)title andItems:(NSArray*)items;
+(SectionInfo*) sectionWithTitle:(NSString*)title andItems:(NSArray*)items andImageName:(NSString*)imageName;
@end

@interface MutableSectionInfo : SectionInfo
@property(strong,nonatomic) NSMutableArray* items;

+(MutableSectionInfo*) mutableSectionWithTitle:(NSString*)title;
+(MutableSectionInfo*) mutableSectionWithTitle:(NSString*)title andItems:(NSArray*)items;
+(MutableSectionInfo*) mutableSectionWithTitle:(NSString*)title andItems:(NSArray*)items andImageName:(NSString*)imageName;
@end

@interface SectionItem : NSObject
@property(assign,nonatomic) int       index;
@property(assign,nonatomic) CGFloat   height;
@property(strong,nonatomic) NSString* cellIdentifier;

+(SectionItem*) sectionItemWithIndex:(int)index;
+(SectionItem*) sectionItemWithIndex:(int)index andHeight:(CGFloat)height;
+(SectionItem*) sectionItemWithIndex:(int)index andHeight:(CGFloat)height andCellIdentifier:(NSString*)cellIdentifier;
@end
