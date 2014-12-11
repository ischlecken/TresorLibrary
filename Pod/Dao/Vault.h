//
//  Vault.h
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TresorDaoProtokols.h"

@class Commit;
@class Payload;
@class MasterKey;

@interface Vault : NSManagedObject <Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSDate*   modifyts;

@property (nonatomic, retain) NSString* vaulttype;
@property (nonatomic, retain) NSString* vaultname;
@property (nonatomic, retain) NSData*   vaulticon;

@property (nonatomic, retain) Commit*   commit;
@property (nonatomic, retain) Commit*   newcommit;

@property (nonatomic, retain) NSSet*    payloads;

@property (nonatomic, retain) NSSet*    masterkeys;

#pragma mark dao extension

-(Commit*)  nextCommit:(NSError**)error;
-(BOOL)     cancelNextCommit:(NSError**)error;

-(NSArray*) allCommits:(NSError**)error;

-(void)     addNewPayloadObject:(Payload*)payload removedPayload:(Payload*)removedPayload                  context:(NSString*)context;
-(void)     addNewPayloadObject:(Payload*)payload removedPayloadObjectId:(NSString*)removedPayloadObjectId context:(NSString*)context;

+(Vault*)   vaultObjectWithName:(NSString*)vaultName andType:(NSString*)vaultType andError:(NSError**)error;
+(Vault*)   findVaultByName:(NSString*)vaultName andError:(NSError**)error;
+(NSArray*) allVaults:(NSError**)error;
+(BOOL)     deleteVault:(Vault*)vault andError:(NSError**)error;


@end

@interface Vault (CoreDataGeneratedAccessors)

-(void)addPayloadsObject:(Payload*)value;
-(void)removePayloadsObject:(Payload*)value;
-(void)addPayloads:(NSSet*)values;
-(void)removePayloads:(NSSet*)values;

-(void)addMasterKeysObject:(MasterKey*)value;
-(void)removeMasterKeysObject:(MasterKey*)value;
-(void)addMasterKeys:(NSSet*)values;
-(void)removeMasterKeys:(NSSet*)values;

@end
