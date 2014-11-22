//
//  TresorTests.m
//  TresorTests
//
//  Created by Feldmaus on 04.05.14.
//  Copyright (c) 2014 ischlecken. All rights reserved.
//
#import <XCTest/XCTest.h>
#import "TresorModel.h"
#import "CryptoService.h"
#import "DumpVisitor.h"
#import "NSIndexPath+Util.h"
#import "PromiseKit+Tresor.h"
#import "TresorDaoCategories.h"

#define wait(t) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:t]]


@interface CreditCard : JSONModel
@property NSString* no;
@property NSString* cvs;
@property NSDate*   validUntil;
@end

@implementation CreditCard

/**
 *
 */
-(BOOL) isEqual:(id)object
{ BOOL result = NO;
  
  if( [object isKindOfClass:[CreditCard class]] )
  { CreditCard* cc = object;
    
    BOOL validUntilIsEqual = fabs([self.validUntil timeIntervalSince1970] - [cc.validUntil timeIntervalSince1970])<10.0;
    
    result = [self.no isEqual:cc.no] && [self.cvs isEqual:cc.cvs] && validUntilIsEqual;
  } /* of if */
  
  _NSLOG(@"result:%ld",(long)result);
  
  return result;
}
@end



@interface TresorTests : XCTestCase<DecryptedPayloadKeyPromiseDelegate,TresorModelDelegate>

@end

@implementation TresorTests

/**
 *
 */
- (void)setUp
{ [super setUp];
  
  [CryptoService sharedInstance].delegate = self;
  
  [TresorModel sharedInstance].delegate = self;
}

/**
 *
 */
- (void)tearDown
{ [CryptoService sharedInstance].delegate = nil;
  
  [TresorModel sharedInstance].delegate = nil;
  
  [super tearDown];
}

/**
 *
 */
-(PMKPromise*) decryptedPayloadKeyPromiseForPayload:(Payload*)payload
{ PMKPromise* promise = dispatch_promise_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), ^
  { NSData* passwordKey = _DUMMYPASSWORD;
     
    //_NSLOG(@"passwordKey=%@",[NSString stringWithUTF8String:[passwordKey bytes]]);
     
    return passwordKey;
  });
  
  return promise;
}


/**
 *
 */
-(void) test_010_DaoCreation
{ NSError* error = nil;
  
  error=nil;
  Key* key = [Key keyWithIV:@"123" andPayloadKey:[NSData dataWithUTF8String:@"123"] andPayloadIV:@"123" andPayloadAlgorith:@"123" andError:&error];
  XCTAssertTrue(error==nil, @"error while creating key object:%@",error);
  _NSLOG(@"key=%@",[key uniqueObjectId]);

  error=nil;
  Password* password = [Password passwordObject:&error];
  XCTAssertTrue(error==nil, @"error while creating password object:%@",error);
  _NSLOG(@"key=%@",[password uniqueObjectId]);
  
  error=nil;
  Audit* audit = [Audit auditObjectWithEventId:1 andParam1:@"abc" andError:&error];
  XCTAssertTrue(error==nil, @"error while creating audit object:%@",error);
  _NSLOG(@"audit=%@",[audit uniqueObjectId]);
  
  error=nil;
  PMKPromise* payload = [Payload payloadWithObject:@"text"]
  .then(^(Payload* payload)
  { _NSLOG(@"payload=%@",[payload uniqueObjectId]);
  }).catch(^(NSError* err)
  { XCTAssertTrue(err!=nil, @"error while creating payload object:%@",err);
  });
  XCTAssertTrue(payload!=nil, @"error while creating payload object");
  
  error=nil;
  Commit* commit = [Commit commitObjectWithMessage:@"test" andError:&error];
  XCTAssertTrue(error==nil, @"error while creating commit object:%@",error);
  _NSLOG(@"commit=%@",[commit uniqueObjectId]);

  error=nil;
  Vault* vault = [Vault vaultObjectWithName:@"test" andType:@"testtype" andError:&error];
  XCTAssertTrue(error==nil, @"error while creating vault object:%@",error);
  _NSLOG(@"vault=%@",[vault uniqueObjectId]);
}


/**
 *
 */
-(void) test_020_NewVault
{ Vault* vault = [self createVault:@"newVaultTest" andType:@"unitTest"];
  
  [self createVaultCommit:vault]
  .then(^(Vault* v)
  { return [v acceptVisitor:[DumpVisitor new]];
  });
  
  wait(20);
}


/**
 *
 */
