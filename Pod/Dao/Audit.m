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
#import "Audit.h"
#import "TresorModel.h"

@implementation Audit

@dynamic createts;
@dynamic eventid;
@dynamic param1;
@dynamic param2;
@dynamic param3;
@dynamic picture;

#pragma mark dao extension


/**
 *
 */
-(NSString*) description
{ NSString* result = [NSString stringWithFormat:@"Audit[]"];
  
  return result;
}

/**
 *
 */
+(Audit*) auditObjectWithEventId:(NSInteger)eventid andParam1:(NSString*)param1 andError:(NSError**)error
{ Audit* result = [NSEntityDescription insertNewObjectForEntityForName:@"Audit" inManagedObjectContext:_MOC];
  
  result.createts = [NSDate date];
  result.eventid  = [NSNumber numberWithInteger:eventid];
  result.param1   = param1;
  
  _MOC_SAVERETURN;
}
@end
