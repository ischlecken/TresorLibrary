//
//  MasterKey.h
//  Pods
//
//  Created by Feldmaus on 11.12.14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Vault;

@interface MasterKey : NSManagedObject

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSString* cryptoalgorithm;
@property (nonatomic, retain) NSData*   encryptedkey;
@property (nonatomic, retain) NSString* cryptoiv;
@property (nonatomic, retain) Vault*    vault;

@property (nonatomic, retain) NSDate*   lockts;
@property (nonatomic, retain) NSNumber* lockcount;
@property (nonatomic, retain) NSNumber* failedauthentications;
@property (nonatomic, retain) NSString* authentication;

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
