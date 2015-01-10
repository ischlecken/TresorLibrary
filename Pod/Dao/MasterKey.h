//
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
#import <CoreData/CoreData.h>
#import "PromiseKit.h"

#define kTresorKeychainServiceName @"net.ischlecken.tresor.masterkeys"

@class Key;
@class Vault;

@interface MasterKey : NSManagedObject
@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSString* cryptoalgorithm;
@property (nonatomic, retain) NSString* keychainid4encryptedkey;
@property (nonatomic, retain) NSString* cryptoiv;
@property (nonatomic, retain) NSDate*   lockts;
@property (nonatomic, retain) NSNumber* lockcount;
@property (nonatomic, retain) NSNumber* failedauthentications;
@property (nonatomic, retain) NSString* authentication;
@property (nonatomic, retain) NSString* kdfsalt;
@property (nonatomic, retain) NSString* kdf;
@property (nonatomic, retain) NSNumber* kdfiterations;
@property (nonatomic, retain) NSSet*    keys;
@property (nonatomic, retain) Vault*    vault;

+(PMKPromise*) masterKeyWithPin:(NSString*)pin andPUK:(NSString*)puk;
-(PMKPromise*) decryptedMasterKeyUsingPIN:(NSString*)pin;
@end

@interface MasterKey (CoreDataGeneratedAccessors)
-(void)addKeysObject:(Key*)value;
-(void)removeKeysObject:(Key*)value;
-(void)addKeys:(NSSet*)values;
-(void)removeKeys:(NSSet*)values;
@end

/**

 Usecases:
 
 1. create vault
    --> create a random masterkey, encrypt with key derived from password/pin
    --> later store encryptedkey not in sqlite db, but in secure keychain
 
 2. add payload
    --> create key encrypted with masterkey

 3. change password/pin
    --> reencrypt masterkey using new key derived from password/pin
 
 4. rescue key
    --> create second masterkey entry with encrypted masterkey using a 
        random password/pin that is displayed to the user
 
 5. authentication failed
    --> lock corresponding password/pin masterkey for a period of time
    --> delete masterkey after n locks
    --> unlock vault using rescue key
 
 6. change masterkey
    --> decrypt all keys using this masterkey and encrypt with new masterkey
 
 7. use of many masterkeys
    --> link key to corresponding masterkey
 
 */
