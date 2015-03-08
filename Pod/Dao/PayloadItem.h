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
 * Copyright (c) 2015 ischlecken.
 */
#import "TresorModel.h"
#import "TresorDaoProtokols.h"
#import "JSONModel.h"

@interface PayloadItem : JSONModel<PayloadItem,NSCoding,NSCopying>

-(instancetype) initWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andIconColor:(NSString*)iconColor andPayloadObjectId:(NSString*)payloadoid;

-(PayloadItem*) updateTitle:(NSString*)title;
-(PayloadItem*) updateSubtitle:(NSString*)subtitle;
-(PayloadItem*) updateIcon:(NSString*)icon;
-(PayloadItem*) updateIconColor:(NSString*)iconColor;
-(PayloadItem*) updateIcon:(NSString*)icon andColor:(NSString*)iconColor;
-(PayloadItem*) updateTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andColor:(NSString*)iconColor;
-(PayloadItem*) updatePayloadObjectId:(NSString*)payloadoid;

-(Payload*)     payload:(NSError**)error;

@end

