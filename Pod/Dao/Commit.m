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
#import "Commit.h"
#import "CryptoService.h"
#import "TresorModel.h"
#import "TresorError.h"
#import "TresorDaoCategories.h"
#import "Payload.h"

@interface Commit ()
{
  NSArray* _payloadObjectIds;
}

@end

@implementation Commit

@dynamic createts;
@dynamic message;
@dynamic parentcommitoid;
@dynamic payloadoid;
@dynamic vault;
@dynamic payloads;


#pragma mark dao extension

#pragma mark PayloadItem protocol

/**
 *
 */
-(NSString*) title
{ return self.message; }

/**
 *
 */
-(NSString*) subtitle
{ return nil; }

/**
 *
 */
-(NSString*) icon
{ return nil; }

/**
 *
 */
-(NSString*) iconcolor
{ return nil; }

/**
 *
 */
-(void) setTitle:(NSString*)value
{ self.message = value; }

/**
 *
 */
-(void) setSubtitle:(NSString*)value
{ }

/**
 *
 */
-(void) setIcon:(NSString*)value
{ }

/**
 *
 */
-(void) setIconcolor:(NSString*)value
{ }

/**
 *
 */
-(void) setPayloadObjectId:(NSString*)value
{ self.payloadoid = value; }


#pragma mark messages

/**
 *
 */
-(PMKPromise*) payloadObject
{ PMKPromise* promise = [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
  { NSError* error = nil;
     id       obj   = nil;
     
     if( self.payloadoid==nil )
     { error = _TRESORERROR(TresorErrorCommitPayloadoidNotSet);
       
       goto cleanup;
     } /* of if */
     
     obj = [_MOC loadObjectWithObjectID:self.payloadoid andError:&error];
     
     if( obj && ![obj isKindOfClass:[Payload class]] )
     { obj   = nil;
       error = _TRESORERROR(TresorErrorUnexpectedObjectClass);
       
       goto cleanup;
     } /* of if */
     
   cleanup:
     
     if( obj )
       resolve(obj);
     else
       resolve(error);
   }];
  
  return promise;
}



/**
 *
 */
-(NSString*) description
{ return [NSString stringWithFormat:@"Commit[createts:%@ message:'%@' parentcommitoid:%@ payloadoid:%@ vault:%@]",self.createts,self.message,self.parentcommitoid,self.payloadoid,self.vault]; }

/**
 *
 */
-(PMKPromise*) acceptVisitor:(id)visitor
{
  PMKPromise* result = [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
  { if( [visitor respondsToSelector:@selector(visitCommit:andState:)] )
      [visitor visitCommit:self andState:0];
     
    resolve(self);
  }]
  .then(^(Commit* cm)
  { return [cm payloadObject]; })
  .then(^(Payload* payload)
  { return [payload acceptVisitor:visitor];
  })
  .then(^()
  { if( [visitor respondsToSelector:@selector(visitCommit:andState:)] )
      [visitor visitCommit:self andState:1];
      
    return self;
  });
  
  return result;
}


/**
 *
 */
-(PMKPromise*) payloadForPath:(NSIndexPath*)path
{ PMKPromise* result = [self parentPathForPath:path]
  .then(^(NSMutableArray* parentPath)
  { return PMKManifold([parentPath firstObject],parentPath);
  });
  
  return result;
}

/**
 * Payload:PayloadItemList <-- commit <-- vault
 * 0 Payload:String1
 * 1 Payload:PayloadItemList
 * 1.0 Payload:String2
 * 1.1 Payload:String3
 * 1.2 Payload:PayloadItemList
 * 1.2.0 Payload:String4.0
 * 1.2.1 Payload:String4.2
 * 1.2.2 Payload:String4.3
 * 1.2.3 Payload:PayloadItemList
 * 1.2.3.0 Payload:String5.0
 * 1.2.3.1 Payload:String5.1
 * 2 Payload:String5
 *
 * parentPath: 1.2.3.0
 * [0] 1.2.3.0 Payload:String5.0
 * [1] 1.2.3 Payload:PayloadItemList
 * [2] 1.2 Payload:PayloadItemList
 * [3] 1 Payload:PayloadItemList
 * [4] Payload:PayloadItemList
 *
 */
