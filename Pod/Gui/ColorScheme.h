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

@interface GasPriceColorScheme : NSObject
@property UIColor* labelColor;
@property UIColor* gaspriceColor;
@property UIColor* gastypeColor;
@property UIColor* displayBackgroundColor;
@property UIColor* displayBorderColor;
@property UIColor* selectedDisplayBorderColor;
@property UIColor* frameColor;
@property UIColor* frameBorderColor;
@end

typedef enum
{ ColorSchemeBlue         = 0,
  ColorSchemeCyan            ,
  ColorSchemeGreen           ,
  ColorSchemeYellow          ,
  ColorSchemeNight           ,
  ColorSchemeHighContrast    ,
  ColorSchemeCount      
} ColorSchemeType;
extern NSString* const ColorSchemeName[ColorSchemeCount];

@interface ColorScheme : NSObject
@property UIColor*             tintColor;
@property UIColor*             radarColor;
@property UIColor*             selectedTintColor;
@property UIColor*             cheapestColor;
@property UIColor*             expensiveColor;
@property UIColor*             nearestColor;

@property GasPriceColorScheme* gasPriceColors;
@end

@interface ColorSchemeInstance : NSObject
@property(nonatomic,strong) ColorScheme*    colorScheme;
@property(nonatomic,assign) ColorSchemeType type;

-(void)                 setTypeFromUserDefault;

+(UIColor*)             getNightColor:(UIColor*)c;
+(ColorSchemeInstance*) sharedInstance;
@end

#define _COLORSCHEME     [ColorSchemeInstance sharedInstance].colorScheme
#define _COLORSCHEMETYPE [ColorSchemeInstance sharedInstance].type