-(void) test_021_NewVault
{ NSError* error  = nil;
  
  Vault*  vault      = [self createVault:@"newVaultTest" andType:@"unitTestCancel"];
  Commit* nextCommit = [vault nextCommit:&error];
  XCTAssertTrue(error==nil, @"error while creating next commit:%@",error);
  
  PMKPromise* result = [nextCommit addPayloadItemWithTitle:@"item1" andSubtitle:@"subtitle1" andIcon:@"default" andObject:@"bla1" forPath:[NSIndexPath new]]
  .then(^(Commit* cm)
  { return [cm addPayloadItemWithTitle:@"item2" andSubtitle:@"subtitle2" andIcon:@"default" andObject:@"bla2" forPath:[NSIndexPath new]];
  })
  .then(^(Commit* cm)
  { NSError* error = nil;
    
    if( [_MOC save:&error]
        &&
        [vault cancelNextCommit:&error]
      )
    { [_MOC deleteObject:vault];

      [_MOC save:&error];
    } /* of if */
    
    return error;
  })
  .catch(^(NSError* err)
  { XCTAssertNil(err, @"error while creating vault:%@",err);
  });

  XCTAssertNotNil(result, @"result is nil");
  
  wait(20);
}


/**
 *
 */
-(void) test_041_dump
{ NSError* error = nil;
  Vault*   vault = [Vault findVaultByName:@"updateVaultTest" andError:&error];

  if( vault )
    [vault acceptVisitor:[DumpVisitor new]];
  
  wait(20);
}

/**
 * six payloads
 commit
 [P]payloaditemlist
 item1
   [P]bla1
 item2.1
   [P]update2
 title-update
   [P]payloaditemlist
   update2.1
     [P]text2.1
   xx
     [P]payloaditemlist
     update2.1.1
       [P]update2.1.1

 */
-(void) test_040_UpdateVault
{ NSError* error = nil;
  
  Vault* vault = [Vault findVaultByName:@"updateVaultTest" andError:&error];
  XCTAssertTrue(error==nil, @"error while search vault for updatetest:%@",error);
  
  PMKPromise* vaultPromise = nil;
  
  if( vault==nil )
  { vault = [self createVault:@"updateVaultTest" andType:@"unitTest"];
  
    vaultPromise = [self createVaultCommit:vault];
  } /* of if */
  else
    vaultPromise = [PMKPromise new:^(PMKPromiseFulfiller fulfiller, PMKPromiseRejecter rejecter)
    { fulfiller(vault);
    }];
  
  vaultPromise
    .then(^(Vault* vm)
    { NSError* error = nil;
            
      Commit* nextCommit = [vm nextCommit:&error];
      XCTAssertTrue(error==nil, @"error while creating next commit:%@",error);
      
      return nextCommit ? (id)[nextCommit updatePayloadItemWithTitle:@"item2.1" andSubtitle:@"subtitle2.2" andIcon:@"default2" forPath:[NSIndexPath new] atPosition:1] : error;
    })
    .then(^(Commit* cm)
    { return [cm updatePayloadItemWithObject:@"update2" forPath:[NSIndexPath new] atPosition:1];
    })
    .then(^(Commit* cm)
    { return [cm addPayloadItemWithTitle:@"title-update" andSubtitle:@"subtitle-update" andIcon:@"icon-update" andObject:@"text-update" forPath:[NSIndexPath new]];
    })
    .then(^(Commit* cm)
    { return [cm updatePayloadItemListForPath:[NSIndexPath new] atPosition:2];
    })
    .then(^(Commit* cm)
    { return [cm addPayloadItemWithTitle:@"update2.1" andSubtitle:@"subtitle2.1" andIcon:@"default2.1" andObject:@"text2.1" forPath:[NSIndexPath indexPathFromStringPath:@"2"]];
    })
    .then(^(Commit* cm)
    { return [cm addPayloadItemListWithTitle:@"xx" andSubtitle:@"adfa" andIcon:@"afda" forPath:[NSIndexPath indexPathFromStringPath:@"2"]];
    })
    .then(^(Commit* cm)
    { return [cm addPayloadItemWithTitle:@"update2.1.1" andSubtitle:@"subtitle2.1.1" andIcon:@"default2.1.1" andObject:@"text2.1.1" forPath:[NSIndexPath indexPathFromStringPath:@"2.1"]];
    })
    .then(^(Commit* cm)
    { cm.message   = @"Update Commit 2";
      vault.commit = cm;
      [self save];
      
      [self isExpectedValue:vault.commit
                    forPath:[NSIndexPath indexPathFromStringPath:@"1"]
                 atPosition:1
                    titleIs:@"item2.1"
                 subtitleIs:@"subtitle2.2"
                     iconIs:@"default2"
                     textIs:@"update2"];
      
      return [vault acceptVisitor:[DumpVisitor new]];
    })
    .catch(^(NSError* err)
    { XCTAssertTrue(err==nil, @"error while updating vault:%@",err);
    });
  
  wait(20);
}


