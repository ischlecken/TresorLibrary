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
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Audit : NSManagedObject

@property (nonatomic, retain) NSDate * createts;
@property (nonatomic, retain) NSNumber * eventid;
@property (nonatomic, retain) NSString * param1;
@property (nonatomic, retain) NSString * param2;
@property (nonatomic, retain) NSString * param3;
@property (nonatomic, retain) NSData * picture;

#pragma mark dao extension


+(Audit*) auditObjectWithEventId:(NSInteger)eventid andParam1:(NSString*)param1 andError:(NSError**)error;

@end