-(PMKPromise*) parentPathForPath:(NSIndexPath*)path
{ NSMutableArray* parentPath = [[NSMutableArray alloc] initWithCapacity:5];
  PMKPromise*     promise    = [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
  { if( path==nil )
    { resolve(_TRESORERROR(TresorErrorPathShouldNotBeNil));
       
      return;
    } /* of if */
     
    if( self.payloadoid==nil && path.length>0 )
    { resolve(_TRESORERROR(TresorErrorPathMismatch));
       
      return;
    } /* of if */
     
    resolve( [self payloadObject] );
  }]
  .then(^(Payload* pl)
  { PMKPromise* decodedCommitPayload = [[CryptoService sharedInstance] decryptPayload:pl];
     
    return decodedCommitPayload;
  });
  
  if( path )
    for( NSUInteger ppi=0;ppi<path.length;ppi++ )
      promise = promise.then([^(Payload* pl)
      { if( ![pl isPayloadItemList] )
          return (id)_TRESORERROR(TresorErrorUnexpectedClassInPath);
        
        [parentPath insertObject:pl atIndex:0];
        
        NSError*         error   = nil;
        PayloadItem*     pi      = [pl objectAtIndex:[path indexAtPosition:ppi]];
        
        _NSLOG(@"[%ld,%ld]:%@",(unsigned long)ppi,(unsigned long)[path indexAtPosition:ppi],pi);
        
        id               payload = [_MOC loadObjectWithObjectID:pi.payloadoid andError:&error];
        
        if( payload==nil || ![payload isKindOfClass:[Payload class]] )
          return (id)_TRESORERROR(TresorErrorUnexpectedObjectClass);
        
        PMKPromise* decodePromise = [[CryptoService sharedInstance] decryptPayload:payload];
        
        return (id)decodePromise;
      } copy]);

  promise = promise.then(^(Payload* pl)
  { [parentPath insertObject:pl atIndex:0];
    
    return parentPath;
  });
  
  return promise;
}

/**

 * parentPath: 1.2.3
 * [0] 1.2.3 Payload:PayloadItemList
 * [1] 1.2 Payload:PayloadItemList
 * [2] 1 Payload:PayloadItemList
 * [3] Payload:PayloadItemList
 *
 * Payload:PayloadItemList         ### <-- commit <-- vault
 * 0 Payload:String1
 * 1 Payload:PayloadItemList       ###
 * 1.0 Payload:String2
 * 1.1 Payload:String3
 * 1.2 Payload:PayloadItemList     ###
 * 1.2.0 Payload:String4.0
 * 1.2.1 Payload:String4.2
 * 1.2.2 Payload:String4.3
 * 1.2.3 Payload:PayloadItemList   ###
 * 1.2.3.0 Payload:String5.0
 * 1.2.3.1 Payload:String5.1
 * 1.2.3.2 Payload:addedString     +++
 
 
 
 */
