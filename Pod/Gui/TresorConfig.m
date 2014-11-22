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
#import "Macros.h"
#import "TresorConfig.h"
#import "TresorDefaults.h"
#import "SSKeychain.h"
 

#pragma mark - UserDefaultDesc

@interface UserDefaultDesc : NSObject

@property NSString* keyName;
@property id        defaultValue;

+(instancetype) userDefaultDescWithKeyName:(NSString*)keyName andDefaultValue:(id)defaultValue;
@end

/**
 *
 */
@implementation UserDefaultDesc

/**
 *
 */
+(instancetype) userDefaultDescWithKeyName:(NSString *)keyName andDefaultValue :(id)defaultValue
{ UserDefaultDesc* result = [UserDefaultDesc new];
  
  result.keyName      = keyName;
  result.defaultValue = defaultValue;
  
  return result;
}

@end

#pragma mark - TresorConfig
@interface TresorConfig ()
{
  NSString* _userId;
}

@property(nonatomic,strong) NSDictionary*        userDefaultDescription;
@property(nonatomic,strong) NSMutableDictionary* userDefaults;

@end

@implementation TresorConfig



/**
 *
 */
+(instancetype) sharedInstance
{ static dispatch_once_t   once;
  static TresorConfig*        sharedInstance;
  
  dispatch_once(&once, ^{sharedInstance        = [self new]; });
  
  return sharedInstance;
}

/**
 *
 */
-(instancetype) init
{ self = [super init];
  
  if (self)
  { NSArray* udd =
    @[
#if TKR_PRODUCTION_ENVIRONMENT
       [UserDefaultDesc userDefaultDescWithKeyName:@"hostName"             andDefaultValue:@"tankradar.info"],
       [UserDefaultDesc userDefaultDescWithKeyName:@"port"                 andDefaultValue:[NSNumber numberWithInteger:443]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"secureConnection"     andDefaultValue:[NSNumber numberWithBool:YES]],
#else
       [UserDefaultDesc userDefaultDescWithKeyName:@"hostName"             andDefaultValue:@"planck.varetis.de"],
       [UserDefaultDesc userDefaultDescWithKeyName:@"port"                 andDefaultValue:[NSNumber numberWithInteger:22212]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"secureConnection"     andDefaultValue:[NSNumber numberWithBool:YES]],
#endif
       [UserDefaultDesc userDefaultDescWithKeyName:@"logConnection"        andDefaultValue:[NSNumber numberWithBool:NO]],

       [UserDefaultDesc userDefaultDescWithKeyName:@"pageSize"             andDefaultValue:[NSNumber numberWithInteger:20]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"radiusInMeter"        andDefaultValue:[NSNumber numberWithInteger:5000]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"distanceFilter"       andDefaultValue:[NSNumber numberWithInteger:1000]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"pushNotification"     andDefaultValue:[NSNumber numberWithBool:YES]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"apnsDeviceToken"      andDefaultValue:nil],
       [UserDefaultDesc userDefaultDescWithKeyName:@"locationUpdate"       andDefaultValue:[NSNumber numberWithBool:YES]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"simpleUI"             andDefaultValue:[NSNumber numberWithBool:NO]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"radarAnimation"       andDefaultValue:[NSNumber numberWithBool:YES]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"colorScheme"          andDefaultValue:[NSNumber numberWithInteger:0]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"lastSearch"           andDefaultValue:nil],
       [UserDefaultDesc userDefaultDescWithKeyName:@"sortCriteria"         andDefaultValue:[NSNumber numberWithInteger:0]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"listViewHelpStatus"   andDefaultValue:[NSNumber numberWithInteger:0]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"detailViewHelpStatus" andDefaultValue:[NSNumber numberWithInteger:0]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"walkthroughShowed"    andDefaultValue:[NSNumber numberWithBool:NO]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"useCloud"             andDefaultValue:[NSNumber numberWithBool:YES]]
     ];
    
    NSMutableDictionary* udd1 = [[NSMutableDictionary alloc] initWithCapacity:udd.count];
    for( UserDefaultDesc* u in udd )
      [udd1 setObject:u forKey:u.keyName];
    
    self.userDefaultDescription = udd1;
    
    self.userDefaults = [[NSMutableDictionary alloc] initWithCapacity:udd.count];
    
    [self registerUserDefaults];
    
    self.icloudId = [[NSFileManager defaultManager] ubiquityIdentityToken];
    
    _NSLOG(@"icloudId=%@",self.icloudId);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudAccountAvailabilityChanged:) name:NSUbiquityIdentityDidChangeNotification object: nil];
    
  } /* of if */
  
  return self;
}

