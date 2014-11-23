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

@interface Vault : NSManagedObject <Visit>

@property (nonatomic, retain) NSString* vaulttype;
@property (nonatomic, retain) NSString* vaultname;
@property (nonatomic, retain) NSData*   vaulticon;

@property (nonatomic, retain) Commit*   commit;
@property (nonatomic, retain) Commit*   newcommit;

#pragma mark dao extension

-(Commit*)  nextCommit:(NSError**)error;
-(BOOL)     cancelNextCommit:(NSError**)error;

-(NSArray*) allCommits:(NSError**)error;
-(NSArray*) allPayloads:(NSError**)error;

-(void)     addNewPayloadObject:(Payload*)payload removedPayload:(Payload*)removedPayload                  context:(NSString*)context;
-(void)     addNewPayloadObject:(Payload*)payload removedPayloadObjectId:(NSString*)removedPayloadObjectId context:(NSString*)context;

+(Vault*)   vaultObjectWithName:(NSString*)vaultName andType:(NSString*)vaultType andError:(NSError**)error;
+(Vault*)   findVaultByName:(NSString*)vaultName andError:(NSError**)error;
+(NSArray*) allVaults:(NSError**)error;
+(BOOL)     deleteVault:(Vault*)vault andError:(NSError**)error;


@end
