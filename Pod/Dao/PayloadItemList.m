#import "PayloadItemList.h"
#import "TresorDaoCategories.h"

@interface PayloadItemList ()
@property NSArray<PayloadItem>* list;
@end

@implementation PayloadItemList


/**
 *
 */
-(instancetype) init
{ self = [super init];
 
  if (self)
  { self.list = (NSArray<PayloadItem>*)[[NSArray alloc] init];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(instancetype) initWithList:(NSArray*)list
{ self = [super init];
  
  if (self)
  { self.list = (NSArray<PayloadItem>*)[[NSArray alloc] initWithArray:list];
  } /* of if */
  
  return self;
}


/**
 *
 */
-(id) initWithCoder:(NSCoder*)decoder
{ self = [super init];
  
  if( self )
  { self.list = [decoder decodeObjectForKey:@"list"];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(void) encodeWithCoder:(NSCoder*)encoder
{ [encoder encodeObject:self.list forKey:@"list"];
}

#pragma mark PayloadItemList protocol

/**
 *
 */
-(NSUInteger) count
{ return self.list.count; }

/**
 *
 */
-(id) objectAtIndex:(NSUInteger)index
{ return [self.list objectAtIndex:index]; }


#pragma mark manipulate messages

/**
 *
 */
-(PayloadItemList*) addItem:(PayloadItem*)item
{ PayloadItemList* result = nil;
  
  if( item )
  { NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:self.list.count+1];
    
    [list addObjectsFromArray:self.list];
    [list addObject:item];
    
    result = [[PayloadItemList alloc] initWithList:list];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(PayloadItemList*) insertItem:(PayloadItem*)item at:(NSInteger)position
{ PayloadItemList* result = nil;
  
  if( item )
  { NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:self.list.count+1];
    
    NSUInteger pos=0;
    for( id i in self.list )
    { if( pos==position )
        [list addObject:item];
      
      [list addObject:i];
      pos++;
    } /* of for */
    
    result = [[PayloadItemList alloc] initWithList:list];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(PayloadItemList*) updateItem:(PayloadItem*)item at:(NSInteger)position
{ PayloadItemList* result = nil;
  
  if( item )
  { NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:self.list.count];
    
    NSUInteger pos=0;
    for( id i in self.list )
    { if( pos==position )
        [list addObject:item];
      else
        [list addObject:i];
      
      pos++;
    } /* of for */
    
    result = [[PayloadItemList alloc] initWithList:list];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(PayloadItemList*) updatePayload:(Payload*)payload withNewPayload:(Payload*)newPayload
{ PayloadItemList* result = nil;

  if( payload )
  { NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:self.list.count];
    
    NSString* payloadoid = [payload uniqueObjectId];
    for( PayloadItem* pi in self.list )
    {
      if( [pi.payloadoid isEqual:payloadoid] )
      { PayloadItem* newPi = [pi updatePayloadObjectId:[newPayload uniqueObjectId]];
        
        [list addObject:newPi];
      } /* of if */
      else
        [list addObject:pi];
      
    } /* of for */
    
    result = [[PayloadItemList alloc] initWithList:list];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(PayloadItemList*) deleteItem:(PayloadItem*)item
{ PayloadItemList* result = nil;
  
  if( item )
  { NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:self.list.count-1];
    
    for( id i in self.list )
      if( ![i isEqual:item] )
        [list addObject:i];
    
    result = [[PayloadItemList alloc] initWithList:list];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(PayloadItemList*) deleteItemAtPosition:(NSInteger)position
{ PayloadItemList* result = nil;
  
  if( position>=0 )
  { NSMutableArray* list = [[NSMutableArray alloc] initWithCapacity:self.list.count];
    
    for( int i=0;i<self.list.count;i++ )
      if( i!=position )
        [list addObject:self.list[i]];
    
    result = [[PayloadItemList alloc] initWithList:list];
  } /* of if */
  
  return result;

  
}

/**
 *
 */
-(NSString*) description
{ NSMutableString* result = [NSMutableString stringWithCapacity:256];
  
  [result appendString:@"PayloadItemList["];
  
  [result appendFormat:@"size:%lu",(unsigned long)self.list.count];
  
  [result appendString:@"]"];
  return result;
}


/**
 *
 */
-(id) copyWithZone:(NSZone *)zone
{ PayloadItemList* result = [[PayloadItemList alloc] initWithList:self.list];
  
  return result;
}

/**
 *
 */
-(PMKPromise*) acceptVisitor:(id)visitor
{
  PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  { if( [visitor respondsToSelector:@selector(visitPayloadItemList:andState:)] )
      [visitor visitPayloadItemList:self andState:0];
    
    fulfiller(self);
  }];
  
  for( PayloadItem* pi in self.list )
    result = result.then(^(){ return [pi acceptVisitor:visitor]; });
  
  result = result
  .then(^()
  { if( [visitor respondsToSelector:@selector(visitPayloadItemList:andState:)] )
      [visitor visitPayloadItemList:self andState:1];
  });
  
  return result;
}
@end
