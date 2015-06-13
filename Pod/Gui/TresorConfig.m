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
#import "UIColor+Hexadecimal.h"

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
@property(nonatomic,strong) NSDictionary*        userDefaultDescription;
@property(nonatomic,strong) NSMutableDictionary* userDefaults;

@property(nonatomic,strong) NSDictionary*        colorScheme;
@property(nonatomic,strong) NSMutableDictionary* colorCache;

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
       [UserDefaultDesc userDefaultDescWithKeyName:@"colorSchemeName"      andDefaultValue:@"default"],
       [UserDefaultDesc userDefaultDescWithKeyName:@"useCloud"             andDefaultValue:[NSNumber numberWithBool:NO]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"useTouchID"           andDefaultValue:[NSNumber numberWithBool:NO]],
       [UserDefaultDesc userDefaultDescWithKeyName:@"usageCount"           andDefaultValue:[NSNumber numberWithInteger:0]]
     ];
    
    NSMutableDictionary* udd1 = [[NSMutableDictionary alloc] initWithCapacity:udd.count];
    for( UserDefaultDesc* u in udd )
      [udd1 setObject:u forKey:u.keyName];
    
    self.userDefaultDescription = udd1;
    self.userDefaults = [[NSMutableDictionary alloc] initWithCapacity:udd.count];
    
    [self registerUserDefaults];
    [self loadColorScheme];
    [self loadIconList];
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
-(BOOL) configValueExists:(NSString*)key
{ UserDefaultDesc* udd = self.userDefaultDescription[key];
  
  return udd!=nil;
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
    
    if( [key isEqualToString:@"colorSchemeName"] )
    { self.colorCache = nil;
    } /* of else if */
  } /* of if */
  
  //_NSLOG(@"setConfigValue(value=%@,key=%@)",value,key);
}

/**
 *
 */
-(BOOL) useCloud
{ return [[self getConfigValue:@"useCloud"] boolValue];
}

/**
 *
 */
-(void) setUseCloud:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"useCloud"]; }

/**
 *
 */
-(BOOL) useTouchID
{ return [[self getConfigValue:@"useTouchID"] boolValue];
}

/**
 *
 */
-(void) setUseTouchID:(BOOL)value
{ [self setConfigValue:[NSNumber numberWithBool:value] forKey:@"useTouchID"]; }


/**
 *
 */
-(NSInteger) usageCount
{ NSNumber* result = [self getConfigValue:@"usageCount"]; return [result integerValue]; }

/**
 *
 */
-(void) setUsageCount:(NSInteger)value
{ [self setConfigValue:[NSNumber numberWithInteger:value] forKey:@"usageCount"]; }

/**
 *
 */
-(NSString*) colorSchemeName
{ return [self getConfigValue:@"colorSchemeName"]; }

/**
 *
 */
-(void) setColorSchemeName:(NSString*)value
{ [self setConfigValue:value forKey:@"colorSchemeName"]; }

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
-(NSURL*) databaseStoreURL
{ NSString* dbName = self.databaseStoreName ? self.databaseStoreName : @"tresor.sqlite";
  
  return [[self.class applicationDocumentsDirectory] URLByAppendingPathComponent:dbName];
}

/**
 *
 */
-(BOOL) databaseStoreExists
{ NSURL* url    = [self databaseStoreURL];
  BOOL   result = [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
  
  return result;
}

/**
 *
 */
+(NSURL*) appGroupURLForFileName:(NSString*)fileName
{ NSURL* storeURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kAppGroup];
  NSURL* result   = [storeURL URLByAppendingPathComponent:fileName];
  
  //_NSLOG(@"result:%@",result);
  
  return result;
}

/**
 *
 */
+(void) copyToSharedLocationIfNotExists:(NSString*)fileName andType:(NSString*)fileType
{ NSString* sharedFilePath = [[TresorConfig appGroupURLForFileName:[NSString stringWithFormat:@"%@.%@",fileName,fileType]] path];
  
  if( ![[NSFileManager defaultManager] fileExistsAtPath:sharedFilePath] )
  { NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
    NSError*  error    = nil;
    
    if( ![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:sharedFilePath error:&error] )
      _NSLOG(@"could not copy %@ to %@:%@",filePath,sharedFilePath,error);
  } /* of if */
}

/**
 *
 */
+(void) copyToSharedLocation:(NSString*)fileName andType:(NSString*)fileType
{ NSString* sharedFilePath = [[TresorConfig appGroupURLForFileName:[NSString stringWithFormat:@"%@.%@",fileName,fileType]] path];
  
  NSError* error = nil;
  
  if( [[NSFileManager defaultManager] fileExistsAtPath:sharedFilePath] )
  { if( ![[NSFileManager defaultManager] removeItemAtPath:sharedFilePath error:&error] )
    _NSLOG(@"could not remove %@:%@",sharedFilePath,error);
  } /* of if */
  
  NSString* filePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
  if( ![[NSFileManager defaultManager] copyItemAtPath:filePath toPath:sharedFilePath error:&error] )
    _NSLOG(@"could not copy %@ to %@:%@",filePath,sharedFilePath,error);
}

/**
 *
 */
