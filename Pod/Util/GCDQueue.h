//
//  GCDQueue.h
//  Pods
//
//  Created by Feldmaus on 10.01.15.
//
//

#import <Foundation/Foundation.h>

@interface GCDQueue : NSObject

-(dispatch_queue_t) serialBackgroundQueue;

+(instancetype)     sharedInstance;
@end
