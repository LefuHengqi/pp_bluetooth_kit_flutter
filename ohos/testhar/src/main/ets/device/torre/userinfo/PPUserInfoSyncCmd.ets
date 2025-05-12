import { PPBleFFF2ErrorCode } from "../../../enums/PPBleFFF2ErrorCode";
import { PPLogger } from "../../../log/PPLogger";
import { PPDeviceModel } from "../../../vo/PPDeviceModel";
import call from "@ohos.telephony.call";
import { TorreHelper } from "../TorreHelper";
import HexUtil from "../../../utils/HexUtil";
import { ByteUtil } from "../../../utils/ByteUtil";
import { PPUserModel } from "../../../vo/PPUserModel";
import { PPScaleHelper } from "../../../utils/PPScaleHelper";
import { UserUtil } from "../../../utils/UserUtil";
import { PPUserGender } from "../../../enums/PPDeviceEnums";
import { OptimizedTextToBinary } from "../../../utils/ImageUtil";


export class PPUserInfoSyncCmd {
  static deviceModel?: PPDeviceModel | null = null;
  static syncUserInfoConfirmCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static syncUserInfoResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static delUserInfoConfirmCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static delUserInfoResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static confirmCurrentUserInfoConfirmCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static confirmCurrentUserInfoResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static monitorUserListResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  static monitorUserListCallBack?: (userIds: string[]) => void;
  static userModel: PPUserModel | null = null
  static deleteUserIdHex: Uint8Array = new Uint8Array(0)
  static currentUserUserIdHex: Uint8Array = new Uint8Array(0)

  static syncUserInfoStartCmd(userModel: PPUserModel, deviceModel: PPDeviceModel | null): Uint8Array {
    if (PPScaleHelper.isCalcute8(deviceModel?.deviceCalculateType)) {
      //8电极强行不支持运动员
      userModel.isAthleteMode = false;
    }
    PPUserInfoSyncCmd.userModel = userModel;
    PPLogger.d("syncUserInfo 开始同步用户信息");
    //050301D703
    return new Uint8Array([0x05, 0x03, 0x01, 0xD7, 0x03]);
  }

  static async syncUserInfoCmd(mtu: number): Promise<Uint8Array[]> {
    if (PPUserInfoSyncCmd.userModel) {
      const userDataHex = await PPUserInfoSyncCmd.getSyncUserInfoHex(PPUserInfoSyncCmd.userModel);
      const userDataBytes = ByteUtil.hexStringToUint8Array(userDataHex)
      if (userDataBytes && userDataBytes.length > 0) {
        return ByteUtil.splitByMTUWithLeadingZero(userDataBytes, mtu)
      }
    }
    return [];
  }

  static setUserInfoEndCmd(): Uint8Array {
    return new Uint8Array([0x05, 0x01, 0x02]);
  }

  static setUserSevenWeighInfoEnd(): Uint8Array {
    return new Uint8Array([0x0A, 0x01, 0x02]);
  }