+(BOOL) copyIfModified:(NSURL*)sourceURL destination:(NSURL*)destinationURL
{ BOOL           result      = NO;
  BOOL           copyFile    = NO;
  NSFileManager* fileManager = [NSFileManager defaultManager];
  
  if( sourceURL && destinationURL )
  { if( ![fileManager fileExistsAtPath:[destinationURL path]] )
    copyFile = YES;
  else
  { NSDictionary* sourceFileAttributes = [fileManager attributesOfItemAtPath:[sourceURL path] error:NULL];
    NSDictionary* destFileAttributes   = [fileManager attributesOfItemAtPath:[destinationURL path] error:NULL];
    
    if( sourceFileAttributes && destFileAttributes )
    { NSNumber* sourceFileSize = sourceFileAttributes[NSFileSize];
      NSNumber* destFileSize   = destFileAttributes[NSFileSize];
      
      _NSLOG(@"sourceFileSize:%@ destFileSize:%@",sourceFileSize,destFileSize);
      
      if( ![sourceFileSize isEqualToNumber:destFileSize] )
        copyFile = YES;
    } /* of if */
  } /* of else */
    
    if( copyFile )
    { NSError* error = nil;
      
      if( [fileManager fileExistsAtPath:[destinationURL path]] &&
         ![fileManager removeItemAtPath:[destinationURL path] error:&error]
         )
        _NSLOG(@"remove of %@ failed:%@",destinationURL,error);
      
      if( [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&error] )
      { _NSLOG(@"copied %@ to %@",sourceURL,destinationURL);
        
        result = YES;
      } /* of if */
      else
        _NSLOG(@"copy of %@ to %@ failed:%@",sourceURL,destinationURL,error);
    } /* of if */
  } /* of if */
  
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
  
  self.userDefaults = [[NSMutableDictionary alloc] initWithCapacity:self.userDefaultDescription.count];
}



#pragma mark Info

/**
 *
 */
-(NSString*) appName
{ NSDictionary* localizedInfo    = [[NSBundle bundleForClass:[self class]] localizedInfoDictionary];
  
  return localizedInfo[@"CFBundleDisplayName"];
}

/**
 *
 */
-(NSString*) appVersion
{ NSDictionary* info             = [[NSBundle bundleForClass:[self class]] infoDictionary];
  
  return info[@"CFBundleShortVersionString"];
}

/**
 *
 */
-(NSString*) appBuild
{ NSDictionary* info             = [[NSBundle bundleForClass:[self class]] infoDictionary];
  
  return info[@"CFBundleVersion"];
}

#pragma mark Colorscheme

/**
 *
 */
-(void) loadColorScheme
{ NSError*      error    = nil;
  NSString*     dataPath = [[TresorConfig colorSchemeURL] path];
  
  if( dataPath )
    self.colorScheme = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                       options:kNilOptions
                                                         error:&error];
  
  //_NSLOG(@"colorScheme:%@",self.colorScheme);
}


/**
 *
 */
-(NSArray*) colorSchemeNames
{ NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:3];
  
  for( NSString* colorSchemeName in self.colorScheme )
    [result addObject:colorSchemeName];
  
  return result;
}

/**
 *
 */
-(id) colorWithName:(NSString*)colorName
{ id result = nil;
  
  if( self.colorCache==nil )
    self.colorCache = [[NSMutableDictionary alloc] initWithCapacity:10];
  
  result = [self.colorCache objectForKey:colorName];
  
  if( result==nil && self.colorScheme )
  { NSDictionary* currentColorScheme = [self.colorScheme objectForKey:self.colorSchemeName];
    
    if( currentColorScheme )
    { id colorValue = [currentColorScheme objectForKey:colorName];
      
      if( [colorValue isKindOfClass:[NSString class]] )
        result = [UIColor colorWithHexString:colorValue];
      else if( [colorValue isKindOfClass:[NSArray class]] )
      { NSMutableArray* colors = [[NSMutableArray alloc] initWithCapacity:5];
        
        for( NSString* c in colorValue )
          [colors addObject:[UIColor colorWithHexString:c]];
        
        result = colors;
      } /* of else if */
      
      if( result )
        [self.colorCache setObject:result forKey:colorName];
    } /* of if */
  } /* of if */
  
  //_NSLOG(@"%@:%@",colorName,result);
  
  return result;
}

/**
 *
 */
+(NSURL*) colorSchemeURL
{
#if 0
  return [TresorConfig appGroupURLForFileName:[NSString stringWithFormat:@"%@.json",kColorSchemeFileName]];
#else
  NSString* path = [[NSBundle mainBundle] pathForResource:kColorSchemeFileName ofType:@"json"];
  
  return [NSURL fileURLWithPath:path];
#endif
}

#pragma mark IconList

/**
 *
 */
-(void) loadIconList
{ NSString* dataPath = [[NSBundle mainBundle] pathForResource:kIconListFileName ofType:@"json"];
  NSError*  error    = nil;
  
  if( dataPath )
  { NSArray* iconList = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:dataPath]
                                                        options:kNilOptions
                                                          error:&error];
    
    if( iconList )
      self->_iconList = iconList;
  } /* of if */
}
@end
