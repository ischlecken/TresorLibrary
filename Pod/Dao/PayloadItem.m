#import "PayloadItem.h"
#import "TresorModel.h"
#import "TresorDaoCategories.h"



@implementation PayloadItem

@synthesize title=_title,subtitle=_subtitle,icon=_icon,payloadObjectId=_payloadObjectId;

/**
 *
 */
-(instancetype) init
{ self = [super init];
 
  if( self )
  { _title             = nil;
    _subtitle          = nil;
    _icon              = nil;
    _payloadObjectId   = nil;
  } /* of if */
  
  return self;
}


/**
 *
 */
-(instancetype) initWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andPayloadObjectId:(NSString*)payloadObjectId
{ self = [self init];
  
  if( self )
  { _title             = title;
    _subtitle          = subtitle;
    _icon              = icon;
    _payloadObjectId   = payloadObjectId;
  } /* of if */
  
  return self;
}

/**
 *
 */
-(id) initWithCoder:(NSCoder*)decoder
{ self = [super init];
  
  if( self )
  { _title             = [decoder decodeObjectForKey :@"title"];
    _subtitle          = [decoder decodeObjectForKey :@"subtitle"];
    _icon              = [decoder decodeObjectForKey :@"icon"];
    _payloadObjectId   = [decoder decodeObjectForKey :@"payloadObjectId"];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(void) encodeWithCoder:(NSCoder*)encoder
{ [encoder encodeObject :self.title             forKey:@"title"];
  [encoder encodeObject :self.subtitle          forKey:@"subtitle"];
  [encoder encodeObject :self.icon              forKey:@"icon"];
  [encoder encodeObject :self.payloadObjectId   forKey:@"payloadObjectId"];
}

/**
 *
 */
-(id) copyWithZone:(NSZone *)zone
{ PayloadItem* result = [[PayloadItem allocWithZone:zone] init];
  
  result->_title             = self.title;
  result->_subtitle          = self.subtitle;
  result->_icon              = self.icon;
  result->_payloadObjectId   = self.payloadObjectId;
  
  return result;
}

/**
 *
 */
-(PayloadItem*) updateTitle:(NSString*)title
{ PayloadItem* result = [self copy];
  
  result->_title = title;
  
  return result;
}

/**
 *
 */
-(PayloadItem*) updateSubtitle:(NSString*)subtitle
{ PayloadItem* result = [self copy];
  
  result->_subtitle = subtitle;
  
  return result;
}

/**
 *
 */
-(PayloadItem*) updateIcon:(NSString*)icon
{ PayloadItem* result = [self copy];
  
  result->_icon = icon;
  
  return result;
}


/**
 *
 */
-(PayloadItem*) updateTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon
{ PayloadItem* result = [self copy];
  
  result->_title    = title;
  result->_subtitle = subtitle;
  result->_icon     = icon;
  
  return result;
}

/**
 *
 */
-(PayloadItem*) updatePayloadObjectId:(NSString*)payloadObjectId
{ PayloadItem* result = [self copy];
  
  result->_payloadObjectId   = payloadObjectId;
  
  return result;
}


/**
 *
 */
-(BOOL) isEqual:(id)object
{ BOOL result = NO;
  
  if( [object isKindOfClass:[PayloadItem class]] )
  { PayloadItem* payloadItemObject = object;
    
    if( ((self.title          ==nil && payloadItemObject.title          ==nil) || [payloadItemObject.title           isEqual:self.title]          ) &&
        ((self.subtitle       ==nil && payloadItemObject.subtitle       ==nil) || [payloadItemObject.subtitle        isEqual:self.subtitle]       ) &&
        ((self.icon           ==nil && payloadItemObject.icon           ==nil) || [payloadItemObject.icon            isEqual:self.icon]           ) &&
        ((self.payloadObjectId==nil && payloadItemObject.payloadObjectId==nil) || [payloadItemObject.payloadObjectId isEqual:self.payloadObjectId])
      )
      result = YES;
  } /* of if */
  
  return result;
}

/**
 *
 */
-(NSString*) description
{ NSMutableString* result = [NSMutableString stringWithCapacity:256];
  
  [result appendString:@"PayloadItem["];
  
  [result appendFormat:@"title:%@ ",self.title];
  [result appendFormat:@"subtitle:%@ ",self.subtitle];
  [result appendFormat:@"icon:%@ ",self.icon];
  [result appendFormat:@"payloadobjectid:%@ ",self.payloadObjectId];
  
  [result appendString:@"]"];
  
  return result;
}

/**
 *
 */
-(Payload*) payload:(NSError**)error
{ Payload* result = (Payload*)[_MOC loadObjectWithObjectID:self.payloadObjectId andError:error];

  return result;
}

/**
 *
 */
-(PMKPromise*) acceptVisitor:(id)visitor
{
  PMKPromise* result = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
  {
    if( [visitor respondsToSelector:@selector(visitPayloadItem:andState:)] )
      [visitor visitPayloadItem:self andState:0];

    fulfiller(self);
  }]
  .then(^()
  {
    return [[self payload:NULL] acceptVisitor:visitor];
  })
  .then(^()
  {
    if( [visitor respondsToSelector:@selector(visitPayloadItem:andState:)] )
      [visitor visitPayloadItem:self andState:1];
  });
  

  return result;
}
@end