-(PMKPromise*) updateParentPathWithNewPayload:(Payload*)newPl inParentPath:(NSMutableArray*)parentPath
{ PMKPromise* result = [self payloadObject];
  
  result = result.then(^(Payload* payload)
  { [self removePayloadsObject:payload];
   
    return [PMKPromise promiseWithResolverBlock:^(PMKResolver resolve)
    { resolve(newPl); }];
  });
  
  if( parentPath )
    for( NSUInteger ppi=1;ppi<parentPath.count;ppi++ )
      result = result.then([^(Payload* newChildPayload)
      { Payload*         oldChildPayload = [parentPath objectAtIndex:ppi-1];
        Payload*         payload         = [parentPath objectAtIndex:ppi];
        PayloadItemList* pil             = [payload decryptedPayload];
        
        if( pil==nil )
          return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
        
        PayloadItemList* newPil    = [pil updatePayload:oldChildPayload withNewPayload:newChildPayload];
        
        [parentPath replaceObjectAtIndex:ppi-1 withObject:newChildPayload];
       
        [self removePayloadsObject:oldChildPayload];
        [self addPayloadsObject:newChildPayload];
        
        return (id)[[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
      } copy]);
  
  result = result.then(^(Payload* newPayload)
  { [self addPayloadsObject:newPayload];
    
    self.payloadoid = [newPayload uniqueObjectId];
    
    return parentPath;
  });
  
  return result;
}

/**
 *
 * Payload:PayloadItemList <-- commit <-- vault
 * 0 Payload:String1
 * 1 Payload:PayloadItemList
 * 1.0 Payload:String2
 * 1.1 Payload:String3
 * 1.2 Payload:PayloadItemList
 * 1.2.0 Payload:String4.0
 * 1.2.1 Payload:String4.2
 * 1.2.2 Payload:String4.3
 * 1.2.3 Payload:PayloadItemList
 * 1.2.3.0 Payload:String5.0
 * 1.2.3.1 Payload:String5.1
 * 2 Payload:String5
 *
 * parentPath: 1.2.3.0
 * [0] 1.2.3.0 Payload:String5.0
 * [1] 1.2.3 Payload:PayloadItemList
 * [2] 1.2 Payload:PayloadItemList
 * [3] 1 Payload:PayloadItemList
 * [4] Payload:PayloadItemList
 *
 * addPayloadItem:addedString forPath:1.2.3
 * Payload:PayloadItemList         ### <-- commit <-- vault
 * 0 Payload:String1
 * 1 Payload:PayloadItemList       ###
 * 1.0 Payload:String2
 * 1.1 Payload:String3
 * 1.2 Payload:PayloadItemList     ###
 * 1.2.0 Payload:String4.0
 * 1.2.1 Payload:String4.2
 * 1.2.2 Payload:String4.3
 * 1.2.3 Payload:PayloadItemList   ###
 * 1.2.3.0 Payload:String5.0
 * 1.2.3.1 Payload:String5.1
 * 1.2.3.2 Payload:addedString     +++
 * 2 Payload:String5
 */
-(PMKPromise*) addPayloadItemWithTitle:(NSString*)title
                           andSubtitle:(NSString*)subtitle
                               andIcon:(NSString*)icon
                          andIconColor:(NSString*)iconColor
                             andObject:(id)obj
                               forPath:(NSIndexPath*)path
{ __block NSMutableArray* parentPath = nil;
  
  _NSLOG(@"title:%@ subtitle:%@ object:%@ path:%@",title,subtitle,obj,path);
  
  PMKPromise* result = [self parentPathForPath:path]
    .then(^(NSMutableArray* promisedParentPath)
    { parentPath = promisedParentPath;
     
      return [[CryptoService sharedInstance] encryptObject:obj forCommit:self];
    })
    .then(^(Payload* textPayload)
    { [self addPayloadsObject:textPayload];
      
      Payload* pl = [parentPath firstObject];
            
      if( ![pl isPayloadItemList] )
        return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
      
      PayloadItemList* pil    = [pl decryptedPayload];
     
      if( pil==nil )
        return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
      
      PayloadItem*     pi     = [[PayloadItem alloc] initWithTitle:title andSubtitle:subtitle andIcon:icon andIconColor:iconColor andPayloadObjectId:[textPayload uniqueObjectId]];
      PayloadItemList* newPil = [pil addItem:pi];
      PMKPromise*      newPl  = [[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
      
      return (id)newPl;
    })
    .then(^(Payload* newPl)
    { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
    })
    .then(^(NSMutableArray* parentPath)
    { return self;
    });
 
  return result;
} /* of addPayloadItemWithTitle: */


/**
 *
 */
-(PMKPromise*) addPayloadItemListWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andIconColor:(NSString*)iconColor forPath:(NSIndexPath*)path
{ __block NSMutableArray* parentPath = nil;
  
  PMKPromise* result = [self parentPathForPath:path]
    .then(^(NSMutableArray* promisedParentPath)
    { parentPath = promisedParentPath;
      
      return [[CryptoService sharedInstance] encryptObject:[PayloadItemList new] forCommit:self];
    })
    .then(^(Payload* itemListPayload)
    { [self addPayloadsObject:itemListPayload];
            
      Payload* pl = [parentPath firstObject];
            
      if( ![pl isPayloadItemList] )
        return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
      
      PayloadItemList* pil    = [pl decryptedPayload];
      
      if( pil==nil )
        return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
      
      PayloadItem*     pi     = [[PayloadItem alloc] initWithTitle:title andSubtitle:subtitle andIcon:icon andIconColor:iconColor andPayloadObjectId:[itemListPayload uniqueObjectId]];
      PayloadItemList* newPil = [pil addItem:pi];
      PMKPromise*      newPl  = [[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
      
      return (id)newPl;
    })
    .then(^(Payload* newPl)
    { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
    })
    .then(^(NSMutableArray* parentPath)
    { return self;
    });

  return result;
}


/**
 *
 */
-(PMKPromise*) updatePayloadItemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andColor:(NSString*)iconcolor forPath:(NSIndexPath*)path atPosition:(NSInteger)position
{ __block NSMutableArray* parentPath = nil;
  
  PMKPromise* result = [self parentPathForPath:path]
    .then(^(NSMutableArray* promisedParentPath)
    { parentPath = promisedParentPath;
      
      Payload* pl = [parentPath firstObject];
            
      if( ![pl isPayloadItemList] )
        return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
      
      PayloadItemList* pil    = [pl decryptedPayload];
      
      if( pil==nil )
        return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);

      PayloadItem*     pi     = [pil objectAtIndex:position];
      PayloadItem*     newPi  = [pi updateTitle:title andSubtitle:subtitle andIcon:icon andColor:iconcolor];
      PayloadItemList* newPil = [pil updateItem:newPi at:position];
      PMKPromise*      newPl  = [[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
      
      return (id)newPl;
    })
    .then(^(Payload* newPl,Payload* pl,NSMutableArray* parentPath)
    { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
    })
    .then(^(NSMutableArray* parentPath)
    { return self;
    });

  return result;
}

/**
 *
 */
-(PMKPromise*) updatePayloadItemWithObject:(id)obj forPath:(NSIndexPath*)path atPosition:(NSInteger)position
{ __block NSMutableArray* parentPath = nil;
  
  PMKPromise* result = [self parentPathForPath:path]
  .then(^(NSMutableArray* promisedParentPath)
  { parentPath = promisedParentPath;
    
    return [[CryptoService sharedInstance] encryptObject:obj forCommit:self];
  })
  .then(^(Payload* itemListPayload)
  { [self addPayloadsObject:itemListPayload];
          
    Payload* pl = [parentPath firstObject];
    
    if( ![pl isPayloadItemList] )
      return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
    
    PayloadItemList* pil    = [pl decryptedPayload];
    
    if( pil==nil )
      return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
    
    PayloadItem*     pi     = [pil objectAtIndex:position];
    PayloadItem*     newPi  = [pi updatePayloadObjectId:[itemListPayload uniqueObjectId]];
    PayloadItemList* newPil = [pil updateItem:newPi at:position];
    PMKPromise*      newPl  = [[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
    
    return (id)newPl;
  })
  .then(^(Payload* newPl,Payload* pl,NSMutableArray* parentPath)
  { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
  })
  .then(^(NSMutableArray* parentPath)
  { return self;
  });
  
  return result;
}


/**
 *
 */
-(PMKPromise*) updatePayloadItemListForPath:(NSIndexPath*)path atPosition:(NSInteger)position
{ __block NSMutableArray* parentPath = nil;
  
  PMKPromise* result = [self parentPathForPath:path]
  .then(^(NSMutableArray* promisedParentPath)
  { parentPath = promisedParentPath;
    
    return [[CryptoService sharedInstance] encryptObject:[PayloadItemList new] forCommit:self];
  })
  .then(^(Payload* itemListPayload)
  { [self addPayloadsObject:itemListPayload];
    
    Payload* pl = [parentPath firstObject];
    
    if( ![pl isPayloadItemList] )
      return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
    
    PayloadItemList* pil    = [pl decryptedPayload];
    
    if( pil==nil )
      return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
    
    PayloadItem*     pi     = [pil objectAtIndex:position];
    PayloadItem*     newPi  = [pi updatePayloadObjectId:[itemListPayload uniqueObjectId]];
    PayloadItemList* newPil = [pil updateItem:newPi at:position];
    PMKPromise*      newPl  = [[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
    
    return (id)newPl;
  })
  .then(^(Payload* newPl,Payload* pl,NSMutableArray* parentPath)
  { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
  })
  .then(^(NSMutableArray* parentPath)
  { return self;
  });
  
  return result;
}



/**
 *
 */
-(PMKPromise*) deletePayloadItemForPath:(NSIndexPath*)path atPosition:(NSInteger)position
{ __block NSMutableArray* parentPath = nil;
  
  _NSLOG(@"path:%@ position:%ld",path,position);
  
  PMKPromise* result = [self parentPathForPath:path]
    .then(^(NSMutableArray *promisedParentPath)
    { parentPath = promisedParentPath;
      
      Payload* pl = [parentPath firstObject];
            
      if( ![pl isPayloadItemList] )
        return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
      
      PayloadItemList* pil    = [pl decryptedPayload];

      if( pil==nil )
        return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
      
      PayloadItemList* newPil = [pil deleteItemAtPosition:position];
      PMKPromise*      newPl  = [[CryptoService sharedInstance] encryptObject:newPil forCommit:self];
      
      return (id)newPl;
    })
    .then(^(Payload* newPl)
    { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
    })
    .then(^(NSMutableArray* parentPath)
    { return self;
    });

  return result;
}

/**
 *
 */
+(PMKPromise*) createInitialCommitUsingMasterCryptoKey:(NSData*)decryptedMasterKey forVault:(Vault*)vault
{ Commit* commit = [NSEntityDescription insertNewObjectForEntityForName:@"Commit" inManagedObjectContext:_MOC];
  
  commit.message         = @"Initial Commit";
  commit.createts        = [NSDate date];
  commit.parentcommitoid = nil;
  commit.vault           = vault;
  
  PMKPromise* result = [Payload payloadWithObject:[PayloadItemList new] inCommit:commit usingDecryptedMasterKey:decryptedMasterKey]
  .then(^(Payload* payload)
  { commit.payloadoid = [payload uniqueObjectId];
    
    [commit addPayloadsObject:payload];
    
    return commit;
  });

  return result;
}


/**
 *
 */
+(Commit*) commitObjectUsingParentCommit:(Commit*)parentCommit forVault:(Vault*)vault andError:(NSError**)error
{ if( parentCommit==nil )
    @throw [NSException exceptionWithName:@"ParentCommitNotSetException" reason:nil userInfo:nil];
  
  Commit* result = [NSEntityDescription insertNewObjectForEntityForName:@"Commit" inManagedObjectContext:_MOC];
  
  result.message         = @"pending";
  result.createts        = [NSDate date];
  result.payloadoid      = [parentCommit payloadoid];
  result.parentcommitoid = [parentCommit uniqueObjectId];
  result.vault           = vault;
  
  [result addPayloads:parentCommit.payloads];
  
  _MOC_SAVERETURN;
}

@end
