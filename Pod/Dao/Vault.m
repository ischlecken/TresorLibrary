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
 * Copyright (c) 2015 ischlecken.
 */
#import "Macros.h"
#import "Vault.h"
#import "Commit.h"
#import "MasterKey.h"
#import "TresorDaoCategories.h"
#import "TresorError.h"
#import "TresorUtilError.h"

@implementation VaultParameter

@end

@interface Vault ()
@end

@implementation Vault

@dynamic createts;
@dynamic modifyts;
@dynamic vaulttype;
@dynamic vaultname;
@dynamic vaulticon;
@dynamic commits;
@dynamic commitoid;
@dynamic nextcommitoid;
@dynamic masterkeys;

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
-(Commit*) headCommit
{ Commit* result = nil;
  
  for( Commit* c in self.commits )
    if( [c.uniqueObjectId isEqualToString:self.commitoid] )
    { result = c;
      
      break;
    } /* of if */
  
  return result;
}

/**
 *
 */
-(void) setHeadCommit:(Commit*)commit
{ self.commitoid = commit.uniqueObjectId;
  self.nextcommitoid = nil;
  
  dispatch_async(dispatch_get_main_queue(), ^
  { [self deleteOrphanPayloads]; });
}


/**
 *
 */
-(Commit*) useOrCreateNextCommit:(NSError**)error
{ Commit* result = self.nextCommit;
  
  if( result==nil )
  { result = [Commit commitObjectUsingParentCommit:self.headCommit forVault:self andError:error];
    
    if( result )
    { [self addCommitsObject:result];
      
      self.nextcommitoid = [result uniqueObjectId];
    } /* of if */
    
    [_MOC save:error];
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
      if( p.commits.count<=1 )
      { _NSLOG(@"delete %@",[p uniqueObjectId]);
        
        //[_MOC deleteObject:p.key];
        [_MOC deleteObject:p];
      } /* of for */
   
    [nextCommit removePayloads:nextCommit.payloads];
    
    _NSLOG(@"delete next commit %@",[nextCommit uniqueObjectId]);

    self.nextcommitoid = nil;

    [_MOC deleteObject:nextCommit];
    [_MOC save:error];
    
    [self deleteOrphanPayloads];
    
    result = YES;
  } /* of if */
  else if( error )
    *error = _TRESORERROR(TresorErrorUnknown);
  
  return result;
}


/**
 *
 */
-(void) deleteOrphanPayloads
{
#if 0
  //
  // FIXME: inperformance implementation, only load orphan payloads, use different moc
  //
  NSError*                error        = nil;
  NSFetchRequest*         fetchRequest = [[NSFetchRequest alloc] init];
  NSManagedObjectContext* moc          = _MOC; //[_TRESORMODEL createManagedObjectContext];
  
  [fetchRequest setEntity:[NSEntityDescription entityForName:@"Payload" inManagedObjectContext:moc]];
  //[fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"commits[SIZE]==0"]];
  //[fetchRequest setIncludesPropertyValues:NO];
  
  NSArray* deletedEntities = [_MOC executeFetchRequest:fetchRequest error:&error];
  
  for( Payload* p in deletedEntities )
  { //_NSLOG(@"%@ commits:%ld",[p uniqueObjectId],(long)p.commits.count);
    
    if( p.commits.count==0 )
    { _NSLOG(@"delete %@",[p uniqueObjectId]);
      
      //[moc deleteObject:p.key];
      [moc deleteObject:p];
    } /* of if */
  } /* of for */
  
  [moc save:&error];
  addToErrorList(@"could not delete orphan payloads", error, AddErrorNothing);
#else
  _NSLOG_SELECTOR;
#endif
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
  PMKPromise* result = [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
  { if( [visitor respondsToSelector:@selector(visitVault:andState:)] )
      [visitor visitVault:self andState:0];
       
    resolve(self);
  }]
  .then(^()
  { return [self.headCommit acceptVisitor:visitor];
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
+(PMKPromise*) vaultObjectWithParameter:(VaultParameter*)parameter
{ PMKPromise* result = nil;
  
  if( parameter==nil     || parameter.name==nil || parameter.type==nil ||
      parameter.pin==nil || parameter.puk==nil
    )
    result = [PMKPromise promiseWithValue:_TRESORERROR(TresorErrorMandatoryVaultParameterNotSet)];
  else if( [self findVaultByName:parameter.name andError:nil] )
    result = [PMKPromise promiseWithValue:_TRESORERROR(TresorErrorVaultNameShouldBeUnique)];
  else
  { Vault* vault  = [NSEntityDescription insertNewObjectForEntityForName:@"Vault" inManagedObjectContext:_MOC];
    
    vault.createts  = [NSDate date];
    vault.vaultname = parameter.name;
    vault.vaulttype = parameter.type;
    
    if( parameter.icon )
      vault.vaulticon = UIImagePNGRepresentation(parameter.icon);
    
    result = [MasterKey masterKeyWithVaultParameter:parameter]
    .then(^(MasterKey* pin,MasterKey* puk)
    { pin.vault = vault;
      puk.vault = vault;
      
      return [Commit createInitialCommitUsingMasterCryptoKey:parameter.masterCryptoKey forVault:vault];
    })
    .then(^(Commit* commit)
    { NSError* error = nil;
      
      [vault setHeadCommit:commit];
      
      parameter.masterCryptoKey = nil;
    
      return [_MOC save:&error] ? (id)vault : (id)error;
    })
    .catch(^(NSError* error)
    { _NSLOG(@"catch error:%@",error);
    
      [_MOC rollback];
      
      return error;
    });
  } /* of else */
  
  return result;
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
{ BOOL result = NO;
  
  _RESETERROR;
  
  if( vault )
  { for( Commit* c in vault.commits )
    { for( Payload* p in c.payloads )
        [_MOC deleteObject:p];
      
      [_MOC deleteObject:c];
    } /* of for */
    
    for( MasterKey* mk in vault.masterkeys )
      [_MOC deleteObject:mk];
    
    [_MOC deleteObject:vault];
    
    result = [_MOC save:error];
  } /* of if */
  
cleanup:
  
  return result;
}


/**
 *
 */
-(MasterKey*)  pinMasterKey
{ MasterKey* result = nil;
  
  for( MasterKey* mk in self.masterkeys )
  {
    if( [mk.authentication isEqualToString:kMasterKeyPINAuthentication] )
    {
      if( mk.lockts==nil )
      { result = mk;
        
        break;
      } /* of if */
    } /* of if */
    
  } /* of for */
  
  return result;
}

@end
