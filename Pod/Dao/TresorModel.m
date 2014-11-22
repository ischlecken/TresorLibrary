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
#import "TresorModel.h"
#import "TresorUtilError.h"
#import "TresorDaoCategories.h"

#pragma mark - TresorModel

@interface TresorModel ()
{ NSMutableSet* _vaultsInEditMode;
}
@end

@implementation TresorModel

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize writerManagedObjectContext = _writerManagedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize cryptionQueue              = _cryptionQueue;

/**
 *
 */
+(instancetype) sharedInstance
{ static dispatch_once_t once;
  static TresorModel*    sharedInstance;
  
  dispatch_once(&once, ^{ sharedInstance = [self new]; });
  
  return sharedInstance;
}

/**
 *
 */
-(instancetype) init
{ self = [super init];
 
  if (self)
  { self->_vaultsInEditMode = [[NSMutableSet alloc] initWithCapacity:10];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(void) reloadModels
{ _NSLOG_SELECTOR;
  
}


#pragma mark Core Data

/**
 *
 */
-(void) resetCoreDataObjects
{ [_managedObjectContext reset];
  _managedObjectContext       = nil;
  
  _managedObjectModel         = nil;
  
  if( _persistentStoreCoordinator )
  { [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresWillChangeNotification       object:_persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreCoordinatorStoresDidChangeNotification        object:_persistentStoreCoordinator];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:_persistentStoreCoordinator];
  } /* of if */
  
  _persistentStoreCoordinator = nil;
}


/**
 *
 */
-(NSManagedObjectModel*) managedObjectModel
{ if( _managedObjectModel==nil )
  {
#if 0
    NSBundle* mainBundle = [NSBundle mainBundle];
#else
    NSBundle* mainBundle = [NSBundle bundleForClass:[self class]];
#endif
    
    _NSLOG(@"bundlePath=<%@>",mainBundle.bundlePath);
    
    NSURL* modelURL = [mainBundle URLForResource:@"Tresor" withExtension:@"momd"];
    
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  } /* of if */
  
  return _managedObjectModel;
}

/**
 *
 */
-(NSPersistentStoreCoordinator*) persistentStoreCoordinator
{ if( _persistentStoreCoordinator==nil )
  { _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  
    if( [self.delegate iCloudAvailable] && [self.delegate useCloud] )
    { NSPersistentStoreCoordinator* psc = _persistentStoreCoordinator;
      
      BOOL result = [self addLocalSQLiteStoreWithURL:[self.delegate keysDatabaseStoreURL] usingConfiguration:@"Keys" toPersistentStoreCoordinator:_persistentStoreCoordinator];
      
      // to download preexisting iCloud content
      if( result )
      { [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storesWillChange:)
                                                     name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                                   object:psc];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(storesDidChange:)
                                                     name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                   object:psc];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(persistentStoreDidImportUbiquitousContentChanges:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:psc];

        [self addCloudSQLiteStoreWithURL:[self.delegate dataDatabaseStoreURL] usingConfiguration:@"Data" toPersistentStoreCoordinator:psc];
      } /* of if */
    } /* of if */
    else
    { BOOL result = YES; // [self addLocalSQLiteStoreWithURL:[self.delegate keysDatabaseStoreURL] usingConfiguration:@"Keys" toPersistentStoreCoordinator:_persistentStoreCoordinator];
      
      if( result )
        result = [self addLocalSQLiteStoreWithURL:[self.delegate dataDatabaseStoreURL] usingConfiguration:nil toPersistentStoreCoordinator:_persistentStoreCoordinator];
    } /* of else */
  } /* of if */
  
  return _persistentStoreCoordinator;
}



/**
 *
 */
-(BOOL) addLocalSQLiteStoreWithURL:(NSURL*)storeURL usingConfiguration:(NSString*)configuration toPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)psc
{ NSError*           error    = nil;
  NSDictionary*      options  = @{ NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool:YES],
                                   NSInferMappingModelAutomaticallyOption       : [NSNumber numberWithBool:YES]
                                   };
  NSPersistentStore* ps       = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                  configuration:configuration
                                                            URL:storeURL
                                                        options:options
                                                          error:&error];
  
  //if( ps==nil && [error.domain isEqualToString:NSCocoaErrorDomain] && error.code==NSPersistentStoreIncompatibleVersionHashError )
  
  addToErrorList(@"addLocalSQLiteStoreWithURL failed", error, AddErrorAlert);
  
  return ps!=nil;
}


/**
 *
 */
