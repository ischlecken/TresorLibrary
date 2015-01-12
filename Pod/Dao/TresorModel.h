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

#import "Vault.h"
#import "Commit.h"
#import "Payload.h"
#import "Key.h"
#import "Audit.h"
#import "PayloadItem.h"
#import "PayloadItemList.h"
#import "NSData+Crypto.h"


#define _TRESORMODEL [TresorModel sharedInstance]
#define _MOC         _TRESORMODEL.managedObjectContext
#define _TRESORQUEUE _TRESORMODEL.cryptionQueue

#define _MOC_SAVERETURN \
if( error ) \
*error = nil; \
\
return [_MOC save:error] ? result : nil; \

#define _RESETERROR \
if( error ) *error=nil; \


@interface TresorModel : NSObject

@property(readonly, strong, nonatomic) NSManagedObjectContext*       managedObjectContext;
@property(readonly, strong, nonatomic) NSManagedObjectContext*       writerManagedObjectContext;
@property(readonly, strong, nonatomic) NSManagedObjectModel*         managedObjectModel;
@property(readonly, strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property(readonly, strong, nonatomic) NSSet*                        vaultsInEditMode;
@property(readonly, strong, nonatomic) dispatch_queue_t              cryptionQueue;


+(instancetype)            sharedInstance;
-(void)                    reloadModels;
-(void)                    resetCoreDataObjects;
-(NSManagedObjectContext*) createManagedObjectContext;
-(NSManagedObjectContext*) createTemporaryManagedObjectContext;

-(BOOL)                    isVaultInEditMode:(Vault*)vault;
-(void)                    editMode:(BOOL)enable forVault:(Vault*)vault;
@end
