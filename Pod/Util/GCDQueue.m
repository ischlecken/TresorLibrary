//
//  GCDQueue.m
//  Pods
//
//  Created by Feldmaus on 10.01.15.
//
//
#import "GCDQueue.h"

@interface GCDQueue ()
@property dispatch_queue_t backgroundQueue;
@end

@implementation GCDQueue

/**
 *
 */
-(dispatch_queue_t) serialBackgroundQueue
{ if( self.backgroundQueue==nil )
     self.backgroundQueue = dispatch_queue_create("com.ischlecken.tresor.backgroundqueue", DISPATCH_QUEUE_SERIAL);
  
  return self.backgroundQueue;
}

/**
 *
 */
+(instancetype)     sharedInstance
{ static GCDQueue*       _inst = nil;
  static dispatch_once_t oncePredicate;
  
  dispatch_once(&oncePredicate,^{ _inst = [self new]; });
  
  return _inst;
  
}
@end
