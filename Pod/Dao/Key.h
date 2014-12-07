//
//  Key.h
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Password.h"

@class Payload;
@interface Key : NSManagedObject

@property (nonatomic, retain) NSDate*   createts;
@property (nonatomic, retain) NSString* cryptoalgorithm;
@property (nonatomic, retain) NSString* cryptoiv;
@property (nonatomic, retain) NSData*   encryptedkey;
@property (nonatomic, retain) NSString* authentication;
@property (nonatomic, retain) Payload*  payload;

#pragma mark dao extension

+(Key*) keyWithEncryptedKey:(NSData*)encryptedKey andCryptoIV:(NSString*)cryptoIV andCryptoAlgorith:(NSString*)cryptoAlgorithm andError:(NSError**)error;
+(Key*) keyWithRandomKey:(NSData*)passwordKey andKeySize:(NSUInteger)keySize andError:(NSError**)error;

@end
