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

#define _TRESORCONFIG [TresorConfig sharedInstance]

@interface TresorConfig : NSObject
@property(          assign, nonatomic) BOOL         useCloud;
@property(          assign, nonatomic) NSInteger    usageCount;

@property(          strong, nonatomic) NSString*    colorSchemeName;
@property(readonly, strong, nonatomic) NSArray*     colorSchemeNames;

@property(readonly, strong, nonatomic) NSArray*     iconList;

@property(readonly ,strong, nonatomic) NSString*    appName;
@property(readonly ,strong, nonatomic) NSString*    appVersion;
@property(readonly ,strong, nonatomic) NSString*    appBuild;

-(id)           getConfigValue:(NSString*)key;
-(BOOL)         hasConfigValueChanged:(NSString*)key;
-(BOOL)         configValueExists:(NSString*)key;
-(void)         setConfigValue:(id)value forKey:(NSString*)key;

-(void)         resetUserDefaults;
-(id)           colorWithName:(NSString*)colorName;

+(NSURL*)       applicationDocumentsDirectory;
+(NSURL*)       databaseStoreURL;
+(NSURL*)       colorSchemeURL;

+(BOOL)         databaseStoreExists;
+(instancetype) sharedInstance;
@end
