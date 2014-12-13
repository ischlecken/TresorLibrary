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
@class Commit;

@interface Payload : NSManagedObject<PayloadItemList,Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSData*   encryptedpayload;
@property (nonatomic, retain) NSString* cryptoiv;
@property (nonatomic, retain) NSString* cryptoalgorithm;
@property (nonatomic, retain) Key*      key;
@property (nonatomic, retain) NSSet*    commits;

#pragma mark dao extension

-(id)          decryptedPayload;
-(BOOL)        isPayloadItemList;

+(Payload*)    payloadWithRandomKey:(NSError**)error;
+(PMKPromise*) payloadWithObject:(id)object;

@end

@interface Payload (CoreDataGeneratedAccessors)

-(void)addCommitsObject:(Commit*)value;
-(void)removeCommitsObject:(Commit*)value;
-(void)addCommits:(NSSet*)values;
-(void)removeCommits:(NSSet*)values;

@end