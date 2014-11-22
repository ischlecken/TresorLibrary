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
#import "UIImage+Tint.h"

@implementation UIImage (Tint)

#pragma mark - Public methods

/**
 *
 */
- (UIImage *)tintedGradientImageWithColor:(UIColor *)tintColor andBackgroundColor:(UIColor*)backgroundColor
{
  return [self tintedImageWithColor:tintColor andBackgroundColor:backgroundColor blendingMode:kCGBlendModeOverlay];
}

/**
 *
 */
- (UIImage *)tintedImageWithColor:(UIColor *)tintColor andBackgroundColor:(UIColor*)backgroundColor
{
  return [self tintedImageWithColor:tintColor andBackgroundColor:backgroundColor blendingMode:kCGBlendModeDestinationIn];
}

/**
 *
 */
-(UIImage*) tintedImageWithColor:(UIColor *)tintColor andBackgroundColor:(UIColor*)backgroundColor blendingMode:(CGBlendMode)blendMode
{ static NSMutableDictionary* cache = nil;
  
  if( cache==nil )
    cache = [[NSMutableDictionary alloc] initWithCapacity:10];
  
  NSString* key    = [NSString stringWithFormat:@"%ld%@%@",(unsigned long)[self hash],[self cgColorToString:tintColor.CGColor],[self cgColorToString:backgroundColor.CGColor] ];
  UIImage*  result = [cache objectForKey:key];
  
  if( result==nil )
  { result = [self interalTintedImageWithColor:tintColor andBackgroundColor:backgroundColor blendingMode:blendMode];
  
    _NSLOG(@"key=%@",key);
    
    [cache setObject:result forKey:key];
  } /* of if */
  
  return result;
}


#pragma mark - Private methods

/**
 *
 */
- (NSString*) cgColorToString:(CGColorRef)cgColorRef
{
  const CGFloat *components = CGColorGetComponents(cgColorRef);
  int red = (int)(components[0] * 255);
  int green = (int)(components[1] * 255);
  int blue = (int)(components[2] * 255);
  int alpha = (int)(components[3] * 255);
  return [NSString stringWithFormat:@"#%0.2X%0.2X%0.2X%0.2X", red, green, blue, alpha];
}


/**
 *
 */
-(UIImage*) interalTintedImageWithColor:(UIColor *)tintColor  andBackgroundColor:(UIColor*)backgroundColor blendingMode:(CGBlendMode)blendMode
{ CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
  
  UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
  
  [tintColor setFill];
  UIRectFill(bounds);
  
  [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
  
  UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  
  UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
  
  [backgroundColor setFill];
  UIRectFill(bounds);

  [tintedImage drawInRect:bounds];

  UIImage* resultImage = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  return resultImage;
}

@end