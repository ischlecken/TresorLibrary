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

@class PMKPromise;
@protocol Visit <NSObject>
-(PMKPromise*) acceptVisitor:(id)visitor;
@end

@class Vault;
@class Commit;
@class Payload;
@class PayloadItemList;
@class PayloadItem;

@protocol Visitor <NSObject>
@optional
-(void) visitVault:(Vault*)vault andState:(NSUInteger)state;
-(void) visitCommit:(Commit*)commit andState:(NSUInteger)state;
-(void) visitPayload:(Payload*)payload andState:(NSUInteger)state;
-(void) visitPayloadItemList:(PayloadItemList*)payloadItemList andState:(NSUInteger)state;
-(void) visitPayloadItem:(PayloadItem*)payloadItem andState:(NSUInteger)state;
@end

@protocol PayloadItem <NSObject,Visit>
@property(strong,nonatomic) NSString* title;
@property(strong,nonatomic) NSString* subtitle;
@property(strong,nonatomic) NSString* icon;
@property(strong,nonatomic) NSString* payloadObjectId;
@end


@protocol PayloadItemList <NSObject>
-(NSUInteger) count;
-(id)         objectAtIndex:(NSUInteger)index;
@end