#pragma mark Configuration parameter handling

/**
 *
 */
-(id) getConfigValue:(NSString*)key
{ id               result = nil;
  UserDefaultDesc* udd    = self.userDefaultDescription[key];
  
  if( udd )
  { result = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    if( result!=nil )
      [self.userDefaults setObject:result forKey:key];
  } /* of if */
  
  //_NSLOG(@"getConfigValue(%@):%@",key,result);
  
  return result;
}

/**
 *
 */
-(BOOL) hasConfigValueChanged:(NSString*)key
{ BOOL             result = NO;
  UserDefaultDesc* udd    = self.userDefaultDescription[key];
  
  if( udd )
  { NSObject* value0 = self.userDefaults[key];
    NSObject* value1 = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    
    result = (value0==nil && value1!=nil) || (value1!=nil && value0==nil) || ![value0 isEqual:value1];
  } /* of if */
  
  //_NSLOG(@"hasConfigValueChanged(%@):%d",key,result);
  
  return result;
}



/**
 *
 */
-(void) setConfigValue:(id)value forKey:(NSString*)key
{ UserDefaultDesc* udd    = self.userDefaultDescription[key];
  
  if( udd )
  { [[NSUserDefaults standardUserDefaults] setObject:value forKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.userDefaults setObject:value forKey:key];
  } /* of if */
  
  //_NSLOG(@"setConfigValue(value=%@,key=%@)",value,key);
}

/**
 *
 */
-(NSString*) hostName
{ return [self getConfigValue:@"hostName"]; }

/**
 *
 */
-(void) setHostName:(NSString *)value
{ [self setConfigValue:value forKey:@"hostName"]; }

/**
 *
 */
-(NSString*) apnsDeviceToken
{ return [self getConfigValue:@"apnsDeviceToken"]; }

/**
 *
 */
-(void) setApnsDeviceToken:(NSString *)value
{ [self setConfigValue:value forKey:@"apnsDeviceToken"]; }


/**
 *
 */
-(NSInteger) port
{ NSNumber* result = [self getConfigValue:@"port"]; return [result integerValue]; }

/**
 *
 */
-(void) setPort:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"port"]; }


/**
 *
 */
-(NSInteger) pageSize
{ NSNumber* result = [self getConfigValue:@"pageSize"]; return [result integerValue]; }

/**
 *
 */
-(void) setPageSize:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"pageSize"]; }


/**
 *
 */
-(NSInteger) radiusInMeter
{ NSNumber* result = [self getConfigValue:@"radiusInMeter"]; return [result integerValue]; }

/**
 *
 */
-(void) setRadiusInMeter:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"radiusInMeter"]; }


/**
 *
 */
-(NSInteger) distanceFilter
{ NSNumber* result = [self getConfigValue:@"distanceFilter"]; return [result integerValue]; }

/**
 *
 */
-(void) setDistanceFilter:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"distanceFilter"]; }

/**
 *
 */
-(NSInteger) colorScheme
{ NSNumber* result = [self getConfigValue:@"colorScheme"]; return [result integerValue]; }

/**
 *
 */
-(void) setColorScheme:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"colorScheme"]; }

/**
 *
 */
-(NSString*) lastSearch
{ NSString* result = [self getConfigValue:@"lastSearch"]; return result; }

/**
 *
 */
