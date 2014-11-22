//
//  TresorTests.m
//  TresorTests
//
//  Created by Feldmaus on 04.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "CryptoService.h"
#import "PromiseKit.h"
#import "PromiseKit+Tresor.h"

#define wait(t) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:t]]


@interface PromiseTests : XCTestCase<DecryptedPayloadKeyPromiseDelegate>

@end

@implementation PromiseTests

/**
 *
 */
- (void)setUp
{ [super setUp];
  
  [CryptoService sharedInstance].delegate = self;
}

/**
 *
 */
- (void)tearDown
{ [CryptoService sharedInstance].delegate = nil;
  
  [super tearDown];
}

/**
 *
 */
-(PMKPromise*) decryptedPayloadKeyPromiseForPayload:(Payload*)payload
{ PMKPromise* promise =
  
  dispatch_promise_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), ^
  { NSData* passwordKey = _DUMMYPASSWORD;
                              
    return passwordKey;
  });
  
  return promise;
}


/**
 *
 */
-(void) test_01_decryptedPayloadPromise
{ PMKPromise* result = [self decryptedPayloadKeyPromiseForPayload:nil];
  
  [PMKPromise when:@[result]]
  .then(^(NSArray* results)
  {
    XCTAssertTrue(results!=nil && results.count==1, @"password should not be nil!");

    id password = results[0];
    
    XCTAssertTrue([password isEqual:_DUMMYPASSWORD], @"password has unexpected value:%@!",[NSString stringWithUTF8String:[password bytes]]);
    
    _NSLOG(@"password=%@",[NSString stringWithUTF8String:[password bytes]]);
  });
  
  XCTAssertTrue(result!=nil,@"");
}

/**
 *
 */
-(void) test_02_whileLoop
{ NSMutableArray* data   = [[NSMutableArray alloc] initWithArray:@[@"first",@"second",@"third",@"fourth"]];
  PMKPromise*     result = [PMKPromise
    whileWithCondition:^BOOL
    { BOOL result = data.count>0;
      
      _NSLOG(@"data.count=%d result=%d",data.count,result);
      
      return result;
    }
    andAction:^PMKPromise*
    {
      _NSLOG(@"action...");
      
      return dispatch_promise_on(dispatch_get_main_queue(), ^()
      {
        if( data.count>0 )
        { _NSLOG(@"reducing data");
          
          sleep(0.3);
          
          [data removeObjectAtIndex:0];
          
          _NSLOG(@"new data.count=%d",data.count);
        } /* of if */
      });
    }];
  
  [PMKPromise when:@[result]].then(^()
  {
    XCTAssertTrue(data.count==0, @"data.count should be zero, but is %d",data.count);
  });
  
  wait(4.0);
  
  XCTAssertTrue(result!=nil,@"");
}

@end
