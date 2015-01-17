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

@property(strong,nonatomic) NSData*    masterCryptoKey;
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
-(MasterKey*)  pinMasterKey;

+(PMKPromise*) vaultObjectWithParameter:(VaultParameter*)parameter;
+(Vault*)      findVaultByName:(NSString*)vaultName andError:(NSError**)error;
+(NSArray*)    allVaults:(NSError**)error;
+(BOOL)        deleteVault:(Vault*)vault andError:(NSError**)error;

@end


@interface Vault (CoreDataGeneratedAccessors)
-(void)addMasterkeysObject:(MasterKey *)value;
-(void)removeMasterkeysObject:(MasterKey *)value;
-(void)addMasterkeys:(NSSet *)values;
-(void)removeMasterkeys:(NSSet *)values;
@end
