//
//  UIColor+Hexadecimal.m
//  vicinity
//
//  Created by Stefan Thomas on 23.01.15.
//  Copyright (c) 2015 LSSiEurope. All rights reserved.
//

#import "UIColor+Hexadecimal.h"

@implementation UIColor(Hexadecimal)

/**
 *
 */
+(UIColor*) colorWithHexString:(NSString *)hexString
{ UIColor* result = [UIColor clearColor];
  
  if( hexString && (hexString.length==7 || hexString.length==9) )
  { unsigned   rgbValue = 0;
    NSScanner* scanner  = [NSScanner scannerWithString:hexString];
    
    // bypass '#' character
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    
    CGFloat red   = ((rgbValue & 0xFF0000) >> 16)/255.0;
    CGFloat green = ((rgbValue & 0xFF00  ) >>  8)/255.0;
    CGFloat blue  = ((rgbValue & 0xFF    )      )/255.0;
    CGFloat alpha = 1.0;
    
    if( hexString.length==9 )
      alpha = ((rgbValue & 0xFF000000) >> 24)/255.0;
    
    result = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
  } /* of if */
  
  return result;
}

/**
 *
 */
-(NSString*) colorHexString
{ NSMutableString* result = [[NSMutableString alloc] initWithCapacity:9];
  
  CGFloat red   = 0.0;
  CGFloat green = 0.0;
  CGFloat blue  = 0.0;
  CGFloat alpha = 1.0;
  
  [self getRed:&red green:&green blue:&blue alpha:&alpha];
  
  [result appendString:@"#"];
  
  if( alpha!=1.0 )
    [result appendString:[NSString stringWithFormat:@"%02lx",(long)round(alpha*255.0)]];

  [result appendString:[NSString stringWithFormat:@"%02lx",(long)round(red   * 255.0)]];
  [result appendString:[NSString stringWithFormat:@"%02lx",(long)round(green * 255.0)]];
  [result appendString:[NSString stringWithFormat:@"%02lx",(long)round(blue  * 255.0)]];

  return result;
}

@end