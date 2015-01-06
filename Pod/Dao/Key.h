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
