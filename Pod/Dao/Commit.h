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
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "PayloadItem.h"
#import "PayloadItemList.h"
#import "Vault.h"
#import "TresorDaoProtokols.h"
#import "PromiseKit.h"

typedef PayloadItemList* (^UpdateParentPathHandler)(PayloadItemList* pl);

@class Payload;

@interface Commit : NSManagedObject <PayloadItem,Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSString* message;
@property (nonatomic, retain) NSString* parentcommitoid;
@property (nonatomic, retain) NSString* payloadoid;
@property (nonatomic, retain) Vault*    vault;
@property (nonatomic, retain) NSSet*    payloads;

#pragma mark dao extension

-(PMKPromise*)      payloadForPath:(NSIndexPath*)path;

-(PMKPromise*)      addPayloadItemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andObject:(id)obj forPath:(NSIndexPath*)path;
-(PMKPromise*)      addPayloadItemListWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon forPath:(NSIndexPath*)path;

-(PMKPromise*)      updatePayloadItemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andColor:(NSString*)iconcolor forPath:(NSIndexPath*)path atPosition:(NSInteger)position;
-(PMKPromise*)      updatePayloadItemWithObject:(id)obj forPath:(NSIndexPath*)path atPosition:(NSInteger)position;
-(PMKPromise*)      updatePayloadItemListForPath:(NSIndexPath*)path atPosition:(NSInteger)position;

-(PMKPromise*)      deletePayloadItemForPath:(NSIndexPath*)path atPosition:(NSInteger)position;

/**
 Generates the parent path of payload objects to the specified path
 
 @return The promise that returns the parentpath array of payload object
 */
-(PMKPromise*)      parentPathForPath:(NSIndexPath*)path;

-(PMKPromise*)      payloadObject;

+(Commit*)          commitObjectUsingParentCommit:(Commit*)parentCommit forVault:(Vault*)vault andError:(NSError**)error;
+(PMKPromise*)      createInitialCommitForVault:(Vault*)vault andMasterCryptoKey:(NSData*)decryptedMasterKey;
@end

@interface Commit (CoreDataGeneratedAccessors)

-(void)addPayloadsObject:(Payload*)value;
-(void)removePayloadsObject:(Payload*)value;
-(void)addPayloads:(NSSet*)values;
-(void)removePayloads:(NSSet*)values;

@end
