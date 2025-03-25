//
//  PPTorreSettingModel.h
//  PPBluetoothKit
//
//  Created by 彭思远 on 2023/4/10.
//

#import <Foundation/Foundation.h>
//#import "PPBluetoothDeviceSettingModel.h"
#import <PPBaseKit/PPBaseKit.h>


NS_ASSUME_NONNULL_BEGIN

@interface PPUserHistoryData : NSObject

@property (nonatomic, assign) CGFloat weightKg;
@property (nonatomic, assign) double timeStamp;

@end

@interface PPTorreSettingModel : PPBluetoothDeviceSettingModel

@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *memberID;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, assign) NSInteger deviceHeaderIndex;

@property (nonatomic, assign) CGFloat currentWeight;
@property (nonatomic, assign) CGFloat targetWeight;
@property (nonatomic, assign) CGFloat idealWeight;


@property (nonatomic, copy) NSArray <PPUserHistoryData *> *recentData;

- (void)deleteMemberUnderAccount:(NSString *)userId;

- (void)userAccount:(NSString *)userId;

- (void)userAccount:(NSString *)userId memberId:(NSString *)memberId;

- (void)touristAccount;

- (void)defaultSettingAccount;
@end

NS_ASSUME_NONNULL_END
