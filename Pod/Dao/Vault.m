//
//  Vault.m
//  Tresor
//
//  Created by Feldmaus on 18.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import "Macros.h"
#import "Vault.h"
#import "Commit.h"
#import "MasterKey.h"
#import "TresorDaoCategories.h"
#import "TresorError.h"
#import "TresorUtilError.h"

@interface Vault ()
@end

@implementation Vault

@dynamic createts;
@dynamic modifyts;
@dynamic vaulttype;
@dynamic vaultname;
@dynamic vaulticon;
@dynamic commit;
@dynamic nextcommitoid;

/**
 *
 */
-(instancetype) init
{ _NSLOG_SELECTOR;
  
  self = [super init];
 
  if (self)
  {
  } /* of if */
  
  return self;
}


/**
 *
 */
-(instancetype) initWithEntity:(NSEntityDescription *)entity insertIntoManagedObjectContext:(NSManagedObjectContext *)context
{ _NSLOG_SELECTOR;
  
  self = [super initWithEntity:entity insertIntoManagedObjectContext:context];
  
  if( self )
  {
  } /* of if */
  
  return self;
}

#pragma mark dao extension


/**
 *
 */
-(Commit*) nextCommit
{ NSError* error  = nil;
  Commit*  result = (Commit*)[_MOC loadObjectWithObjectID:self.nextcommitoid andError:&error];
  
  return result;
}


/**
 *
 */
-(Commit*) useOrCreateNextCommit:(NSError**)error
{ Commit* result = self.nextCommit;
  
  if( result==nil )
  { result = [Commit commitObjectUsingParentCommit:self.commit andError:error];
    
    if( result )
      self.nextcommitoid = [result uniqueObjectId];
  } /* of if */
  
  return result;
}


/**
 *
 */
-(BOOL) cancelNextCommit:(NSError**)error
{ _NSLOG_SELECTOR;
  
  BOOL result = NO;
  
  Commit* nextCommit = self.nextCommit;
  if( nextCommit!=nil )
  { for( Payload* p in nextCommit.payloads )
    { _NSLOG(@"delete %@",[p uniqueObjectId]);
      
      [_MOC deleteObject:p.key];
      [_MOC deleteObject:p];
    } /* of for */
    
    _NSLOG(@"delete next commit %@",[nextCommit uniqueObjectId]);
    
    [_MOC deleteObject:nextCommit];
    [_MOC save:error];
    
    self.nextcommitoid = nil;
    
    result = YES;
  } /* of if */
  else if( error )
    *error = _TRESORERROR(TresorErrorUnknown);
  
  return result;
}


/**
 *
 */
-(void) didChangeValueForKey:(NSString *)key
{ [super didChangeValueForKey:key];
 
  if( [key isEqualToString:@"commit"] )
  { self.nextcommitoid = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^
    { [self deleteOrphanPayloads];
    });
  } /* of if */
}

/**
 *
 */
-(void) deleteOrphanPayloads
{ //
  // FIXME: inperformant implementation, only load orphan payloads, use different moc
  //
  NSError*                error        = nil;
  NSFetchRequest*         fetchRequest = [[NSFetchRequest alloc] init];
  NSManagedObjectContext* moc          = _MOC; //[_TRESORMODEL createManagedObjectContext];
  
  [fetchRequest setEntity:[NSEntityDescription entityForName:@"Payload" inManagedObjectContext:moc]];
  //[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"commits[SIZE]==0"]];
  //[fetchRequest setIncludesPropertyValues:NO];
  
  NSArray* deletedEntities = [_MOC executeFetchRequest:fetchRequest error:&error];
  
  for( Payload* p in deletedEntities )
  { _NSLOG(@"%@ commits:%ld",[p uniqueObjectId],(long)p.commits.count);
    
    if( p.commits.count==0 )
    { _NSLOG(@"delete %@",[p uniqueObjectId]);
      
      //[moc deleteObject:p.key];
      [moc deleteObject:p];
    } /* of if */
  } /* of for */
  
  [moc save:&error];
  addToErrorList(@"could not delete orphan payloads", error, AddErrorNothing);
}

/**
 *
 */
-(NSArray*) allCommits:(NSError**)error
{ NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:10];
  Commit*         c      = self.commit;
  
  if( c )
  { NSString* nextcommitoid = c.parentcommitoid;
    
    [result addObject:c];
    
    while( nextcommitoid )
    { c = (Commit*)[_MOC loadObjectWithObjectID:nextcommitoid andError:error];
      
      if( c )
      { [result addObject:c];
        
        nextcommitoid = c.parentcommitoid;
      } /* of if */
    } /* of while */
  } /* of if */
  
  return result;
}



/**
 *
 */
-(NSString*) description
{ NSString* result = [NSString stringWithFormat:@"Vault[vaultname:%@ vaulttype:%@]",self.vaultname,self.vaulttype];
  
  return result;
}

/**
 *
 */
-(PMKPromise*) acceptVisitor:(id)visitor
{
  PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  { if( [visitor respondsToSelector:@selector(visitVault:andState:)] )
      [visitor visitVault:self andState:0];
       
    fulfiller(self);
  }]
  .then(^()
  { return [self.commit acceptVisitor:visitor];
  })
  .then(^()
  { if( [visitor respondsToSelector:@selector(visitVault:andState:)] )
      [visitor visitVault:self andState:1];
    
    return self;
  });
  
  return result;
}

/**
 *
 */
+(Vault*) vaultObjectWithName:(NSString*)vaultName andType:(NSString*)vaultType andError:(NSError**)error
{ Vault* result = [NSEntityDescription insertNewObjectForEntityForName:@"Vault" inManagedObjectContext:_MOC];
  
  result.vaultname = vaultName;
  result.vaulttype = vaultType;
  result.createts  = [NSDate date];
  
  _MOC_SAVERETURN;
}

/**
 *
 */
+(Vault*) findVaultByName:(NSString*)vaultName andError:(NSError**)error
{ Vault* result = nil;
  
  if( vaultName )
  { _RESETERROR;
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Vault"];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"vaultname=%@",vaultName]];
    
    NSArray* fetchResult = [_MOC executeFetchRequest:fetchRequest error:error];
    
    if( fetchResult && fetchResult.count>=1 )
      result = fetchResult[0];
  } /* of if */
  
  return result;
}

/**
 *
 */
+(NSArray*) allVaults:(NSError**)error
{ _RESETERROR;
  
  return  [_MOC executeFetchRequest:[[NSFetchRequest alloc] initWithEntityName:@"Vault"] error:error];
}


/**
 * iterate all commits of vault using parentcommit relation
 * delete all payloads in a commit using commit2payload relation
 * delete all keys for payloads
 * delete all commit2payload records
 */
+(BOOL) deleteVault:(Vault*)vault andError:(NSError**)error
{ BOOL            result      = NO;
  NSArray*        allCommits  = nil;
  
  _RESETERROR;
  
  if( vault && (allCommits=[vault allCommits:error]) )
  { for( Commit* c in allCommits )
    { for( Payload* p in c.payloads )
      { for( MasterKey* mk in p.key.masterkeys )
          [_MOC deleteObject:mk];
        
        [_MOC deleteObject:p];
      } /* of for */
      
      [_MOC deleteObject:c];
    } /* of for */
    
    [_MOC deleteObject:vault];
    
    result = [_MOC save:error];
  } /* of if */
  
cleanup:
  
  return result;
}


@end