/**
 *
 */
-(void) test_050_DeleteVault
{ NSError* error = nil;
  
  Vault* vault = [Vault findVaultByName:@"deleteVaultTest" andError:&error];
  XCTAssertTrue(error==nil, @"error while search vault for delete test:%@",error);
  
  if( vault==nil )
    vault = [self createVault:@"deleteVaultTest" andType:@"unitTest"];
  
  XCTAssertTrue(vault!=nil, @"vault should not be nil");
  
  [self createVaultCommit:vault]
    .then(^(Vault* v)
    { NSError* error = nil;
            
      Commit* nextCommit = [v nextCommit:&error];
      
      return nextCommit ? (id)[nextCommit addPayloadItemWithTitle:@"deleteTitle" andSubtitle:@"deletesubtitle" andIcon:@"deleteIcon" andObject:@"bla" forPath:[NSIndexPath new]] : error;
    })
    .then(^(Commit* cm)
    {
      cm.message = @"update delete vault";
      
      vault.commit = cm;
      
      [self save];
      
      return [vault acceptVisitor:[DumpVisitor new]];
    })
    .catch(^(NSError* err)
    { XCTAssertTrue(err==nil, @"error while updating vault:%@",err);
    });
  
  wait(10);
  
  [Vault deleteVault:vault andError:&error];
  XCTAssertTrue(error==nil, @"error while deleting vault:%@",error);
}

/**
 *
 */
-(void) test_060_AddPayloadItemInCommit
{ NSError* error = nil;
  
  Vault* vault = [self createVault:@"testAddPayloadItemInCommit" andType:@"unitTest"];
    
  Commit* nextCommit = [vault nextCommit:&error];
  XCTAssertTrue(error==nil, @"error while creating next commit:%@",error);
  
  [nextCommit addPayloadItemWithTitle:@"itemtestAddPayloadItemInCommit.0" andSubtitle:@"subtitletestAddPayloadItemInCommit.0" andIcon:@"default.0" andObject:@"blatestAddPayloadItemInCommit.0" forPath:[NSIndexPath indexPathFromStringPath:nil]]
  .then(^(Commit* cm)
  { PMKPromise* item = [cm addPayloadItemWithTitle:@"itemtestAddPayloadItemInCommit.1" andSubtitle:@"subtitletestAddPayloadItemInCommit.1" andIcon:@"default.1" andObject:@"blatestAddPayloadItemInCommit.1" forPath:[NSIndexPath indexPathFromStringPath:nil]];
    
    return item;
  })
  .then(^(Commit* cm)
  { PMKPromise* item = [cm addPayloadItemListWithTitle:@"itemtestAddPayloadItemInCommit.2" andSubtitle:@"subtitletestAddPayloadItemInCommit.2" andIcon:@"default.2" forPath:[NSIndexPath indexPathFromStringPath:nil]];
  
    return item;
  })
  .then(^(Commit* cm)
  { PMKPromise* item = [cm addPayloadItemWithTitle:@"itemtestAddPayloadItemInCommit.3" andSubtitle:@"subtitletestAddPayloadItemInCommit.3" andIcon:@"default.3" andObject:@"blatestAddPayloadItemInCommit.3" forPath:[NSIndexPath indexPathFromStringPath:@"2"]];
    
    return item;
  })
  .then(^(Commit* cm)
  { cm.message  = @"Initial Commit for testAddPayloadItemInCommit";
    
    vault.commit = cm;
    
    [self save];
    
    return [vault acceptVisitor:[DumpVisitor new]];
  })
  .then(^()
  { NSError* error = nil;
          
    Commit* nextCommit = [vault nextCommit:&error];
    XCTAssertTrue(error==nil, @"error while creating next commit:%@",error);
    
    return [nextCommit updatePayloadItemWithTitle:@"itemtestAddPayloadItemInCommit.4"
                                      andSubtitle:@"subtitletestAddPayloadItemInCommit.4"
                                          andIcon:@"default.4"
                                          forPath:[NSIndexPath new]
                                       atPosition:0];
  })
  .then(^(Commit* cm)
  { cm.message  = @"Commit updatePayloadItem";
    vault.commit = nextCommit;
    
    [self save];
    return [vault acceptVisitor:[DumpVisitor new]];
  })
  .catch(^(NSError* err)
  { XCTAssertTrue(err==nil, @"error while adding payloaditem:%@",err);
  });

  wait(20);
}

