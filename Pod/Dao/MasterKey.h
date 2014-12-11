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
