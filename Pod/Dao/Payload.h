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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PayloadItem.h"
#import "PayloadItemList.h"
#import "Vault.h"

@class Key;
@class Commit;
@class Vault;

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

-(Vault*)      vault;

-(PMKPromise*) decryptPayloadUsingDecryptedMasterKey:(NSData*)decryptedMasterKey;


+(Payload*)    payloadWithRandomKey:(NSError**)error;
+(PMKPromise*) payloadWithObject:(id)object;
@end

@interface Payload (CoreDataGeneratedAccessors)

-(void)addCommitsObject:(Commit*)value;
-(void)removeCommitsObject:(Commit*)value;
-(void)addCommits:(NSSet*)values;
-(void)removeCommits:(NSSet*)values;

@end