/**
 *
 */
-(void) test_070_AllVaults
{ NSError* error = nil;
  
  NSArray* vaults = [Vault allVaults:&error];
  XCTAssertTrue(error==nil, @"error while loading all vaults:%@",error);
  
  for( id v in vaults )
    NSLog(@"%@:%@ %@ '%@‘",[v vaultname],[v vaulttype],[[v commit] createts],[[v commit] message]);
}

/**
 *
 */
-(void) test_080_AllVaultCommits
{ NSError* error = nil;
  
  NSArray* vaults = [Vault allVaults:&error];
  XCTAssertTrue(error==nil, @"error while loading all vaults:%@",error);
  
  for( id v in vaults )
  { NSLog(@"%@:%@ %@",[v vaultname],[v vaulttype],[v uniqueObjectId]);
    
    NSArray* commits = [v allCommits:&error];
    
    for( Commit* c in commits )
      NSLog(@"  %@",[c uniqueObjectId]);
  } /* of for */
}


/**
 *
 */
-(void) test_090_StoreJSONModel
{ NSError* error = nil;
  
  Vault* vault = [Vault findVaultByName:@"jsonModelVault" andError:&error];
  XCTAssertTrue(error==nil, @"error while search vault for jsonmodel test:%@",error);
  
  if( vault==nil )
    vault = [self createVault:@"jsonModelVault" andType:@"unitTest"];
  
  XCTAssertTrue(vault!=nil, @"vault should not be nil");
  
  CreditCard* cc0 = [CreditCard new];
  
  cc0.validUntil = [NSDate date];
  cc0.no         = @"0123 4567 8912 1234";
  cc0.cvs        = @"999";
  
  PMKPromise* vaultPromise =
    [self createVaultCommit:vault]
    .then(^(Vault* v)
    { NSError* error = nil;
      
      Commit* nextCommit = [v nextCommit:&error];
      
      return nextCommit ? (id)[nextCommit addPayloadItemWithTitle:@"cc" andSubtitle:@"ccsub" andIcon:@"ccicon" andObject:cc0 forPath:[NSIndexPath new]] : error;
    })
    .then(^(Commit* cm)
    { cm.message  = @"Initial Commit for jsonmodel test";
      
      vault.commit = cm;
      
      [self save];
      
      return [vault acceptVisitor:[DumpVisitor new]];
    })
    .catch(^(NSError* err)
    { XCTAssertTrue(err==nil, @"error while updating vault:%@",err);
    });
  
  [PMKPromise when:vaultPromise]
    .then(^(Vault* v)
    { _NSLOG(@"read creditcard...");
    
      return [v.commit payloadForPath:[NSIndexPath new]];
    })
    .then(^(Payload* p)
    { XCTAssertTrue(p.isPayloadItemList, @"is not payloadlist");
      
      PayloadItemList* pil = p.decryptedPayload;
      
      NSUInteger lastIndex = pil.count-1;
      _NSLOG(@"lastIndex:%ld",(unsigned long)lastIndex);
      
      return [vault.commit payloadForPath:[NSIndexPath indexPathWithIndex:lastIndex]];
    })
    .then(^(Payload* p)
    { XCTAssertTrue( [p.decryptedPayload isKindOfClass:[CreditCard class]],@"unexcepted class for payload");
      
      CreditCard* cc1 = p.decryptedPayload;
      
      XCTAssertEqualObjects(cc0, cc1, @"decrypted creditcard should be equal to original version: %@ --> %@",cc0,cc1);
    });
  
  wait(10);
  
}

#pragma mark Helper methods

/**
 *
 */
-(void) save
{ NSError* error = nil;
  
  [_MOC save:&error];
  XCTAssertTrue(error==nil, @"error while saving:%@",error);
  
  _NSLOG(@" save MOC");
}

/**
 *
 */
-(Vault*) createVault:(NSString*)vaultName andType:(NSString*)vaultType
{ NSError* error = nil;
    
  Vault* vault = [Vault vaultObjectWithName:vaultName andType:vaultType andError:&error];
  XCTAssertTrue(error==nil, @"error while creating new vault:%@",error);

  return error==nil ? vault : nil;
}

