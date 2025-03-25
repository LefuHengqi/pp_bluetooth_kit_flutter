//
//  PPTorreSettingModel.h
//  PPBluetoothKit
//
//  Created by 彭思远 on 2023/4/10.
//

#import <Foundation/Foundation.h>
//#import "PPBluetoothDeviceSettingModel.h"
#import <PPBaseKit/PPBaseKit.h>
#import "PPTorreSettingModel.h"

NS_ASSUME_NONNULL_BEGIN



@interface PPDorreSettingModel : PPBluetoothDeviceSettingModel

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *memberID;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) NSInteger deviceHeaderIndex;

@property (nonatomic, assign) CGFloat currentWeight;
@property (nonatomic, assign) CGFloat targetWeight;
@property (nonatomic, assign) CGFloat idealWeight;


//local pIndex
@property (nonatomic, assign) NSInteger PIndex;


@property (nonatomic, copy) NSArray <PPUserHistoryData *> *recentData;

- (void)deleteMemberUnderAccount:(NSString *)userId;

- (void)userAccount:(NSString *)userId;

- (void)userAccount:(NSString *)userId memberId:(NSString *)memberId;

- (void)touristAccount;

- (void)defaultSettingAccount;
@end

NS_ASSUME_NONNULL_END
