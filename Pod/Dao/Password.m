//
//  Password.m
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import "Password.h"
#import "Key.h"
#import "TresorModel.h"

@implementation Password

@dynamic createts;
@dynamic kdf;
@dynamic kdfparam;
@dynamic lockcount;
@dynamic locktimestamp;
@dynamic maxtries;
@dynamic passwordsalt;
@dynamic passwordtype;
@dynamic passwordlength;
@dynamic tries;
@dynamic wrongpasswordstrategy;

#pragma mark dao extension


/**
 *
 */
-(NSString*) description
{ NSString* result = [NSString stringWithFormat:@"Password[]"];
  
  return result;
}

/**
 *
 */
+(Password*) passwordObject:(NSError**)error
{ Password* result = [NSEntityDescription insertNewObjectForEntityForName:@"Password" inManagedObjectContext:_MOC];
  
  result.createts               = [NSDate new];
  result.kdf                    = @"kdf";
  result.kdfparam               = @"10000";
  result.maxtries               = [NSNumber numberWithInteger:5];
  result.passwordsalt           = @"1234";
  result.passwordtype           = @"pin";
  result.passwordlength         = [NSNumber numberWithInteger:6];
  result.wrongpasswordstrategy  = @"lock";
  
  _MOC_SAVERETURN;
}

@end