-(void) setLastSearch:(NSString*)value
{ [self setConfigValue:value forKey:@"lastSearch"]; }

/**
 *
 */
-(NSInteger) sortCriteria
{ NSNumber* result = [self getConfigValue:@"sortCriteria"]; return [result integerValue]; }

/**
 *
 */
-(void) setSortCriteria:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"sortCriteria"]; }

/**
 *
 */
-(NSInteger) listViewHelpStatus
{ NSNumber* result = [self getConfigValue:@"listViewHelpStatus"]; return [result integerValue]; }

/**
 *
 */
-(void) setListViewHelpStatus:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"listViewHelpStatus"]; }


/**
 *
 */
-(NSInteger) detailViewHelpStatus
{ NSNumber* result = [self getConfigValue:@"detailViewHelpStatus"]; return [result integerValue]; }

/**
 *
 */
-(void) setDetailViewHelpStatus:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"detailViewHelpStatus"]; }


/**
 *
 */
-(BOOL) secureConnection
{ NSNumber* result = [self getConfigValue:@"secureConnection"]; return [result boolValue]; }

/**
 *
 */
-(void) setSecureConnection:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"secureConnection"]; }

/**
 *
 */
-(BOOL) logConnection
{ NSNumber* result = [self getConfigValue:@"logConnection"]; return [result boolValue]; }

/**
 *
 */
-(void) setLogConnection:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"logConnection"]; }


/**
 *
 */
-(BOOL) locationUpdate
{ NSNumber* result = [self getConfigValue:@"locationUpdate"]; return [result boolValue]; }

/**
 *
 */
-(void) setLocationUpdate:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"locationUpdate"]; }

/**
 *
 */
-(BOOL) simpleUI
{ NSNumber* result = [self getConfigValue:@"simpleUI"]; return [result boolValue]; }

/**
 *
 */
-(void) setSimpleUI:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"simpleUI"]; }

/**
 *
 */
-(BOOL) radarAnimation
{ NSNumber* result = [self getConfigValue:@"radarAnimation"]; return [result boolValue]; }

/**
 *
 */
-(void) setRadarAnimation:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"radarAnimation"]; }


/**
 *
 */
-(BOOL) walkthroughShowed
{ NSNumber* result = [self getConfigValue:@"walkthroughShowed"]; return [result boolValue]; }

/**
 *
 */
-(void) setWalkthroughShowed:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"walkthroughShowed"]; }


/**
 *
 */
-(BOOL) useCloud
{ return NO;
}

/**
 *
 */
-(void) setUseCloud:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"useCloud"]; }



/**
 *
 */
-(BOOL) pushNotification
{ NSNumber* result = [self getConfigValue:@"pushNotification"]; return [result boolValue]; }

/**
 *
 */
-(void) setPushNotification:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"pushNotification"]; }

#if 0

/**
 *
 */
-(NSMethodSignature*) methodSignatureForSelector:(SEL)selector
{ _NSLOG_SELECTOR;
  
  NSMethodSignature* result = nil;
  
  NSString* sel = NSStringFromSelector(selector);
  if( [sel rangeOfString:@"set"].location==0 )
    result = [NSMethodSignature signatureWithObjCTypes:"v@:@"];
  else
    result = [NSMethodSignature signatureWithObjCTypes:"@@:"];
  
  return result;
}

/**
 *
 */
-(void) forwardInvocation:(NSInvocation *)invocation
{ NSString* key = NSStringFromSelector([invocation selector]);
  
  _NSLOG(@"key=%@",key);
  
  if( [key rangeOfString:@"set"].location==0 )
  {
    key = [[key substringWithRange:NSMakeRange(3, [key length]-4)] lowercaseString];
  
    NSString* obj;
    [invocation getArgument:&obj atIndex:2];
    
    [self.userDefaults setObject:obj forKey:key];
  } /* of if */
  else
  {
    NSString* obj = [self.userDefaults objectForKey:key];
    
    [invocation setReturnValue:&obj];
  } /* of else */
}
#endif 

