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

@interface Vault : NSManagedObject <Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSDate*   modifyts;

@property (nonatomic, retain) NSString* vaulttype;
@property (nonatomic, retain) NSString* vaultname;
@property (nonatomic, retain) NSData*   vaulticon;

@property (nonatomic, retain) NSString* nextcommitoid;

@property (nonatomic, retain) Commit*   commit;
#pragma mark dao extension

-(Commit*)  nextCommit;
-(Commit*)  useOrCreateNextCommit:(NSError**)error;
-(BOOL)     cancelNextCommit:(NSError**)error;

-(NSArray*) allCommits:(NSError**)error;

+(Vault*)   vaultObjectWithName:(NSString*)vaultName andType:(NSString*)vaultType andError:(NSError**)error;
+(Vault*)   findVaultByName:(NSString*)vaultName andError:(NSError**)error;
+(NSArray*) allVaults:(NSError**)error;
+(BOOL)     deleteVault:(Vault*)vault andError:(NSError**)error;

@end