  static deleteAllUserInfoStartCmd(userModel: PPUserModel): Uint8Array {

    PPLogger.d("deleteUserInfo userModel" + userModel.userID + "删除所有用户开始");

    const deleteUserIdHex: string = PPUserInfoSyncCmd.getDeleteUseridHex(userModel.memberID ?? "", "");

    const userID: Uint8Array = ByteUtil.hexStringToUint8Array(deleteUserIdHex);

    PPUserInfoSyncCmd.deleteUserIdHex = userID;

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0x05, 0x03, 0x03]);

    const lenHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(PPUserInfoSyncCmd.deleteUserIdHex.length, 2));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, lenHex]);
  }

  static deleteAllUserInfoDataCmd(mtu: number): Uint8Array[] {

    const uidHex = PPUserInfoSyncCmd.deleteUserIdHex;

    if (uidHex && uidHex.length > 0) {
      return ByteUtil.splitByMTUWithLeadingZero(uidHex, mtu)
    }
    return [];
  }

  static deleteAllUserInfoEndCmd() {
    return new Uint8Array([0x05, 0x01, 0x04]);
  }


  static sendCurrentUserinfoStartCmd(userModel: PPUserModel): Uint8Array {

    PPLogger.d("sendCurrentUserinfo userName" + userModel.userName + "用户开始");

    const userIdHex: string = PPUserInfoSyncCmd.getUseridHex(userModel.memberID ?? "", "");

    const userID: Uint8Array = ByteUtil.hexStringToUint8Array(userIdHex);

    PPUserInfoSyncCmd.currentUserUserIdHex = userID;

    // 命令头 0xF1
    const commandHeader = new Uint8Array([0x05, 0x03, 0x06]);

    const lenHex = ByteUtil.swapEndian(ByteUtil.numberToUint8Array(PPUserInfoSyncCmd.currentUserUserIdHex.length, 2));

    // 合并所有字节
    return ByteUtil.concatArrays([commandHeader, lenHex]);
  }

  static sendCurrentUserinfoDataCmd(mtu: number): Uint8Array[] {

    const uidHex = PPUserInfoSyncCmd.currentUserUserIdHex;

    if (uidHex && uidHex.length > 0) {
      return ByteUtil.splitByMTUWithLeadingZero(uidHex, mtu)
    }
    return [];
  }

  static sendCurrentUserinfoEndCmd() {
    return new Uint8Array([0x05, 0x01, 0x07]);
  }


  static getUserListCmd() {
    return new Uint8Array([0x05, 0x02, 0x05, 0x00]);
  }


  /**
   * 组装用户信息为16进制字符串
   * @param userModel 用户数据模型
   * @returns 16进制字符串
   */
  static async getSyncUserInfoHex(userModel: PPUserModel): Promise<string> {
    PPLogger.d("syncUserInfo 组装用户信息");
    PPLogger.d("syncUserInfo user = " + JSON.stringify(userModel));

    // 用户ID处理
    const userIdHex: string = PPUserInfoSyncCmd.getUseridHex(userModel.userID ?? "", userModel.memberID ?? "");
    PPLogger.v("syncUserInfo userIdHex = " + userIdHex);

    // 年龄处理
    const ageHex: string = ByteUtil.decimalToHex(userModel.age ?? 0);
    PPLogger.v("syncUserInfo ageHex = " + ageHex);

    // 性别处理
    const sexHex: string = ByteUtil.decimalToHex(UserUtil.getEnumSex(userModel.sex ?? PPUserGender.PPUserGenderFemale));
    PPLogger.v("syncUserInfo sexHex = " + sexHex);

    // 身高处理
    const heightHex: string = ByteUtil.hexToLittleEndianMode(ByteUtil.autoLeftPadZero(ByteUtil.decimalToHex(userModel.userHeight), 4));
    PPLogger.v("syncUserInfo heightHex = " + heightHex);

    // 运动员模式
    const athleteModeHex: string = userModel.isAthleteMode ? "01" : "00";
    PPLogger.v("syncUserInfo athleteModeHex = " + athleteModeHex);

    // 体重处理（保留两位小数）
    const weight: number = Math.floor((userModel.weightKg ?? 0.0 + 0.005) * 100);
    const weightHex: string = ByteUtil.hexToLittleEndianMode(ByteUtil.autoLeftPadZero(ByteUtil.decimalToHex(weight), 4));
    PPLogger.v("syncUserInfo weightHex = " + weightHex);

    // 头像索引
    const avatarHex: string = ByteUtil.decimalToHex(userModel.deviceHeaderIndex ?? 0);
    PPLogger.v("syncUserInfo avatarHex = " + avatarHex);

    // 目标体重
    const targetWeightHex: string = PPUserInfoSyncCmd.getTargetWeightHex(userModel.targetWeight ?? 0.0);
    PPLogger.v("syncUserInfo targetWeightHex = " + targetWeightHex);

    // 理想体重
    const ideaWeightHex: string = PPUserInfoSyncCmd.getTargetWeightHex(userModel.ideaWeight ?? 0.0);
    PPLogger.v("syncUserInfo ideaWeightHex = " + ideaWeightHex);

    // 处理近7天体重数据
    let userWeightArray = userModel.userWeightArray;
    let userWeightTimeArray = userModel.userWeightTimeArray;

    // 截取最近7条数据
    if (userWeightArray && userWeightArray.length > 7) {
      userWeightArray = userWeightArray.slice(-7);
    }
    if (userWeightTimeArray && userWeightTimeArray.length > 7) {
      userWeightTimeArray = userWeightTimeArray.slice(-7);
    }

    const dataLen: number = Math.min(userWeightArray?.length ?? 0, 7);
    const sevenDayDataNum: string = ByteUtil.decimalToHex(dataLen);
    PPLogger.v("syncUserInfo sevenDayDataNum = " + sevenDayDataNum);

    // 构建7天体重数据
    let sevenDayData: string = "";
    let sevenDayDataTimeHex: string = "";

    if (userWeightArray && dataLen > 0) {
      for (let i = 0; i < dataLen; i++) {
        const iWeight: number = Math.floor((userWeightArray[i] + 0.005) * 100);
        let time: number = userWeightTimeArray?.[i] ? Math.floor(userWeightTimeArray[i] / 1000) : Date.now();
        if (time < 0) {
          time = Date.now();
        }

        PPLogger.v(`syncUserInfo i:${i} iWeight:${iWeight} time:${time}`);

        sevenDayData += ByteUtil.hexToLittleEndianMode(ByteUtil.autoLeftPadZero(ByteUtil.decimalToHex(iWeight), 4));
        sevenDayDataTimeHex += ByteUtil.hexToLittleEndianMode(ByteUtil.autoLeftPadZero(ByteUtil.decimalToHex(time), 8));
      }
    }

    // 补全数据长度
    sevenDayData = ByteUtil.autoPadZeroStr(sevenDayData, 28);
    sevenDayDataTimeHex = ByteUtil.autoPadZeroStr(sevenDayDataTimeHex, 56);
    PPLogger.v("syncUserInfo sevenDayData = " + sevenDayData);
    PPLogger.v("syncUserInfo sevenDayDataTimeHex = " + sevenDayDataTimeHex);

    // 用户名处理
    let userNameHexStr: string = "";
    if (userModel.userName && userModel.userName.length > 0) {

      // 高性能转换示例
      const binaryMatrix = await OptimizedTextToBinary.convert("ABC123");
      OptimizedTextToBinary.printBinary(binaryMatrix);
      const userNameBinaryStr = OptimizedTextToBinary.flattenMatrix(binaryMatrix);

      // const userNameBinaryStr: string = ImageUtil.bitmapToBinary(userModel.userName);
      userNameHexStr = ByteUtil.binaryToHexString(userNameBinaryStr);

    }
    // 用户名补全到1600字符（800字节）
    const userNickName: string = ByteUtil.autoPadZeroStr(userNameHexStr, 1600);

    // 组合所有数据
    const userDataHex: string = userIdHex + ageHex + sexHex +
      heightHex + athleteModeHex +
      weightHex + avatarHex + targetWeightHex + ideaWeightHex +
      sevenDayDataNum + sevenDayData + sevenDayDataTimeHex + userNickName;

    PPLogger.d(`syncUserInfo 组装用户信息完成 len=${userDataHex.length / 2} userDataHex=${userDataHex}`);
    return userDataHex;

  }

  static getTargetWeightHex(targetWeight: number): string {
    const weight: number = Math.floor((targetWeight + 0.005) * 100);
    return ByteUtil.hexToLittleEndianMode(ByteUtil.autoLeftPadZero(ByteUtil.decimalToHex(weight), 4));
  }

  /**
   * 获取用户ID的16进制字符串
   * @param uid 用户ID
   * @param memberId 会员ID
   * @returns 拼接后的16进制字符串
   */
  static getUseridHex(uid: string | null, memberId: string | null): string {
    const userIdNormalLen = TorreHelper.userIdMormalLen;
    let uidHex: string;
    let memberHex: string;

    // 处理UID
    if (!uid || uid.length === 0) {
      uidHex = TorreHelper.normalMemberId;
    } else {
      const uidHexStr = ByteUtil.stringToHexString(uid);
      uidHex = ByteUtil.autoPadZeroStr(uidHexStr, userIdNormalLen * 2);
    }

    // 处理会员ID
    if (!memberId || memberId.length === 0) {
      memberHex = TorreHelper.normalMemberId;
    } else {
      const memberHexStr = ByteUtil.stringToHexString(memberId);
      memberHex = ByteUtil.autoPadZeroStr(memberHexStr, userIdNormalLen * 2);
    }

    PPLogger.v(`getUseridHex uidHex: ${uidHex}, memberHex: ${memberHex}`);
    return `${uidHex}${memberHex}`;
  }

  /**
   * 获取用户ID的16进制字符串
   * @param uid 用户ID
   * @param memberId 会员ID
   * @returns 拼接后的16进制字符串
   */
  static getDeleteUseridHex(uid: string | null, memberId: string | null): string {
    const userIdNormalLen = TorreHelper.userIdMormalLen;
    let uidHex: string;
    let memberHex: string;

    // 处理UID
    if (!uid || uid.length === 0) {
      uidHex = TorreHelper.normalDeleteUId;
    } else {
      const uidHexStr = ByteUtil.stringToHexString(uid);
      uidHex = ByteUtil.autoPadZeroStr(uidHexStr, userIdNormalLen * 2);
    }

    // 处理会员ID
    if (!memberId || memberId.length === 0) {
      memberHex = TorreHelper.deleteNormalMemberId;
    } else {
      const memberHexStr = ByteUtil.stringToHexString(memberId);
      memberHex = ByteUtil.autoPadZeroStr(memberHexStr, userIdNormalLen * 2);
    }

    PPLogger.v(`getDeleteUseridHex uidHex: ${uidHex}, memberHex: ${memberHex}`);
    return `${uidHex}${memberHex}`;
  }


  static processSyncUserInfo(receiveData: Uint8Array, cacheReceiveData: Uint8Array, deviceModel?: PPDeviceModel | null) {
    PPUserInfoSyncCmd.deviceModel = deviceModel;
    switch (receiveData[2]) {
      case 0x01: {
        if (receiveData[3] == 0x00) {
          PPLogger.d("syncUserInfo 开始用户信息确认成功");
          PPUserInfoSyncCmd.syncUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Ok);
        } else {
          PPLogger.e("syncUserInfo 开始用户信息确认失败");
          PPUserInfoSyncCmd.syncUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Unknown);
        }
        break;
      }
      case 0x02: {
        switch (receiveData[3]) {
          case 0x00: { //下发用户信息成功
            PPLogger.d("syncUserInfo 下发用户信息成功");
            PPUserInfoSyncCmd.syncUserInfoResultCallBack?.(PPBleFFF2ErrorCode.Ok);
            break;
          }
          case 0xFF: {
            PPLogger.e("syncUserInfo 数据总长度为0或接收长度与总长度不匹配");
            PPUserInfoSyncCmd.syncUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
          default: {
            PPLogger.e("syncUserInfo 下发用户信息失败");
            PPUserInfoSyncCmd.syncUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
        }
        break;
      }
      case 0x03: {
        switch (receiveData[3]) { //删除用户信息确认
          case 0x00: { //删除用户信息确认成功
            PPLogger.d("syncUserInfo 删除用户信息确认成功");
            PPUserInfoSyncCmd.delUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Ok);
            break;
          }
          default: {
            PPLogger.e("syncUserInfo 删除用户信息确认失败");
            PPUserInfoSyncCmd.delUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
        }
      }
      case 0x04: { //删除用户ID数据下发结束返回
        switch (receiveData[3]) { //获取用户信息
          case 0x00: { //删除用户信息成功
            PPLogger.d("syncUserInfo 删除用户信息成功");
            PPUserInfoSyncCmd.delUserInfoResultCallBack?.(PPBleFFF2ErrorCode.Ok);
            break;
          }
          default: {
            PPLogger.e("syncUserInfo 删除用户信息失败");
            PPUserInfoSyncCmd.delUserInfoResultCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
        }
      }
      case 0x05: { //获取用户信息
        PPUserInfoSyncCmd.receiveUserInfoListEnd(cacheReceiveData);
        PPUserInfoSyncCmd.monitorUserListResultCallBack?.(PPBleFFF2ErrorCode.Ok);
      }
      case 0x06: { //在线用户下发确认
        switch (receiveData[3]) { //获取用户信息
          case 0x00: { //删除用户信息成功
            PPLogger.d("currentUserResult 在线用户下发确认成功");
            PPUserInfoSyncCmd.confirmCurrentUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Ok);
            break;
          }
          default: {
            PPLogger.e("currentUserResult 在线用户下发确认失败");
            PPUserInfoSyncCmd.confirmCurrentUserInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
        }
      }
      case 0x07: { //在线用户下发结果
        switch (receiveData[3]) { //获取用户信息
          case 0x00: { //删除用户信息成功
            PPLogger.d("currentUserResult 在线用户下发结果成功");
            PPUserInfoSyncCmd.confirmCurrentUserInfoResultCallBack?.(PPBleFFF2ErrorCode.Ok);
            break;
          }
          case 0x01: {
            PPLogger.e("currentUserResult 参数错误");
            PPUserInfoSyncCmd.confirmCurrentUserInfoResultCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
          default: {
            PPLogger.e("currentUserResult 在线用户下发结果失败");
            PPUserInfoSyncCmd.confirmCurrentUserInfoResultCallBack?.(PPBleFFF2ErrorCode.Unknown);
          }
        }
      }

    }
  }

  static receiveUserInfoListEnd(cacheReceiveData: Uint8Array) {

    const suUserNum = cacheReceiveData[0]
    PPLogger.d("获取已存储用户ID 用户数 subuser Num = " + suUserNum);

    const subString1 = cacheReceiveData.subarray(1)

    const userIdLen = TorreHelper.userIdMormalLen;

    const num = subString1.length / userIdLen;

    const userIds: string[] = [];

    for (let i = 0; i < num; i++) {
      const subString2 = subString1.subarray(i * userIdLen, (i + 1) * userIdLen);
      const userId = ByteUtil.bufferToAscii(subString2);
      PPLogger.d("获取已存储用户ID 用户ID = " + userId);
      userIds.push(userId);
    }

    PPUserInfoSyncCmd.monitorUserListCallBack?.(userIds);
  }
}