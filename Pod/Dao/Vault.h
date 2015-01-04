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
@class MasterKey;

@interface VaultParameter : NSObject

@property(strong,nonatomic) NSString*  name;
@property(assign,nonatomic) NSString*  type;
@property(strong,nonatomic) UIImage*   icon;
@property(strong,nonatomic) NSString*  pin;
@property(strong,nonatomic) NSString*  puk;
@property(strong,nonatomic) NSString*  kdfAlgorithm;
@property(assign,nonatomic) NSUInteger kdfIterations;
@property(strong,nonatomic) NSData*    kdfSalt;
@end


@interface Vault : NSManagedObject <Visit>

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSDate*   modifyts;

@property (nonatomic, retain) NSString* vaulttype;
@property (nonatomic, retain) NSString* vaultname;
@property (nonatomic, retain) NSData*   vaulticon;

@property (nonatomic, retain) NSString* nextcommitoid;

@property (nonatomic, retain) Commit*   commit;

@property (nonatomic, retain) NSSet*    masterkeys;

#pragma mark dao extension

-(Commit*)     nextCommit;
-(Commit*)     useOrCreateNextCommit:(NSError**)error;
-(BOOL)        cancelNextCommit:(NSError**)error;

-(NSArray*)    allCommits:(NSError**)error;

+(PMKPromise*) vaultObjectWithParameter:(VaultParameter*)parameter;
+(Vault*)      findVaultByName:(NSString*)vaultName andError:(NSError**)error;
+(NSArray*)    allVaults:(NSError**)error;
+(BOOL)        deleteVault:(Vault*)vault andError:(NSError**)error;

@end

@interface Vault (CoreDataGeneratedAccessors)

-(void)addMasterKeysObject:(MasterKey*)value;
-(void)removeMasterKeysObject:(MasterKey*)value;
-(void)addMasterKeys:(NSSet*)values;
-(void)removeMasterKeys:(NSSet*)values;

@end
