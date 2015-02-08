//
//  UIColor+Hexadecimal.h
//  vicinity
//
//  Created by Stefan Thomas on 23.01.15.
//  Copyright (c) 2015 LSSiEurope. All rights reserved.
//

@interface UIColor(Hexadecimal)
+(UIColor *) colorWithHexString:(NSString *)hexString;
-(NSString*) colorHexString;
@end
