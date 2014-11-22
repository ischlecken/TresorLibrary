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
 

@interface Commit ()
{
  NSArray* _payloadObjectIds;
}

@end

@implementation Commit

@dynamic createts;
@dynamic message;
@dynamic parentobjectid;
@dynamic payloadobjectid;
@dynamic vault;
@dynamic newvault;

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
-(NSString*) payloadObjectId
{ return self.payloadobjectid; }


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
-(void) setPayloadObjectId:(NSString*)value
{ self.payloadobjectid = value; }


#pragma mark messages

/**
 *
 */
-(PMKPromise*) loadPayloadObject
{ PMKPromise* promise = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
   { NSError* error = nil;
     id       obj   = [_MOC loadObjectWithObjectID:self.payloadobjectid andError:&error];
     
     if( obj && ![obj isKindOfClass:[Payload class]] )
       rejecter(_TRESORERROR(TresorErrorUnexpectedObjectClass));
     else if( obj==nil )
       rejecter(error);
     
     fulfiller(obj);
   }];
  
  return promise;
}

/**
 *
 */
-(PMKPromise*) createPayloadObject
{ PMKPromise* promise = [Payload payloadWithObject:[PayloadItemList new]]
  .then(^(Payload* payload)
  { self.payloadobjectid = [payload uniqueObjectId];
    
    [self.newvault addNewPayloadObject:payload removedPayload:nil context:@"createPayloadForCommit"];
    
    return payload;
  });
  
  return promise;
}

/**
 *
 */
-(PMKPromise*) payloadObject
{ PMKPromise* promise = self.payloadobjectid==nil ? [self createPayloadObject] : [self loadPayloadObject];
  
  return promise;
}



/**
 *
 */
-(NSString*) description
{ return [NSString stringWithFormat:@"Commit[createts:%@ message:'%@' parentobjectid:%@ payloadobjectid:%@]",self.createts,self.message,self.parentobjectid,self.payloadobjectid]; }

/**
 *
 */
