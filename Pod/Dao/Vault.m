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
#import "TresorDaoCategories.h"
 
#import "TresorError.h"

@interface Vault ()
{
  NSMutableArray* _newPayloads;
  NSMutableArray* _intermediatePayloads;
}
@end

@implementation Vault

@dynamic createts;
@dynamic modifyts;
@dynamic vaulttype;
@dynamic vaultname;
@dynamic vaulticon;
@dynamic commit;
@dynamic newcommit;
@dynamic payloads;

/**
 *
 */
-(instancetype) init
{ _NSLOG_SELECTOR;
  
  self = [super init];
 
  if (self)
  { self->_newPayloads          = [[NSMutableArray alloc] initWithCapacity:10];
    self->_intermediatePayloads = [[NSMutableArray alloc] initWithCapacity:10];
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
  { self->_newPayloads          = [[NSMutableArray alloc] initWithCapacity:10];
    self->_intermediatePayloads = [[NSMutableArray alloc] initWithCapacity:10];
  } /* of if */
  
  return self;
}

#pragma mark dao extension

/**
 *
 */
-(void)     addNewPayloadObject:(Payload*)payload removedPayload:(Payload*)removedPayload context:(NSString*)context
{ _NSLOG(@"%@:%@ --> %@",context,[removedPayload uniqueObjectId],[payload uniqueObjectId]);
  
  if( removedPayload && [self->_newPayloads containsObject:removedPayload] )
  { [self->_intermediatePayloads addObject:removedPayload];
    
    removedPayload.vault = nil;
    
    [self->_newPayloads removeObject:removedPayload];
  } /* of if */
  
  if( ![self->_newPayloads containsObject:payload] )
  { payload.vault = self;
    
    [self->_newPayloads addObject:payload];
  } /* of if */
}

/**
 *
 */
-(void)     addNewPayloadObject:(Payload*)payload removedPayloadObjectId:(NSString *)removedPayloadObjectId context:(NSString *)context
{ _NSLOG(@"%@:%@ --> %@",context,removedPayloadObjectId,[payload uniqueObjectId]);
  
  if( removedPayloadObjectId )
  { Payload* foundPayload = nil;
    
    for( Payload* p in self->_newPayloads )
      if( [[p uniqueObjectId] isEqualToString:removedPayloadObjectId] )
      { [self->_intermediatePayloads addObject:p];
        
        p.vault = nil;
        foundPayload = p;
        break;
      } /* of if */
    
    if( foundPayload )
      [self->_newPayloads removeObject:foundPayload];
  } /* of if */
  
  if( ![self->_newPayloads containsObject:payload] )
  { payload.vault = self;
    [self->_newPayloads addObject:payload];
  } /* of if */
}



/**
 *
 */
-(Commit*) nextCommit:(NSError**)error
{ Commit* result = self.newcommit;
  
  _RESETERROR;
  
  if( result==nil )
  { result = [Commit commitObjectUsingParentCommit:self.commit andError:error];
    
    if( result )
      self.newcommit = result;
  } /* of if */
  
  return result;
}


/**
 *
 */
-(BOOL) cancelNextCommit:(NSError**)error
{ BOOL result = NO;
  
  _RESETERROR;
  
  Commit* nextCommit = self.newcommit;
  if( nextCommit!=nil )
  { [self->_intermediatePayloads addObjectsFromArray:self->_newPayloads];
    
    for( Payload* p in self->_intermediatePayloads )
      [_MOC deleteObject:p];
    
  cleanup:

    [self->_newPayloads          removeAllObjects];
    [self->_intermediatePayloads removeAllObjects];
    
    [_MOC deleteObject:self.newcommit];
    [_MOC save:error];
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
  { for( Payload* p in self->_intermediatePayloads )
    { _NSLOG(@"%@",p.uniqueObjectId);
      
      [_MOC deleteObject:p];
    } /* of for */
    
  cleanup:
    [self->_newPayloads removeAllObjects];
    [self->_intermediatePayloads removeAllObjects];
    
    self.newcommit = nil;
  } /* of if */
}


/**
 *
 */
-(NSArray*) allCommits:(NSError**)error
{ NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:10];
  Commit*         c      = self.commit;
  
  if( c )
  { NSString* nextCommitObjectId = c.parentobjectid;
    
    [result addObject:c];
    
    while( nextCommitObjectId )
    { c = (Commit*)[_MOC loadObjectWithObjectID:nextCommitObjectId andError:error];
      
      if( c )
      { [result addObject:c];
        
        nextCommitObjectId = c.parentobjectid;
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
      [_MOC deleteObject:c];
    
    for( Payload* p in vault.payloads )
      [_MOC deleteObject:p];
    
    [_MOC deleteObject:vault];
    
    result = [_MOC save:error];
  } /* of if */
  
cleanup:
  
  return result;
}


@end
