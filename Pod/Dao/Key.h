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

@interface Key : NSManagedObject

@property (nonatomic, retain) NSString* iv;
@property (nonatomic, retain) NSString* payloadalgorithm;
@property (nonatomic, retain) NSString* payloadiv;
@property (nonatomic, retain) NSData*   payloadkey;
@property (nonatomic, retain) Password* password;

#pragma mark dao extension


+(Key*) keyWithIV:(NSString*)iv andPayloadKey:(NSData*)payloadKey andPayloadIV:(NSString*)payloadIV andPayloadAlgorith:(NSString*)payloadAlgorithm andError:(NSError**)error;
+(Key*) keyWithRandomKey:(NSData*)passwordKey andError:(NSError**)error;

@end
