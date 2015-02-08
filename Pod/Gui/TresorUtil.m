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

#import <AudioToolbox/AudioToolbox.h>
#import "TresorUtil.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+Tint.h"
#import "TresorConfig.h"
#import "TresorDefaults.h"
#import "Macros.h"

@interface TresorUtil ()
@property(nonatomic,strong) NSMutableArray* backgroundImages;
@end

@implementation TresorUtil

/**
 *
 */
+(instancetype) sharedInstance
{ static dispatch_once_t once;
  static TresorUtil*        sharedInstance;
  
  dispatch_once(&once, ^{ sharedInstance = [self new]; });
  
  return sharedInstance;
}

/**
 *
 */
+(UIImage*) tintedImage:(NSString*)imageName
{ UIImage* image = [UIImage imageNamed:imageName];
  
  image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
  
  return image;
}

/**
 *
 */
+(UIImage*) blurredBackgroundImage:(BOOL)extraLight forView:(UIView*)view
{ UIImage* image = [TresorUtil backgroundImage:view];
  
  image = extraLight ? [image applyExtraLightEffect] : [image applyLightEffect];
  
  return image;
}

/**
 *
 */
+(UIImage*) backgroundImage:(UIView*)view
{ CGSize  size = view.bounds.size;
  
  UIGraphicsBeginImageContext(size);
  [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
  
  UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

/**
 *
 */
-(void) resetBackgroundImage
{ self.backgroundImages=nil; }

/**
 *
 */
-(UIImage*) backgroundImage:(BOOL)extraLight
{ if( self.backgroundImages==nil )
  { self.backgroundImages = [[NSMutableArray alloc] initWithCapacity:2];
    
    [self.backgroundImages addObject:[NSNull null]];
    [self.backgroundImages addObject:[NSNull null]];
  } /* of if */
  
  int index = extraLight;
  
  if( [self.backgroundImages[index] isKindOfClass:[NSNull class]] )
  { UIImage* backgroundImage = [UIImage imageNamed:kBackgroundImage];
    
    UIColor* tintColor = [_TRESORCONFIG colorWithName:kTintColorName];
    
    backgroundImage = [backgroundImage tintedImageWithColor:tintColor andBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
    self.backgroundImages[index] = extraLight ? [backgroundImage applyExtraLightEffect] : [backgroundImage applyLightEffect];
  } /* of if */
  
  return self.backgroundImages[index];
}

/**
 *
 */
+(void) playSound:(NSString*)soundName
{ NSURL*        soundPath =  [[NSBundle mainBundle] URLForResource:soundName withExtension:@"caf"];
  SystemSoundID soundID;
  
  AudioServicesCreateSystemSoundID((__bridge CFURLRef)soundPath, &soundID);
  AudioServicesPlaySystemSound (soundID);
}

/**
 *
 */
+(void) earthquake:(UIView*)itemView
{ CGFloat t        = 4.0;
  
  CGAffineTransform leftQuake  = CGAffineTransformTranslate(CGAffineTransformIdentity, t, -t);
  CGAffineTransform rightQuake = CGAffineTransformTranslate(CGAffineTransformIdentity, -t, t);
  
  itemView.transform = leftQuake;  // starting point
  
  
  [UIView animateWithDuration:0.07
                        delay:0
                      options:UIViewAnimationOptionAutoreverse
                   animations:^
   { [UIView setAnimationRepeatCount:4];
     itemView.transform = rightQuake;
   }
                   completion:^(BOOL finished)
   { if( finished )
       itemView.transform = CGAffineTransformIdentity;
     
   }];
}

#pragma mark app info

/**
 *
 */
+(void) aboutDialogue:(UIViewController*)vc
{ NSString*          aboutTitleTmpl   = _LSTR(@"TresorUtil.AboutTitle");
  NSString*          aboutMessageTmpl = _LSTR(@"TresorUtil.AboutMessage");
  NSString*          aboutTitle       = [NSString stringWithFormat:aboutTitleTmpl,[_TRESORCONFIG appName]];
  NSString*          aboutMessage     = [NSString stringWithFormat:aboutMessageTmpl,[_TRESORCONFIG appVersion],[_TRESORCONFIG appBuild]];
  UIAlertController* alert            = [UIAlertController alertControllerWithTitle:aboutTitle message:aboutMessage preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:_LSTR(@"TresorUtil.OKButtonTitle") style:UIAlertActionStyleDefault handler:NULL]];
  
  [vc presentViewController:alert animated:YES completion:NULL];
}



/**
 *
 */
+(void) openAppStore
{ NSString* appURL = [NSString stringWithFormat:kAppStoreBaseURL2,kAppName,(long)kAppID,kAppStoreBaseURL1];
  
  _NSLOG(@"appURL:%@",appURL);
  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURL]];
}

/**
 *
 */
+(void) appStoreRatingReminderDialogue:(UIViewController*)vc
{ NSString* alertTitle   = _LSTR(@"RatingReminder.Title");
  NSString* alertMessage = _LSTR(@"RatingReminder.Message");
  NSString* appName      = [_TRESORCONFIG appName];
  
  UIAlertController* alert    = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:alertTitle,appName]
                                                                    message:[NSString stringWithFormat:alertMessage,appName]
                                                             preferredStyle:UIAlertControllerStyleAlert];
  
  [alert addAction:[UIAlertAction actionWithTitle:_LSTR(@"RatingReminder.RateNow.Title") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action)
                    { _TRESORCONFIG.usageCount = -1000;
                      [TresorUtil openAppStore];
                    }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:_LSTR(@"RatingReminder.RemindLater.Title") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                    { _TRESORCONFIG.usageCount = 0;
                    }]];
  
  [alert addAction:[UIAlertAction actionWithTitle:_LSTR(@"RatingReminder.NoNever.Title") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                    { _TRESORCONFIG.usageCount = -10000;
                    }]];
  
  [vc presentViewController:alert animated:YES completion:NULL];
}

/**
 *
 */
+(void) openHomepage
{ [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kHomepageURL]];
}

@end
