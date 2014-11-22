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
#import "ColorScheme.h"

#define kBackgroundImage                  @"background.png"

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
    
    backgroundImage = [backgroundImage tintedImageWithColor:_COLORSCHEME.tintColor andBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1.0]];
    
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
@end