/**
 * three payloads
 commit
   [P]payloaditemlist
   item1
     [P]bla1
   item2
     [P]bla2
 */
-(PMKPromise*) createVaultCommit:(Vault*)vault
{ NSError*         error  = nil;
  
  Commit* nextCommit = [vault nextCommit:&error];
  XCTAssertTrue(error==nil, @"error while creating next commit:%@",error);
  
  PMKPromise* result = [nextCommit addPayloadItemWithTitle:@"item1" andSubtitle:@"subtitle1" andIcon:@"default" andObject:@"bla1" forPath:[NSIndexPath new]]
  .then(^(Commit* cm)
  { return [cm addPayloadItemWithTitle:@"item2" andSubtitle:@"subtitle2" andIcon:@"default" andObject:@"bla2" forPath:[NSIndexPath new]];
  })
  .then(^(Commit* cm)
  { cm.message   = @"Initial Commit";
    vault.commit = nextCommit;
    [self save];
    
    [self isExpectedValue:vault.commit
                  forPath:[NSIndexPath indexPathFromStringPath:@"1"]
               atPosition:1
                  titleIs:@"item2"
               subtitleIs:@"subtitle2"
                   iconIs:@"default"
                   textIs:@"bla2"];
    
    [self isExpectedValue:vault.commit
                  forPath:[NSIndexPath indexPathFromStringPath:@"0"]
               atPosition:0
                  titleIs:@"item1"
               subtitleIs:@"subtitle1"
                   iconIs:@"default"
                   textIs:@"bla1"];
    
    return [vault acceptVisitor:[DumpVisitor new]];
  })
  .catch(^(NSError* err)
  { XCTAssertTrue(err==nil, @"error while creating vault:%@",err);
  });
  
  return result;
}


/**
 *
 */
-(void) isExpectedValue:(Commit*)commit forPath:(NSIndexPath*)path atPosition:(NSInteger)position titleIs:(NSString*)title subtitleIs:(NSString*)subtitle iconIs:(NSString*)icon textIs:(NSString*)text
{ 
  [commit payloadForPath:path]
    .then(^(Payload* pl,NSArray* parentPath)
    { id decryptedPayload = [pl decryptedPayload];
      
      XCTAssertEqualObjects(decryptedPayload, text, @"decryptedPayload has unexpected value, %@!=%@",decryptedPayload,text);
      
      Payload* parentPayload          = [parentPath objectAtIndex:1];
      id       decryptedparentPayload = [parentPayload decryptedPayload];
      
      XCTAssertTrue( [decryptedparentPayload isKindOfClass:[PayloadItemList class]],@"payload is not a PayloadItemList" );
      
      PayloadItemList* pil = decryptedparentPayload;
      PayloadItem*     pi  = [pil objectAtIndex:position];
      
      XCTAssertEqualObjects(pi.title   , title   , @"payloaditem title has unexpected value");
      XCTAssertEqualObjects(pi.subtitle, subtitle, @"payloaditem subtitle has unexpected value");
      XCTAssertEqualObjects(pi.icon    , icon    , @"payloaditem icon has unexpected value");
    })
    .catch(^(NSError* err)
    { XCTAssertTrue(err==nil, @"error loading payload using path:%@",err);
    });
  
}

#pragma mark TresorModelDelegate

/**
 *
 */
-(NSURL*) applicationDocumentsDirectory
{ NSURL* result = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];

  _NSLOG(@"appDocDir=<%@>",result);
  
  return result;
}


/**
 *
 */
-(BOOL)   useCloud
{ return NO; }

/**
 *
 */
-(id)     icloudId
{ return [[NSFileManager defaultManager] ubiquityIdentityToken]; }

/**
 *
 */
-(BOOL)   iCloudAvailable
{ return NO; }

/**
 *
 */
-(NSURL*) keysDatabaseStoreURL
{ return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"tresor-keys.sqlite"]; }

/**
 *
 */
-(NSURL*) dataDatabaseStoreURL
{ return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"tresor-data.sqlite"]; }

/**
 *
 */
-(BOOL) keysDatabaseStoreExists
{ NSURL* url    = [self keysDatabaseStoreURL];
  BOOL   result = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
  
  return result;
}

/**
 *
 */
-(BOOL) dataDatabaseStoreExists
{ NSURL* url    = [self dataDatabaseStoreURL];
  BOOL   result = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
  
  return result;
}
@end
