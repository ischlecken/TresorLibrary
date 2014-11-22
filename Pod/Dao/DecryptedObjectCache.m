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
 * Copyright (c) 2014 ischlecken.
 */
#import "Macros.h"
#import "DecryptedObjectCache.h"

@interface DecryptedObjectCache ()
@property NSMutableDictionary* cache;
@end

@implementation DecryptedObjectCache

/**
 *
 */
-(instancetype) init
{ self = [super init];
  
  if( self )
  { self.cache      = [[NSMutableDictionary alloc] initWithCapacity:256];
  } /* of if */
  
  return self;
}

/**
 * TODO: purge decoded objects
 */
-(void) flush
{ _NSLOG_SELECTOR;
  
  self.cache      = [[NSMutableDictionary alloc] initWithCapacity:256];
}

/**
 *
 */
-(id) decryptedObjectForUniqueId:(NSString*)uniqueId
{ id result = [self.cache objectForKey:uniqueId];
  
 // _NSLOG(@"%@:%@",uniqueId,(result!=nil ? @"found" : @"not found"));
  
  return result;
}


/**
 *
 */
-(void) setDecryptedObject:(id)object forUniqueId:(NSString*)uniqueId
{ [self.cache setObject:object forKey:uniqueId]; }


/**
 *
 */
+(DecryptedObjectCache*) sharedInstance
{ static DecryptedObjectCache* _inst = nil;
  static dispatch_once_t       oncePredicate;
  
  dispatch_once(&oncePredicate, ^{ _inst = [self new]; });
  
  return _inst;
}
@end


