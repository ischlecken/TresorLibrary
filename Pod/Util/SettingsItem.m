//
//  Created by Stefan Thomas on 15.01.2015.
//  Copyright (c) 2015 LSSi Europe. All rights reserved.
//

#import "SettingsItem.h"

@implementation SettingsItem

/**
 *
 */
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId
{ SettingsItem* result = [SettingsItem new];
  
  result.title        = title;
  result.cellId       = cellId;
  result.keyboardType = UIKeyboardTypeDefault;
  result.selectAction = NULL;
  result.pickerValues = nil;
  result.selectedPickerValue = 0;
  
  return result;
}

/**
 *
 */
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andSelectAction:(SelectActionType)selectAction
{ SettingsItem* result = [SettingsItem new];
  
  result.title        = title;
  result.cellId       = cellId;
  result.keyboardType = UIKeyboardTypeDefault;
  result.selectAction = selectAction;
  result.pickerValues = nil;
  result.selectedPickerValue = 0;
  
  return result;
}

/**
 *
 */
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andSelectAction:(SelectActionType)selectAction andPickerValues:(NSArray*)pickerValues
{ SettingsItem* result = [SettingsItem new];
  
  result.title               = title;
  result.cellId              = cellId;
  result.keyboardType        = UIKeyboardTypeDefault;
  result.selectAction        = selectAction;
  result.pickerValues        = pickerValues;
  result.selectedPickerValue = 0;
  
  return result;
}


/**
 *
 */
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andPickerValues:(NSArray*)pickerValues andSelectedPickerValue:(NSInteger)selectedPicerValue
{ SettingsItem* result = [SettingsItem new];
  
  result.title               = title;
  result.cellId              = cellId;
  result.keyboardType        = UIKeyboardTypeDefault;
  result.selectAction        = NULL;
  result.pickerValues        = pickerValues;
  result.selectedPickerValue = selectedPicerValue;
  
  return result;
}


/**
 *
 */
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andKeyboardType:(NSUInteger)keyboardType
{ SettingsItem* result = [SettingsItem new];
  
  result.title        = title;
  result.cellId       = cellId;
  result.keyboardType = keyboardType;
  result.selectAction = NULL;
  result.pickerValues = nil;
  result.selectedPickerValue = 0;
  
  return result;
}
@end
