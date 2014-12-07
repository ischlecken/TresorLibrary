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
#import "Vault.h"

@class Key;

@interface Payload : NSManagedObject<PayloadItemList,Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSData*   encryptedpayload;
@property (nonatomic, retain) Vault*    vault;
@property (nonatomic, retain) NSString* cryptoiv;
@property (nonatomic, retain) NSString* cryptoalgorithm;
@property (nonatomic, retain) NSSet*    keys;

#pragma mark dao extension

-(id)          decryptedPayload;
-(BOOL)        isPayloadItemList;

+(Payload*)    payloadWithRandomKey:(NSError**)error;
+(PMKPromise*) payloadWithObject:(id)object;

@end

@interface Payload (CoreDataGeneratedAccessors)

- (void)addKeysObject:(Key *)value;
- (void)removeKeysObject:(Key *)value;
- (void)addKeys:(NSSet *)values;
- (void)removeKeys:(NSSet *)values;

@end
