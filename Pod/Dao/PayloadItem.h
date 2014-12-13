//
//  PayloadData.h
//  Tresor
//
//  Created by Feldmaus on 19.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import "TresorModel.h"
#import "TresorDaoProtokols.h"
#import "JSONModel.h"

@interface PayloadItem : JSONModel<PayloadItem,NSCoding,NSCopying>

-(instancetype) initWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andPayloadObjectId:(NSString*)payloadoid;

-(PayloadItem*) updateTitle:(NSString*)title;
-(PayloadItem*) updateSubtitle:(NSString*)subtitle;
-(PayloadItem*) updateIcon:(NSString*)icon;
-(PayloadItem*) updateTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon;
-(PayloadItem*) updatePayloadObjectId:(NSString*)payloadoid;

-(Payload*)     payload:(NSError**)error;

@end

