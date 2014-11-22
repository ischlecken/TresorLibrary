//
//  PayloadData.h
//  Tresor
//
//  Created by Feldmaus on 19.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
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

