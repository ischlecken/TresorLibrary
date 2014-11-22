//
//  Payload.h
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PayloadItem.h"
#import "PayloadItemList.h"
#import "Key.h"

@interface Payload : NSManagedObject<PayloadItemList,Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSData*   encryptedpayload;
@property (nonatomic, retain) NSString* keyobjectid;
@property (nonatomic, retain) NSString* vaultobjectid;

#pragma mark dao extension

-(id)          decryptedPayload;
-(BOOL)        isPayloadItemList;

+(Payload*)    payloadWithKey:(Key*)key andError:(NSError**)error;
+(Payload*)    payloadWithRandomKey:(NSError**)error;
+(PMKPromise*) payloadWithObject:(id)object;

@end
