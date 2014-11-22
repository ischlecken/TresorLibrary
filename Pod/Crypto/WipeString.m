//
//  WipeString.m
//  crypto
//
//  Created by Feldmaus on 28.12.12.
//
//
#import "Macros.h"
#import "WipeString.h"

@interface WipeString()
{
  NSString* _str;
}
@end



@implementation WipeString

/**
 *
 */
-(id) initWithString:(NSString *)aString
{ self = [super init];
  
  if( self )
    _str = aString;
  
  return self;
}

/**
 *
 */
-(void) dealloc
{ _NSLOG_SELECTOR;
  
  const char* buffer = CFStringGetCStringPtr((__bridge CFStringRef)(_str),CFStringGetSystemEncoding());
  
  if( ![_str isKindOfClass:[NSConstantString class]] && buffer!=NULL )
    memset((void*)buffer, 0xff, strlen(buffer));
}


#pragma mark Forwarding Messages

/**
 *
 */
-(NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{ _NSLOG(@"selector=%@", NSStringFromSelector(selector));
  
  NSMethodSignature* signature = [super methodSignatureForSelector:selector];
  
  if( !signature )
    signature = [[_str class] instanceMethodSignatureForSelector:selector];
  
  return signature;
}

/**
 *
 */
-(void) forwardInvocation:(NSInvocation *)anInvocation
{ SEL sel = [anInvocation selector];
  
  _NSLOG(@"invocation=%@",NSStringFromSelector(sel));
  
  if( [[_str class] instancesRespondToSelector:sel] )
    [anInvocation invokeWithTarget:_str];
  else
    [super forwardInvocation:anInvocation];
}

/**
 *
 */
-(BOOL) respondsToSelector:(SEL)aSelector
{ BOOL resultSuper = [super respondsToSelector:aSelector];
  bool resultObj   = [[_str class] instancesRespondToSelector:aSelector];
  
  _NSLOG(@"aSelector=%@: resultSuper=%d resultObj=%d",NSStringFromSelector(aSelector),resultSuper,resultObj);
  
  return resultSuper || resultObj;
}

@end
