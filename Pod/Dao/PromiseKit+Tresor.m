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

#import "PromiseKit+Tresor.h"

/**
 *
 */
PMKPromise *dispatch_promise_after(dispatch_time_t after, id (^block)())
{
  return dispatch_promise_on_after(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), after, block);
}


/**
 *
 */
PMKPromise *dispatch_promise_on_after(dispatch_queue_t queue,dispatch_time_t after, id (^block)(void))
{
  return [PMKPromise new:^(void(^fulfiller)(id), void(^rejecter)(id))
  {
    dispatch_after(after,queue, ^
    { id result = block();
     
      if ([result isKindOfClass:[NSError class]])
        rejecter(result);
      else
        fulfiller(result);
    });
  }];
}

@implementation PMKPromise (Tresor)

/**
 *
 */
+(PMKPromise*) whileWithCondition:(BOOL (^)(void))condition andAction:(PMKPromise* (^)(void))action
{ return [PMKPromise new:^(void(^fulfiller)(id), void(^rejecter)(id))
  { __block PMKPromise* (^loop) ();
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    loop = [^ PMKPromise*()
    {
      if( !condition() )
      { NSLog(@"Retain count of loop.1:%ld", CFGetRetainCount((__bridge CFTypeRef)loop));
        
        loop = nil;
        
        return nil;
      } /* of if */
      
      PMKPromise* result = action();
      
      result = result
      .then(^(id bla)
      { return loop();
      });
      
      return result;
    } copy];
    
#pragma clang diagnostic pop
    
    fulfiller(loop());
  }];
  
}


@end

