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
#import "TresorConfig.h"

#pragma mark - TresorModel

@interface TresorModel ()
{ NSMutableSet* _vaultsInEditMode;
  NSURL*        _ubiquityContainerURL;

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
  _managedObjectContext = nil;
  _managedObjectModel   = nil;
  
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
  { NSURL* databaseStoreURL = _TRESORCONFIG.databaseStoreURL;
  
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storesWillChange:)
                                                 name:NSPersistentStoreCoordinatorStoresWillChangeNotification
                                               object:_persistentStoreCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(storesDidChange:)
                                                 name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                               object:_persistentStoreCoordinator];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(persistentStoreDidImportUbiquitousContentChanges:)
                                                 name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                               object:_persistentStoreCoordinator];

    if( _TRESORCONFIG.useCloud )
      [self ubiquityContainerURL:^(BOOL available, NSURL *url)
       { _NSLOG(@"ubiquityURL:%@ add icloud store",url);
         
         if( available && url!=nil )
           [self addCloudSQLiteStoreWithURL:databaseStoreURL usingConfiguration:nil forUbiquityURL:url toPersistentStoreCoordinator:_persistentStoreCoordinator];
         else
           [self addSQLiteStoreWithURL:databaseStoreURL usingConfiguration:nil toPersistentStoreCoordinator:_persistentStoreCoordinator];
       }];
     else
       [self addSQLiteStoreWithURL:databaseStoreURL usingConfiguration:nil toPersistentStoreCoordinator:_persistentStoreCoordinator];
  } /* of if */
  
  return _persistentStoreCoordinator;
}



/**
 *
 */
-(BOOL) addSQLiteStoreWithURL:(NSURL*)storeURL usingConfiguration:(NSString*)configuration toPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)psc
{ BOOL __block       result   = NO;
  
  [psc performBlockAndWait:^
  { NSDictionary*      options  = @{ NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool:YES],
                                     NSInferMappingModelAutomaticallyOption       : [NSNumber numberWithBool:YES],
                                     NSPersistentStoreFileProtectionKey           : NSFileProtectionComplete,
                                     NSSQLitePragmasOption                        : @{@"journal_mode" : @"DELETE"}
                                   };
    NSError*           error    = nil;
  
    result = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:configuration URL:storeURL options:options error:&error]!=nil;
 
    addToErrorList(@"addSQLiteStoreWithURL failed", error, AddErrorAlert);
  }];
  
  return result;
}


/**
 *
 */
-(BOOL) addCloudSQLiteStoreWithURL:(NSURL*)storeURL usingConfiguration:(NSString*)configuration forUbiquityURL:(NSURL*)ubiquityURL toPersistentStoreCoordinator:(NSPersistentStoreCoordinator*)psc
{ BOOL __block       result   = NO;
  
  [psc performBlockAndWait:^
  { NSError*       error                = nil;
    NSURL*         transactionLogsURL   = ubiquityURL;
    NSString*      coreDataCloudContent = [[transactionLogsURL path] stringByAppendingPathComponent:@"CoreDataLogs"];
    NSDictionary*  options              = @{ NSPersistentStoreUbiquitousContentNameKey    : @"tresor",
                                             NSPersistentStoreUbiquitousContentURLKey     : [NSURL fileURLWithPath:coreDataCloudContent],
                                             NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool:YES],
                                             NSPersistentStoreFileProtectionKey           : NSFileProtectionComplete,
                                             NSSQLitePragmasOption                        : @{@"journal_mode" : @"DELETE"}
                                           };
    
    result = [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:configuration URL:storeURL options:options error:&error]!=nil;
    
    addToErrorList(@"addCloudSQLiteStoreWithName failed", error, AddErrorNothing);
  }];
  
  return result;
}

/**
 *
 */
-(NSURL*) ubiquityContainerURL:(void (^)(BOOL available,NSURL* url))completion
{ if( _ubiquityContainerURL==nil )
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  { _ubiquityContainerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
   
    _NSLOG(@"ubiquityContainerURL:%@",_ubiquityContainerURL);
   
    BOOL iCloudAvailable = _ubiquityContainerURL!=nil ;
   
    dispatch_async(dispatch_get_main_queue(), ^{ completion(iCloudAvailable,_ubiquityContainerURL); });
 });
  
  return _ubiquityContainerURL;
}



/**
 *
 */
-(NSManagedObjectContext*) managedObjectContext
{ if( _managedObjectContext==nil )
    _managedObjectContext = [self createManagedObjectContext];
  
  return _managedObjectContext;
}

/**
 *
 */
-(NSManagedObjectContext*) createManagedObjectContext
{ NSManagedObjectContext* moc = nil;
  
  if( [self persistentStoreCoordinator]!=nil )
  { moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  
#if 1
    [moc setPersistentStoreCoordinator: [self persistentStoreCoordinator]];
#else
    moc.parentContext = [self writerManagedObjectContext];
#endif
  
  [moc performBlockAndWait:
   ^{
     // configure context properties
     [moc setMergePolicy:[[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType] ];
   }];
} /* of if */
  
  return moc;
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
