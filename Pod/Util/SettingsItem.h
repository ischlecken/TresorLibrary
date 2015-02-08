//
//  Created by Stefan Thomas on 15.01.2015.
//  Copyright (c) 2015 LSSi Europe. All rights reserved.
//

@class SettingsItem;

typedef void (^SelectActionType)(NSIndexPath* indexPath,SettingsItem* item);

@interface SettingsItem : NSObject
@property(nonatomic,strong) NSString*        title;
@property(nonatomic,strong) NSString*        cellId;
@property(nonatomic,assign) NSUInteger       keyboardType;
@property(nonatomic,copy  ) SelectActionType selectAction;
@property(nonatomic,strong) NSArray*         pickerValues;
@property(nonatomic,assign) NSInteger        selectedPickerValue;

+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId;
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andSelectAction:(SelectActionType)selectAction;
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andSelectAction:(SelectActionType)selectAction andPickerValues:(NSArray*)pickerValues;
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andPickerValues:(NSArray*)pickerValues andSelectedPickerValue:(NSInteger)selectedPicerValue;
+(instancetype) settingItemWithTitle:(NSString*)title andCellId:(NSString*)cellId andKeyboardType:(NSUInteger)keyboardType;

@end
