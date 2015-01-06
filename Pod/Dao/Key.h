//
//  Key.h
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Payload;
@class MasterKey;

@interface Key : NSManagedObject

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSString* cryptoalgorithm;
@property (nonatomic, retain) NSString* cryptoiv;
@property (nonatomic, retain) NSData*   encryptedkey;
@property (nonatomic, retain) Payload*  payload;
@property (nonatomic, retain) NSSet*    masterkeys;

#pragma mark dao extension

+(Key*) keyWithEncryptedKey:(NSData*)encryptedKey andCryptoIV:(NSString*)cryptoIV andCryptoAlgorith:(NSString*)cryptoAlgorithm andError:(NSError**)error;
+(Key*) keyWithRandomKey:(NSData*)passwordKey andKeySize:(NSUInteger)keySize andError:(NSError**)error;

@end

@interface Key (CoreDataGeneratedAccessors)

-(void)addMasterkeysObject:(MasterKey*)value;
-(void)removeMasterkeysObject:(MasterKey*)value;
-(void)addMasterkeys:(NSSet*)values;
-(void)removeMasterkeys:(NSSet*)values;

@end
