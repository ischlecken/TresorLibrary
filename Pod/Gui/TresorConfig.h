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


@property(          strong, nonatomic) NSString*    hostName;
@property(          assign, nonatomic) NSInteger    port;
@property(          assign, nonatomic) BOOL         secureConnection;
@property(          assign, nonatomic) NSInteger    pageSize;
@property(          assign, nonatomic) NSInteger    radiusInMeter;
@property(          assign, nonatomic) BOOL         logConnection;

@property(          assign, nonatomic) BOOL         locationUpdate;
@property(          assign, nonatomic) NSInteger    distanceFilter;

@property(          assign, nonatomic) NSInteger    colorScheme;
@property(          strong, nonatomic) NSString*    lastSearch;
@property(          assign, nonatomic) NSInteger    sortCriteria;

@property(          assign, nonatomic) BOOL         simpleUI;
@property(          assign, nonatomic) BOOL         radarAnimation;
@property(          assign, nonatomic) BOOL         walkthroughShowed;

@property(          assign, nonatomic) BOOL         useCloud;
@property(          strong, nonatomic) id           icloudId;

@property(          assign, nonatomic) NSInteger    listViewHelpStatus;
@property(          assign, nonatomic) NSInteger    detailViewHelpStatus;

@property(          strong, nonatomic) NSString*    apnsDeviceToken;
@property(          assign, nonatomic) BOOL         pushNotification;
@property(readonly, strong, nonatomic) NSString*    userId;

+(NSURL*)                        applicationDocumentsDirectory;
+(NSString*)                     appBaseURL;
+(NSString*)                     appLandingPageURL:(NSString *)landingURL withCommand:(NSString*)cmd;
+(NSString*)                     appOpenLandingPageURL:(NSString *)landingURL;
-(NSString*)                     baseURL;
-(NSString*)                     landingPageURL:(NSString*)landingURL;
-(NSString*)                     restFavoriteListPath;
-(NSString*)                     restCheckChangesPath;
-(NSString*)                     autocompleteURL;
-(NSString*)                     tkrURL:(NSURL*)url;
-(NSString*)                     statisticsURL:(NSString*)landingPageURL;

-(NSString*)                     restQueryPath:(NSString*)path;
-(NSString*)                     restFavoritesPath;
-(NSString*)                     restComplaintPath;
-(NSString*)                     imageURL:(NSString *)imageName;

-(void)                          resetUserDefaults;
-(BOOL)                          iCloudAvailable;

+(BOOL)                          isAppURLScheme:(NSString*)scheme;

+(NSURL*)                        keysDatabaseStoreURL;
+(BOOL)                          keysDatabaseStoreExists;
+(NSURL*)                        dataDatabaseStoreURL;
+(BOOL)                          dataDatabaseStoreExists;

+(instancetype)                  sharedInstance;

@end
