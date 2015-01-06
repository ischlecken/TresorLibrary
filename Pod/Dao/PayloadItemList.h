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
#import "PayloadItem.h"
#import "TresorDaoProtokols.h"
#import "JSONModel.h"

@interface PayloadItemList : JSONModel<PayloadItemList,NSCoding,NSCopying,Visit>
-(PayloadItemList*) addItem:(PayloadItem*)item;
-(PayloadItemList*) insertItem:(PayloadItem*)item at:(NSInteger)position;
-(PayloadItemList*) updateItem:(PayloadItem*)item at:(NSInteger)position;
-(PayloadItemList*) updatePayload:(Payload*)payload withNewPayload:(Payload*)newPayload;
-(PayloadItemList*) deleteItem:(PayloadItem*)item;
-(PayloadItemList*) deleteItemAtPosition:(NSInteger)position;
@end

