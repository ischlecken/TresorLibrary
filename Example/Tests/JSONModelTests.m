//
//  TresorTests.m
//  TresorTests
//
//  Created by Feldmaus on 04.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "JSONModel.h"
#import "PayloadItemList.h"
#import "PayloadItem.h"
#import "NSString+Date.h"

#define kJSON0 @"{\"list\":[]}"
#define kJSON1 @"{\"list\":[{\"title\":\"pi0-title\",\"payloadObjectId\":\"pi0-payloadobjectid\",\"icon\":\"pi0-icon\",\"subtitle\":\"pi0-substitle\"},{\"title\":\"pi1-title\",\"payloadObjectId\":\"pi1-payloadobjectid\",\"icon\":\"pi1-icon\",\"subtitle\":\"pi1-substitle\"},{\"title\":\"pi2-title\",\"payloadObjectId\":\"pi2-payloadobjectid\",\"icon\":\"pi2-icon\",\"subtitle\":\"pi2-substitle\"}]}"

#define kJSON2 @"{\"intValue\":42,\"dateValue\":\"1970-01-01T00:00:00Z\",\"strValue\":\"stringValue1\",\"arrayValue\":[{\"intValueA\":443,\"strValueA\":\"stringValueA\"},{\"intValueB\":3243,\"strValueB\":\"stringValueB\"}]}"

@protocol TestModel <NSObject>
@end

@interface TestModel : JSONModel
@property         NSString*           strValue;
@property(assign) int                 intValue;
@property         NSDate*             dateValue;
@property         NSArray<TestModel>* arrayValue;
@end

@implementation TestModel
@end


@interface TestModelA : JSONModel
@property         NSString* strValueA;
@property(assign) int       intValueA;
@end

@implementation TestModelA
@end

@interface TestModelB : JSONModel
@property         NSString* strValueB;
@property(assign) int       intValueB;
@end

@implementation TestModelB
@end


@interface JSONModelTests : XCTestCase
@end

/*
@interface JSONValueTransformer (TestCustomTransformer)
- (NSDate *)NSDateFromNSString:(NSString*)string;
- (NSString *)JSONObjectFromNSDate:(NSDate *)date;
@end


@implementation JSONValueTransformer (TestCustomTransformer)

- (NSDate *)NSDateFromNSString:(NSString*)string
{ NSLog(@"string:%@",string);
  
  return [NSString rfc3339TimestampValue:string];
}

- (NSString *)JSONObjectFromNSDate:(NSDate *)date
{ NSLog(@"date:%@",date);
  
  return [NSString stringRFC3339TimestampForDate:date];
}

@end
 */

@implementation JSONModelTests

/**
 *
 */
- (void)setUp
{ [super setUp]; }

/**
 *
 */
- (void)tearDown
{ [super tearDown]; }

/**
 *
 */
-(PayloadItemList*) createPayloadList
{ PayloadItemList* pil = [[PayloadItemList alloc] init];
  
  PayloadItem* pi0 = [[PayloadItem alloc] initWithTitle:@"pi0-title" andSubtitle:@"pi0-substitle" andIcon:@"pi0-icon" andPayloadObjectId:@"pi0-payloadobjectid"];
  PayloadItem* pi1 = [[PayloadItem alloc] initWithTitle:@"pi1-title" andSubtitle:@"pi1-substitle" andIcon:@"pi1-icon" andPayloadObjectId:@"pi1-payloadobjectid"];
  PayloadItem* pi2 = [[PayloadItem alloc] initWithTitle:@"pi2-title" andSubtitle:@"pi2-substitle" andIcon:@"pi2-icon" andPayloadObjectId:@"pi2-payloadobjectid"];
  
  pil = [pil addItem:pi0];
  pil = [pil addItem:pi1];
  pil = [pil addItem:pi2];

  return pil;
}

/**
 *
 */
-(void) test_01_encode
{ PayloadItemList* pil = [[PayloadItemList alloc] init];
  
  NSString* json = [pil toJSONString];
  
  XCTAssertEqualObjects(json,kJSON0,@"unexpected value for decoded json");
  
  pil = [self createPayloadList];
  
  json = [pil toJSONString];
  
  XCTAssertEqualObjects(json,kJSON1,@"unexpected value for decoded json");
}

/**
 *
 */
-(void) test_02_encode
{ NSLog(@"the game beginns");
  
  TestModel* model = [[TestModel alloc] init];
  
  model.strValue = @"stringValue1";
  model.intValue = 42;
  model.dateValue= [NSDate dateWithTimeIntervalSince1970:0.0];
  
  TestModelA* modelA = [[TestModelA alloc] init];
  TestModelB* modelB = [[TestModelB alloc] init];
  
  modelA.strValueA = @"stringValueA";
  modelA.intValueA = 443;

  modelB.strValueB = @"stringValueB";
  modelB.intValueB = 3243;
  
  model.arrayValue = (NSArray<TestModel>*)@[modelA,modelB];
  
  NSString* json = [model toJSONString];
  
  XCTAssertEqualObjects(json,kJSON2,@"unexpected value for decoded json");
}


/**
 *
 */
-(void) test_10_decode
{ NSError*         error = nil;
  PayloadItemList* pil   = nil;
  
  pil = [[PayloadItemList alloc] initWithString:kJSON0 error:&error];
  
  XCTAssertNil(error, @"error should be nil:%@",error);
}

/**
 *
 */
-(void) test_11_decode
{ NSError*         error = nil;
  PayloadItemList* pil   = nil;
  
  pil = [[PayloadItemList alloc] initWithString:kJSON1 error:&error];
  
  XCTAssertNil(error, @"error should be nil:%@",error);
}

@end
