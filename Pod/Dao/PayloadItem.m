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

#import "PayloadItem.h"
#import "TresorModel.h"
#import "TresorDaoCategories.h"



@implementation PayloadItem

@synthesize title=_title,subtitle=_subtitle,icon=_icon,payloadoid=_payloadoid,iconcolor=_iconcolor;

/**
 *
 */
-(instancetype) init
{ self = [super init];
 
  if( self )
  { _title      = nil;
    _subtitle   = nil;
    _icon       = nil;
    _iconcolor  = nil;
    _payloadoid = nil;
  } /* of if */
  
  return self;
}


/**
 *
 */
-(instancetype) initWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andPayloadObjectId:(NSString*)payloadoid
{ self = [self init];
  
  if( self )
  { _title      = title;
    _subtitle   = subtitle;
    _icon       = icon;
    _iconcolor  = @"#ff00aa";
    _payloadoid = payloadoid;
  } /* of if */
  
  return self;
}

/**
 *
 */
-(id) initWithCoder:(NSCoder*)decoder
{ self = [super init];
  
  if( self )
  { _title      = [decoder decodeObjectForKey :@"title"];
    _subtitle   = [decoder decodeObjectForKey :@"subtitle"];
    _icon       = [decoder decodeObjectForKey :@"icon"];
    _iconcolor  = [decoder decodeObjectForKey :@"iconcolor"];
    _payloadoid = [decoder decodeObjectForKey :@"payloadoid"];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(void) encodeWithCoder:(NSCoder*)encoder
{ [encoder encodeObject :self.title      forKey:@"title"];
  [encoder encodeObject :self.subtitle   forKey:@"subtitle"];
  [encoder encodeObject :self.icon       forKey:@"icon"];
  [encoder encodeObject :self.iconcolor  forKey:@"iconcolor"];
  [encoder encodeObject :self.payloadoid forKey:@"payloadoid"];
}

/**
 *
 */
-(id) copyWithZone:(NSZone *)zone
{ PayloadItem* result = [[PayloadItem allocWithZone:zone] init];
  
  result->_title      = self.title;
  result->_subtitle   = self.subtitle;
  result->_icon       = self.icon;
  result->_iconcolor  = self.iconcolor;
  result->_payloadoid = self.payloadoid;
  
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
  
  result->_icon      = icon;
  
  return result;
}


/**
 *
 */
-(PayloadItem*) updateIconColor:(NSString*)iconColor
{ PayloadItem* result = [self copy];
  
  result->_iconcolor = iconColor;
  
  return result;
}


/**
 *
 */
-(PayloadItem*) updateIcon:(NSString*)icon andColor:(NSString*)iconColor
{ PayloadItem* result = [self copy];
  
  result->_icon      = icon;
  result->_iconcolor = iconColor;
  
  return result;
}


/**
 *
 */
-(PayloadItem*) updateTitle:(NSString*)title andSubtitle:(NSString*)subtitle andIcon:(NSString*)icon andColor:(NSString*)iconColor
{ PayloadItem* result = [self copy];
  
  result->_title     = title;
  result->_subtitle  = subtitle;
  result->_icon      = icon;
  result->_iconcolor = iconColor;
  
  return result;
}

/**
 *
 */
-(PayloadItem*) updatePayloadObjectId:(NSString*)payloadoid
{ PayloadItem* result = [self copy];
  
  result->_payloadoid   = payloadoid;
  
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
        ((self.iconcolor      ==nil && payloadItemObject.iconcolor      ==nil) || [payloadItemObject.iconcolor       isEqual:self.iconcolor]      ) &&
        ((self.payloadoid     ==nil && payloadItemObject.payloadoid     ==nil) || [payloadItemObject.payloadoid      isEqual:self.payloadoid]     )
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
  [result appendFormat:@"iconcolor:%@ ",self.iconcolor];
  [result appendFormat:@"payloadoid:%@ ",self.payloadoid];
  
  [result appendString:@"]"];
  
  return result;
}

/**
 *
 */
-(Payload*) payload:(NSError**)error
{ Payload* result = (Payload*)[_MOC loadObjectWithObjectID:self.payloadoid andError:error];

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
