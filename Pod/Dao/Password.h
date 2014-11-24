//
//  Password.h
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Key;

@interface Password : NSManagedObject

@property (nonatomic, retain) NSDate * createts;
@property (nonatomic, retain) NSString * kdf;
@property (nonatomic, retain) NSString * kdfparam;
@property (nonatomic, retain) NSNumber * lockcount;
@property (nonatomic, retain) NSDate * locktimestamp;
@property (nonatomic, retain) NSNumber * maxtries;
@property (nonatomic, retain) NSString * passwordsalt;
@property (nonatomic, retain) NSString * passwordtype;
@property (nonatomic, retain) NSNumber * passwordlength;
@property (nonatomic, retain) NSNumber * tries;
@property (nonatomic, retain) NSString * wrongpasswordtrategy;
@property (nonatomic, retain) NSSet *keys;

#pragma mark dao extension

+(Password*) passwordObject:(NSError**)error;

@end

@interface Password (CoreDataGeneratedAccessors)

- (void)addKeysObject:(Key *)value;
- (void)removeKeysObject:(Key *)value;
- (void)addKeys:(NSSet *)values;
- (void)removeKeys:(NSSet *)values;

@end