#pragma mark Paths

/**
 *
 */
+(NSURL*) applicationDocumentsDirectory
{ return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject]; }

/**
 *
 */
+(NSString*) appBaseURL
{ return [NSString stringWithFormat:@"%@://",kAppBaseURLScheme]; }

/**
 *
 */
+(NSString*) appLandingPageURL:(NSString *)landingURL withCommand:(NSString*)cmd
{ return [NSString stringWithFormat:@"%@%@/%@",[self.class appBaseURL],cmd,landingURL]; }

/**
 *
 */
+(NSString*) appOpenLandingPageURL:(NSString *)landingURL
{ return [self appLandingPageURL:landingURL withCommand:@"open"]; }

/**
 *
 */
-(NSString*) baseURL
{ NSString* host   = self.hostName;
  NSInteger port   = self.port;
  BOOL      secure = self.secureConnection;
  NSString* scheme = secure ? @"https" : @"http";
  
  return [NSString stringWithFormat:@"%@://%@:%ld/",scheme,host,(long)port];
}


/**
 *
 */
-(NSString*) landingPageURL:(NSString *)landingURL
{ return [NSString stringWithFormat:@"%@%@",[self baseURL],landingURL]; }


/**
 *
 */
-(NSString*) imageURL:(NSString *)imageName
{ return [NSString stringWithFormat:@"%@%@/%@",[self baseURL],kUserDynamicPanelUrl,imageName]; }


/**
 *
 */
-(NSString*) restFavoriteListPath
{ return [NSString stringWithFormat:@"%@/%@",kUserDefaultRestUrlPrefix,kUserFavoritesRestUrlPrefix]; }

/**
 *
 */
-(NSString*) restQueryPath:(NSString*)path
{ return [NSString stringWithFormat:@"%@/%@",kUserDefaultRestUrlPrefix,path]; }

/**
 *
 */
-(NSString*) restFavoritesPath
{ return [NSString stringWithFormat:@"%@/%@",kUserDefaultRestUrlPrefix,kUserLandingPagesRestUrlPrefix]; }


/**
 *
 */
-(NSString*) restComplaintPath
{ return [NSString stringWithFormat:@"%@/%@",kUserDefaultRestUrlPrefix,kUserComplaintRestUrlPrefix]; }

/**
 *
 */
-(NSString*) autocompleteURL
{ return [NSString stringWithFormat:@"%@/%@",kUserDefaultRestUrlPrefix,kUserDefaultAutocompletePrefix]; }


/**
 *
 */
-(NSString*) statisticsURL:(NSString*)landingPageURL
{ return [NSString stringWithFormat:@"%@/%@/%@",kUserDefaultRestUrlPrefix,kUserDefaultStatisticsPrefix,landingPageURL]; }

/**
 *
 */
-(NSString*) tkrURL:(NSURL*)url
{ return [NSString stringWithFormat:@"%@%@",kUserDefaultRestUrlPrefix,url.path]; }

/**
 *
 */
-(NSString*) restCheckChangesPath
{ return [NSString stringWithFormat:@"%@/%@",kUserDefaultRestUrlPrefix,kUserLandingPagesRestUrlPrefix]; }


/**
 *
 */
+(BOOL) isAppURLScheme:(NSString*)scheme
{ return [scheme isEqualToString:kAppBaseURLScheme]; }


/**
 *
 */
+(NSURL*) keysDatabaseStoreURL
{ return [[self.class applicationDocumentsDirectory] URLByAppendingPathComponent:@"tresor-keys.sqlite"]; }

/**
 *
 */
+(NSURL*) dataDatabaseStoreURL
{ return [[self.class applicationDocumentsDirectory] URLByAppendingPathComponent:@"tresor-data.sqlite"]; }

/**
 *
 */
+(BOOL) keysDatabaseStoreExists
{ NSURL* url    = [self.class keysDatabaseStoreURL];
  BOOL   result = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
  
  return result;
}

/**
 *
 */