-(PMKPromise*) acceptVisitor:(id)visitor
{
  PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  { if( [visitor respondsToSelector:@selector(visitCommit:andState:)] )
      [visitor visitCommit:self andState:0];
     
    fulfiller(self);
  }]
  .then(^(Commit* cm)
  { return [cm payloadObject];
  })
  .then(^(Payload* payload)
  {
    return [payload acceptVisitor:visitor];
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
  PMKPromise*     promise    = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  {
    if( path==nil )
    { rejecter(_TRESORERROR(TresorErrorPathShouldNotBeNil));
       
      return;
    } /* of if */
     
    if( self.payloadobjectid==nil && path.length>0 )
    { rejecter(_TRESORERROR(TresorErrorPathMismatch));
       
      return;
    } /* of if */
     
    fulfiller( [self payloadObject] );
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
        
        id               payload = [_MOC loadObjectWithObjectID:pi.payloadObjectId andError:&error];
        
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
{
  PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  { fulfiller(newPl);
  }];

  if( parentPath )
    for( NSUInteger ppi=1;ppi<parentPath.count;ppi++ )
      result = result.then([^(Payload* newChildPayload)
      {
        Payload*         oldChildPayload = [parentPath objectAtIndex:ppi-1];
        Payload*         payload         = [parentPath objectAtIndex:ppi];
        
        PayloadItemList* pil             = [payload decryptedPayload];
        
        if( pil==nil )
          return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
        
        PayloadItemList* newPil    = [pil updatePayload:oldChildPayload withNewPayload:newChildPayload];
        
        [parentPath replaceObjectAtIndex:ppi-1 withObject:newChildPayload];
        
        [self.newvault addNewPayloadObject:newChildPayload removedPayload:oldChildPayload context:[NSString stringWithFormat:@"updateParentPath[%ld]",(long)ppi]];
        
        return (id)[Payload payloadWithObject:newPil];
      } copy]);
  
  result = result.then(^(Payload* newPayload)
  { [self.newvault addNewPayloadObject:newPayload removedPayloadObjectId:self.payloadobjectid context:@"updateParentPath - set commit"];
    
    self.payloadobjectid = [newPayload uniqueObjectId];
    
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
-(PMKPromise*) addPayloadItemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andObject:(id)obj forPath:(NSIndexPath*)path
{ __block NSMutableArray* parentPath = nil;
  
  PMKPromise* result = [self parentPathForPath:path]
    .then(^(NSMutableArray* promisedParentPath)
    { parentPath = promisedParentPath;
     
      return [Payload payloadWithObject:obj];
    })
    .then(^(Payload* textPayload)
    { [self.newvault addNewPayloadObject:textPayload removedPayload:nil context:[NSString stringWithFormat:@"addPayloadWithTitle:%@",obj]];
      
      Payload* pl = [parentPath firstObject];
            
      if( ![pl isPayloadItemList] )
        return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
      
      PayloadItemList* pil    = [pl decryptedPayload];
     
      if( pil==nil )
        return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
      
      PayloadItem*     pi     = [[PayloadItem alloc] initWithTitle:title andSubtitle:subtitle andIcon:icon andPayloadObjectId:[textPayload uniqueObjectId]];
      PayloadItemList* newPil = [pil addItem:pi];
      PMKPromise*      newPl  = [Payload payloadWithObject:newPil];
      
      return (id)newPl;
    })
    .then(^(Payload* newPl)
    { return [self updateParentPathWithNewPayload:newPl inParentPath:parentPath];
    })
    .then(^(NSMutableArray* parentPath)
    { return self;
    });
 
  return result;
} /* of addPayloadItem: */


/**
 *
 */
-(PMKPromise*) addPayloadItemListWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon forPath:(NSIndexPath*)path
{ __block NSMutableArray* parentPath = nil;
  
  PMKPromise* result = [self parentPathForPath:path]
    .then(^(NSMutableArray* promisedParentPath)
    { parentPath = promisedParentPath;
      
      return [Payload payloadWithObject:[PayloadItemList new]];
    })
    .then(^(Payload* itemListPayload)
    { [self.newvault addNewPayloadObject:itemListPayload removedPayload:nil context:@"addPayloadItemList"];
      
      Payload* pl = [parentPath firstObject];
            
      if( ![pl isPayloadItemList] )
        return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
      
      PayloadItemList* pil    = [pl decryptedPayload];
      
      if( pil==nil )
        return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
      
      PayloadItem*     pi     = [[PayloadItem alloc] initWithTitle:title andSubtitle:subtitle andIcon:icon andPayloadObjectId:[itemListPayload uniqueObjectId]];
      PayloadItemList* newPil = [pil addItem:pi];
      PMKPromise*      newPl  = [Payload payloadWithObject:newPil];
      
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
-(PMKPromise*) updatePayloadItemWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon forPath:(NSIndexPath*)path atPosition:(NSInteger)position
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
      PayloadItem*     newPi  = [pi updateTitle:title andSubtitle:subtitle andIcon:icon];
      PayloadItemList* newPil = [pil updateItem:newPi at:position];
      PMKPromise*      newPl  = [Payload payloadWithObject:newPil];
      
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
    
    return [Payload payloadWithObject:obj];
  })
  .then(^(Payload* itemListPayload)
  { [self.newvault addNewPayloadObject:itemListPayload removedPayload:nil context:[NSString stringWithFormat:@"updatePayloadItemWithText:%@",obj]];
    
    Payload* pl = [parentPath firstObject];
    
    if( ![pl isPayloadItemList] )
      return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
    
    PayloadItemList* pil    = [pl decryptedPayload];
    
    if( pil==nil )
      return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
    
    PayloadItem*     pi     = [pil objectAtIndex:position];
    PayloadItem*     newPi  = [pi updatePayloadObjectId:[itemListPayload uniqueObjectId]];
    PayloadItemList* newPil = [pil updateItem:newPi at:position];
    PMKPromise*      newPl  = [Payload payloadWithObject:newPil];
    
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
    
    return [Payload payloadWithObject:[PayloadItemList new]];
  })
  .then(^(Payload* itemListPayload)
  { [self.newvault addNewPayloadObject:itemListPayload removedPayload:nil context:@"updatePayloadItemList"];
    
    Payload* pl = [parentPath firstObject];
    
    if( ![pl isPayloadItemList] )
      return (id) _TRESORERROR(TresorErrorUnexpectedClassInPath);
    
    PayloadItemList* pil    = [pl decryptedPayload];
    
    if( pil==nil )
      return (id) _TRESORERROR(TresorErrorPayloadIsNotDecrypted);
    
    PayloadItem*     pi     = [pil objectAtIndex:position];
    PayloadItem*     newPi  = [pi updatePayloadObjectId:[itemListPayload uniqueObjectId]];
    PayloadItemList* newPil = [pil updateItem:newPi at:position];
    PMKPromise*      newPl  = [Payload payloadWithObject:newPil];
    
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
      PMKPromise*      newPl  = [Payload payloadWithObject:newPil];
      
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
+(Commit*) commitObjectWithMessage:(NSString*)message andError:(NSError**)error
{ Commit* result = [NSEntityDescription insertNewObjectForEntityForName:@"Commit" inManagedObjectContext:_MOC];
  
  result.message  = message;
  result.createts = [NSDate date];
  
  _MOC_SAVERETURN;
}

/**
 *
 */
+(Commit*) commitObjectUsingParentCommit:(Commit*)parentCommit andError:(NSError**)error
{ Commit* result = [NSEntityDescription insertNewObjectForEntityForName:@"Commit" inManagedObjectContext:_MOC];
  
  result.message         = @"pending";
  result.createts        = [NSDate date];
  result.payloadobjectid = [parentCommit payloadobjectid];
  result.parentobjectid  = [parentCommit uniqueObjectId];
  
  _MOC_SAVERETURN;
}

@end
