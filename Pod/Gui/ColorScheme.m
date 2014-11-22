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
#import "ColorScheme.h"
 
#import "TresorConfig.h"

// #50CCFA
#define kTankradarColor0                 [UIColor colorWithRed: 80.0/255.0 green:204.0/255.0 blue:250.0/255.0 alpha:1.0]

// #12BDFA
#define kTankradarColor1                 [UIColor colorWithRed: 18.0/255.0 green:189.0/255.0 blue:250.0/255.0 alpha:1.0]

// #FB7E11
#define kTankradarColor2                 [UIColor colorWithRed:251.0/255.0 green:126.0/255.0 blue: 17.0/255.0 alpha:1.0]

// #00B737
#define kTankradarColorCheapest          [UIColor colorWithRed:  0.0/255.0 green:183.0/255.0 blue: 55.0/255.0 alpha:1.0]

// #E1081E
#define kTankradarColorExpensive         [UIColor colorWithRed:255.0/255.0 green:  8.0/255.0 blue: 30.0/255.0 alpha:1.0]

// #FB7E11
#define kTankradarColorNearest           [UIColor colorWithRed:251.0/255.0 green:126.0/255.0 blue: 17.0/255.0 alpha:1.0]

#define kTankradarTintColor              [UIColor colorWithRed:120.0/255.0 green:189.0/255.0 blue:255.0/255.0 alpha:1.0]

// #00B737
#define kTankradarColorGreen             [UIColor colorWithRed:  30.0/255.0 green:180.0/255.0 blue: 48.0/255.0 alpha:1.0]

// #00B737
#define kTankradarColorYellow            [UIColor colorWithRed: 254.0/255.0 green:205.0/255.0 blue: 50.0/255.0 alpha:1.0]


NSString* const ColorSchemeName[ColorSchemeCount] =
{ [ColorSchemeBlue]          = @"ColorSchemeBlue",
  [ColorSchemeCyan]          = @"ColorSchemeCyan",
  [ColorSchemeGreen]         = @"ColorSchemeGreen",
  [ColorSchemeYellow]        = @"ColorSchemeYellow",
  [ColorSchemeNight]         = @"ColorSchemeNight",
  [ColorSchemeHighContrast]  = @"ColorSchemeHighContrast",
};


@implementation GasPriceColorScheme

/**
 *
 */
- (id)init
{ self = [super init];
  
  if( self )
  { self.labelColor                 = [UIColor whiteColor];
    self.gaspriceColor              = [UIColor whiteColor];
    self.gastypeColor               = [UIColor whiteColor];
    self.displayBackgroundColor     = kTankradarTintColor;
    self.displayBorderColor         = [UIColor colorWithWhite:0.8 alpha:1.0];
    self.selectedDisplayBorderColor = [UIColor colorWithHue:0.17 saturation:0.8 brightness:1.0 alpha:0.5];
    self.frameColor                 = kTankradarTintColor;
    self.frameBorderColor           = [UIColor colorWithWhite:0.8 alpha:1.0];
  } /* of if */
  
  return self;
}

/**
 *
 */
-(void) createNightScheme
{ self.displayBackgroundColor = [ColorSchemeInstance getNightColor:self.displayBackgroundColor];
  self.frameColor             = [ColorSchemeInstance getNightColor:self.frameColor];
  
  self.labelColor             = [ColorSchemeInstance getNightColor:self.labelColor];
  self.gastypeColor           = [ColorSchemeInstance getNightColor:self.gastypeColor];
  self.displayBorderColor     = [ColorSchemeInstance getNightColor:self.displayBorderColor];
  self.frameBorderColor       = [ColorSchemeInstance getNightColor:self.frameBorderColor];
  
  self.gaspriceColor          = [UIColor yellowColor];
}

@end

@implementation ColorScheme
@end

@implementation ColorSchemeInstance


/**
 *
 */
+(UIColor*) getNightColor:(UIColor*)c
{ CGFloat  hue;
  CGFloat  saturation;
  CGFloat  bright;
  CGFloat  alpha;
  UIColor* result = c;
  
  if( [c getHue:&hue saturation:&saturation brightness:&bright alpha:&alpha] )
    result = [UIColor colorWithHue:hue saturation:saturation*0.9 brightness:bright*0.6 alpha:alpha];
  else if( [c getWhite:&hue alpha:&alpha] )
    result = [UIColor colorWithWhite:hue*0.9 alpha:alpha];
  
  return result;
}

/**
 *
 */
-(void) setType:(ColorSchemeType)type
{ _type = type;

  ColorScheme* newColorScheme = [ColorScheme new];
  
  newColorScheme.tintColor         = kTankradarTintColor;
  newColorScheme.radarColor        = [UIColor colorWithRed:0.2f green:0.7f blue:0.2f alpha:0.9f];
  newColorScheme.selectedTintColor = kTankradarColor2;
  newColorScheme.cheapestColor     = kTankradarColorCheapest;
  newColorScheme.nearestColor      = kTankradarColorNearest;
  newColorScheme.expensiveColor    = kTankradarColorExpensive;
  newColorScheme.gasPriceColors    = [GasPriceColorScheme new];
  
  if( type==ColorSchemeCyan )
  { newColorScheme.tintColor                             = kTankradarColor0;
    newColorScheme.gasPriceColors.displayBackgroundColor = kTankradarColor0;
    newColorScheme.gasPriceColors.frameColor             = kTankradarColor0;
  } /* of if */
  else if( type==ColorSchemeGreen )
  { newColorScheme.radarColor                            = [UIColor magentaColor];
    newColorScheme.tintColor                             = kTankradarColorGreen;
    newColorScheme.gasPriceColors.displayBackgroundColor = kTankradarColorGreen;
    newColorScheme.gasPriceColors.frameColor             = kTankradarColorGreen;
  } /* of if */
  else if( type==ColorSchemeYellow )
  { newColorScheme.radarColor                            = kTankradarTintColor;
    newColorScheme.tintColor                             = kTankradarColorYellow;
    newColorScheme.gasPriceColors.displayBackgroundColor = kTankradarColorYellow;
    newColorScheme.gasPriceColors.frameColor             = kTankradarColorYellow;
  } /* of if */
  else if( type==ColorSchemeNight )
  { newColorScheme.tintColor         = [UIColor lightGrayColor];
    newColorScheme.radarColor        = [UIColor yellowColor];
    [newColorScheme.gasPriceColors createNightScheme];
  } /* of else if */
  else if( type==ColorSchemeHighContrast )
  { newColorScheme.tintColor         = [UIColor blackColor];
    newColorScheme.radarColor        = [UIColor yellowColor];
    
    [newColorScheme.gasPriceColors createNightScheme];
    
    newColorScheme.gasPriceColors.displayBackgroundColor = [UIColor blackColor];
    newColorScheme.gasPriceColors.frameColor             = [UIColor blackColor];
  } /* of else if */
  
  _NSLOG(@"type=%d",type);
  
  self.colorScheme = newColorScheme;
  
  _TRESORCONFIG.colorScheme = type;
}

/**
 *
 */
-(void) setTypeFromUserDefault
{ NSInteger type = _TRESORCONFIG.colorScheme;
  
  self.type = (ColorSchemeType)type;
}

/**
 *
 */
+(ColorSchemeInstance*) sharedInstance
{ static ColorSchemeInstance* _inst = nil;
  static dispatch_once_t      oncePredicate;
  
  dispatch_once(&oncePredicate,
  ^{
     _inst = [[self alloc] init];
    
    [_inst setTypeFromUserDefault];
  });
  
  return _inst;
  
}

@end