+(BOOL) dataDatabaseStoreExists
{ NSURL* url    = [self.class dataDatabaseStoreURL];
  BOOL   result = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
  
  return result;
}


#pragma mark User Defaults

/**
 *
 */
-(void) ubiquitousKeyValueStoreChanged:(NSNotification*) notification
{ NSDictionary* info         = notification.userInfo;
  NSNumber*     changeReason = info[NSUbiquitousKeyValueStoreChangeReasonKey];
  NSArray*      changedKeys  = info[NSUbiquitousKeyValueStoreChangedKeysKey];
  
  _NSLOG(@"ubiqKeyValueStore[%ld]:%@",(long)changeReason,changedKeys);
  
  _userId = nil;
}

/**
 *
 */
-(void) defaultsChanged:(NSNotification*)notification
{ _NSLOG_SELECTOR;
  
}


/**
 *
 */
-(void) registerUserDefaults
{ NSMutableDictionary* defaultValues = [[NSMutableDictionary alloc] initWithCapacity:self.userDefaultDescription.count];
  
  for( NSString* keyName in self.userDefaultDescription )
  { id defaultValue = [self.userDefaultDescription[keyName] defaultValue];
  
    if( defaultValue )
      [defaultValues setObject:defaultValue forKey:keyName];
  }
  
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(defaultsChanged:)
                                               name:NSUserDefaultsDidChangeNotification
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(ubiquitousKeyValueStoreChanged:)
                                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                             object:[NSUbiquitousKeyValueStore defaultStore]];
}


/**
 *
 */
-(void) resetUserDefaults
{ [NSUserDefaults resetStandardUserDefaults];
  
  NSString* appDomain = [[NSBundle mainBundle] bundleIdentifier];
  [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
 
  _NSLOG(@"resetUserDefaults:%@",appDomain);
  
  [NSUserDefaults standardUserDefaults];
  
  if( self.iCloudAvailable )
  { NSUbiquitousKeyValueStore* defaults = [NSUbiquitousKeyValueStore defaultStore];
    
    NSDictionary* content = [defaults dictionaryRepresentation];
    
    for( NSString* key in content.allKeys )
      [defaults removeObjectForKey:key];
    
    [defaults synchronize];
  } /* of if */
  
  self.userDefaults = [[NSMutableDictionary alloc] initWithCapacity:self.userDefaultDescription.count];
}


/**
 *
 */
-(NSString*) userId
{ if( _userId==nil && self.iCloudAvailable )
  { NSUbiquitousKeyValueStore* defaults = [NSUbiquitousKeyValueStore defaultStore];
    
    _NSLOG(@"NSUbiquitousKeyValueStore:%@",[defaults dictionaryRepresentation]);
      
    _userId = [defaults objectForKey:kAppUniqueUserId];
    
    if( _userId )
      [SSKeychain setPassword:_userId forService:kAppKeyChainService account:kAppUniqueUserId];
  } /* of if */
  
  if( _userId==nil )
    _userId = [SSKeychain passwordForService:kAppKeyChainService account:kAppUniqueUserId];
  
  if( _userId==nil )
  { NSUUID* uuid = [[NSUUID alloc] init];
    
    _userId = [uuid UUIDString];
    
    [SSKeychain setPassword:_userId forService:kAppKeyChainService account:kAppUniqueUserId];
  
    if( self.iCloudAvailable )
    { NSUbiquitousKeyValueStore* defaults = [NSUbiquitousKeyValueStore defaultStore];
      
      [defaults setObject:_userId forKey:kAppUniqueUserId];
      [defaults synchronize];
    } /* of if */
  } /* of if */
  
  return _userId;
}




/*
 *
 */
-(void) iCloudAccountAvailabilityChanged:(NSNotification *)note
{ _NSLOG_SELECTOR;
  
  self.icloudId = [[NSFileManager defaultManager] ubiquityIdentityToken];
}

/**
 *
 */
-(BOOL) iCloudAvailable
{ return self.icloudId!=nil; }
@end