-(BOOL) addCloudSQLiteStoreWithURL:(NSURL*)storeURL usingConfiguration:(NSString*)configuration toPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)psc
{ NSError*       error                = nil;
  NSURL*         transactionLogsURL   = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
  NSString*      coreDataCloudContent = [[transactionLogsURL path] stringByAppendingPathComponent:@"CoreDataLogs"];
  NSDictionary*  options              = @{ NSPersistentStoreUbiquitousContentNameKey    : @"tresor",
                                           NSPersistentStoreUbiquitousContentURLKey     : [NSURL fileURLWithPath:coreDataCloudContent],
                                           NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool:YES]
                                         };
  
  //[psc lock];
  BOOL result = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:configuration URL:storeURL options:options error:&error]!=nil;
  //[psc unlock];
  
  if( !result )
    addToErrorList(@"addCloudSQLiteStoreWithName failed", error, AddErrorNothing);
  
  return result;
}


/**
 *
 */
-(NSManagedObjectContext*) managedObjectContext
{ if( _managedObjectContext==nil && [self persistentStoreCoordinator]!=nil )
  { NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    
#if 1
    [moc setPersistentStoreCoordinator: [self persistentStoreCoordinator]];
#else
    moc.parentContext = [self writerManagedObjectContext];
#endif
    
    if( [self.delegate iCloudAvailable] && [self.delegate useCloud] )
      [moc performBlockAndWait:
       ^{
         // configure context properties
         [moc setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType] ];
       }];
        
    _managedObjectContext = moc;
  } /* of if */
  
  return _managedObjectContext;
}

/**
 *
 */
-(NSManagedObjectContext*) writerManagedObjectContext
{ if( _writerManagedObjectContext==nil && [self persistentStoreCoordinator]!=nil )
  { NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    
    [moc setPersistentStoreCoordinator: [self persistentStoreCoordinator]];
    
    _writerManagedObjectContext = moc;
  } /* of if */
  
  return _writerManagedObjectContext;
}

/**
 *
 */
-(NSManagedObjectContext*) createTemporaryManagedObjectContext
{ NSManagedObjectContext* moc = nil;
  
  if( [self persistentStoreCoordinator]!=nil )
  { NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  
    moc.parentContext = self.managedObjectContext;
  } /* of if */
  
  return moc;
}


/**
 * Subscribe to NSPersistentStoreDidImportUbiquitousContentChangesNotification
 */
-(void) persistentStoreDidImportUbiquitousContentChanges:(NSNotification*)notification
{ _NSLOG(@"%@", notification);
  
  NSManagedObjectContext* moc = [self managedObjectContext];
  
  [moc performBlock:^{ [self mergeiCloudChanges:notification forContext:moc]; }];
}

/**
 * Subscribe to NSPersistentStoreCoordinatorStoresWillChangeNotification
 * most likely to be called if the user enables / disables iCloud
 * (either globally, or just for your app) or if the user changes
 * iCloud accounts.
 */
-(void) storesWillChange:(NSNotification*)notification
{ _NSLOG(@"%@", notification);
  
  NSManagedObjectContext* moc = [self managedObjectContext];
  
  [moc performBlock:^{
    NSError *error;
		
    if( [moc hasChanges] )
    { BOOL success = [moc save:&error];
      
      if( !success && error )
        addToErrorList(@"Saving data reported an error in 'store will change' context",error,AddErrorNothing);
    } /* of if */
  }];
}

/**
 * Subscribe to NSPersistentStoreCoordinatorStoresDidChangeNotification
 */
-(void) storesDidChange:(NSNotification*)notification
{ _NSLOG(@"%@", notification);
  
  dispatch_async(dispatch_get_main_queue(),^{
    [self reloadModels];
  });
}

/**
 *
 */
-(void) mergeiCloudChanges:(NSNotification*)notification forContext:(NSManagedObjectContext*)moc
{ _NSLOG(@"mergeiCloudChanges:notification=%@",notification);
  
  [moc mergeChangesFromContextDidSaveNotification:notification];
  
  [self reloadModels];
}

#pragma mark DAO


/**
 *
 */
-(BOOL) isVaultInEditMode:(Vault*)vault
{ NSString* vaultId = [vault uniqueObjectId];
  BOOL      result  = [self.vaultsInEditMode containsObject:vaultId];
  
  return result;
}

/**
 *
 */
-(void) editMode:(BOOL)enable forVault:(Vault*)vault
{ NSString* vaultId = [vault uniqueObjectId];
  
  [self willChangeValueForKey:@"vaultsInEditMode"];
  
  if( enable )
    [self->_vaultsInEditMode addObject:vaultId];
  else
    [self->_vaultsInEditMode removeObject:vaultId];
  
  [self didChangeValueForKey:@"vaultsInEditMode"];
}

/**
 *
 */
-(dispatch_queue_t) cryptionQueue
{ if( _cryptionQueue==nil )
    _cryptionQueue = dispatch_queue_create("tresor.cryptionQueue", DISPATCH_QUEUE_SERIAL);
  
  return _cryptionQueue;
}

@end
