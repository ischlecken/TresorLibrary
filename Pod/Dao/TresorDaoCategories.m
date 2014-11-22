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
#import <CoreData/CoreData.h>
#import "TresorDaoCategories.h"

#pragma mark - NSManagedObjectContext (Tresor)

@implementation NSManagedObjectContext (Tresor)

/**
 *
 */
-(NSManagedObject*) loadObjectWithObjectID:(NSString*)objectId andError:(NSError**)error
{ NSManagedObject* result = nil;
  
  if( objectId )
  { NSURL*             uri      = [NSURL URLWithString:objectId];
    NSManagedObjectID* objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:uri];
    
    if( objectID )
    { NSManagedObject* objectForID = [self objectWithID:objectID];
      if (![objectForID isFault] )
      {
        result = objectForID;
      } /* of if */
      else
      { NSFetchRequest* request = [[NSFetchRequest alloc] init];
        [request setEntity:[objectID entity]];
        
        // Equivalent to
        // predicate = [NSPredicate predicateWithFormat:@"SELF = %@", objectForID];
        NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:[NSExpression expressionForEvaluatedObject]
                                                                    rightExpression:[NSExpression expressionForConstantValue:objectForID]
                                                                           modifier:NSDirectPredicateModifier
                                                                               type:NSEqualToPredicateOperatorType
                                                                            options:0];
        [request setPredicate:predicate];
        
        NSArray* results = [self executeFetchRequest:request error:error];
        if( [results count]==1 )
          result = [results objectAtIndex:0];
      } /* of else */
    } /* of if */
  } /* of if */
  
  return result;
}

@end

#pragma mark - NSManagedObject (Tresor)
@implementation NSManagedObject (Tresor)

/**
 *
 */
-(NSString*) uniqueObjectId
{ return self.objectID.URIRepresentation.description; }
@end



