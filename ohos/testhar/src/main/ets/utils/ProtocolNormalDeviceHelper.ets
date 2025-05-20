import { PPDeviceCalculateType } from '../enums/PPDeviceEnums';
import { PPUnitType } from '../enums/PPUnitType';
import { PPLogger } from '../log/PPLogger';
import { PPBodyBaseModel } from '../vo/PPBodyBaseModel';
import { PPBodyFatInScaleVo } from '../vo/PPBodyFatInScaleVo';
import { PPDeviceModel } from '../vo/PPDeviceModel';
import { PPUserModel } from '../vo/PPUserModel';
import { LF_X_L_16, LF_X_L_17, LF_X_L_20 } from './Constants';
import { UnitUtil } from './UnitUtil';

export class ProtocolNormalDeviceHelper {
  // 获取体重（千克）
  static getWeightKg(data: Uint8Array): number {
    const weight = ProtocolNormalDeviceHelper.getWeightG(data);
    return weight / 100.0;
  }

  // 获取体重（克）
  static getWeightG(data: Uint8Array): number {
    // Check minimum length (original 10 chars = 5 bytes)
    if (data.length < 5) {
      return 0;
    }
    // Combine bytes in little-endian order (low + high)
    return (data[4] << 8) | data[3];
  }

  // 获取阻抗
  static getImpedance(data: Uint8Array): number {
    try {
      // Check minimum length (original 16 chars = 8 bytes)
      if (data.length < 8) {
        return 0;
      }

      // Combine bytes in little-endian order (low + mid + high)
      return (data[7] << 16) | (data[6] << 8) | data[5];
    } catch (e) {
      PPLogger.e(e.toString());
      return 0;
    }
  }

  // 获取直接阻抗类型
  static getImpedanceTypeDirect(data: Uint8Array): number {
    try {
      // Check minimum length (original 24 chars = 12 bytes)
      if (data.length < 12) {
        return 0;
      }

      // Combine bytes in little-endian order (low + high)
      return (data[11] << 8) | data[10];
    } catch (e) {
      PPLogger.e(e.toString());
      return 0;
    }
  }

  // 获取V4时钟
  static getV4Clock(data: Uint8Array, startIndex: number): number {
    // 原14字符=7字节，所以检查startIndex + 7
    if (data.length < startIndex + 7) {
      return 0;
    }

    // 解析日期时间各部分（大端序）
    const year = (data[startIndex] << 8) | data[startIndex + 1];
    const month = data[startIndex + 2];
    const day = data[startIndex + 3];
    const hour = data[startIndex + 4];
    const minute = data[startIndex + 5];
    const second = data[startIndex + 6];

    // 构建日期字符串并转换为时间戳
    const dateStr = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')} ` +
      `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}:${second.toString().padStart(2, '0')}`;

    PPLogger.d(`时间转换前：clock：${dateStr}`);
    return new Date(dateStr).getTime();
  }

  // 获取时钟
  static getClock(data: Uint8Array, deviceModel: PPDeviceModel | null): number {
    // 原36字符=18字节，检查长度18
    if (data.length < 18) {
      return 0;
    }

    // 解析日期时间各部分（大端序）
    const year = (data[11] << 8) | data[12]; // 原22-26→字节11-13
    const month = data[13]; // 原26-28→字节13
    const day = data[14]; // 原28-30→字节14
    const hour = data[15]; // 原30-32→字节15
    const minute = data[16]; // 原32-34→字节16
    const second = data[17]; // 原34-36→字节17

    // 构建日期字符串并转换为时间戳
    const dateStr = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')} ` +
      `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}:${second.toString().padStart(2, '0')}`;

    PPLogger.d(`时间转换前：clock：${dateStr}`);
    return new Date(dateStr).getTime();
  }

  // 获取单位类型
  static getPpUnitType(data: Uint8Array, deviceModel: PPDeviceModel | null): PPUnitType {
    if (data.length < 9) {
      return PPUnitType.Unit_KG;
    } // Default return
    // Original substring(16,18) → byte 8
    const scaleUnit = data[8];

    const deviceName = deviceModel?.deviceName ?? "";
    return UnitUtil.getUnitType(scaleUnit, deviceName);
  }

  // 计算体脂模型
  static getCalculateInScaleBodyFatModel(data: Uint8Array, userModel: PPUserModel,
    deviceModel: PPDeviceModel): PPBodyFatInScaleVo | null {
    // 原16进制字符串长度64（32字节）→ Uint8Array长度32
    if (data.length < 32) {
      return null;
    }

    // 获取体重（原substring(8,12)→字节4-6）
    const weightKg = ((data[5] << 8) | data[4]) / 10.0;
    if (weightKg <= 0) {
      return null;
    }

    // 计算BMI
    const bmi = weightKg / Math.pow(userModel.userHeight / 100.0, 2.0);

    // 解析各项体脂数据（调整所有索引为字节位置）
    const bodyfatPercentage = ((data[7] << 8) | data[6]) / 10.0; // 12-16→6-8
    const boneKg = data[8] / 10.0; // 16-18→8
    const muscleKg = ((data[9] << 8) | data[8]) / 10.0; // 18-22→9-11
    const VFL = data[10]; // 22-24→11
    const waterPercentage = ((data[11] << 8) | data[10]) / 10.0; // 24-28→12-14
    const BMR = (data[12] << 8) | data[11]; // 28-32→14-16

    // 获取阻抗（如果存在）（原substring(32,38)→字节16-19）
    let impedance = 0;
    if (data.length >= 38 && deviceModel.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeInScale) {
      impedance = (data[19] << 16) | (data[18] << 8) | data[17];
    }

    // 构建基础模型
    const bodyBaseModel = new PPBodyBaseModel();
    bodyBaseModel.weight = weightKg * 100;
    bodyBaseModel.impedance = impedance;
    bodyBaseModel.userModel = userModel;
    bodyBaseModel.deviceModel = deviceModel;
    bodyBaseModel.unit = PPUnitType.Unit_KG;

    // 构建体脂模型
    const bodyFatModel = new PPBodyFatInScaleVo();
    bodyFatModel.ppBodyBaseModel = bodyBaseModel;
    bodyFatModel.ppBMI = bmi;
    bodyFatModel.ppFat = bodyfatPercentage;
    bodyFatModel.ppBoneKg = boneKg;
    bodyFatModel.ppMuscleKg = muscleKg;
    bodyFatModel.ppVisceralFat = VFL;
    bodyFatModel.ppWaterPercentage = waterPercentage;
    bodyFatModel.ppBMR = BMR;
    bodyFatModel.ppSDKVersion = impedance > 0 ? LF_X_L_20 : LF_X_L_16;

    PPLogger.d("liyp_ " + bodyFatModel.toString());
    return bodyFatModel;
  }

  // 获取17体脂模型
  static get17BodyFatModel(data: Uint8Array, userModel: PPUserModel,
    deviceModel: PPDeviceModel): PPBodyFatInScaleVo | null {
    // 原16进制字符串长度68（34字节）→ Uint8Array长度34
    if (data.length < 34) {
      return null;
    }

    // 获取体重（原substring(8,12)→字节4-6）
    const weightKg = ((data[5] << 8) | data[4]) / 10.0;
    if (weightKg <= 0) {
      return null;
    }

    // 计算BMI
    const bmi = weightKg / Math.pow(userModel.userHeight / 100.0, 2.0);

    // 解析各项体脂数据（所有索引已转换为字节位置）
    const bodyfatPercentage = ((data[7] << 8) | data[6]) / 10.0; // 12-16→6-8
    const boneKg = data[8] / 10.0; // 16-18→8
    const muscleKg = ((data[9] << 8) | data[8]) / 10.0; // 18-22→9-11
    const VFL = data[10]; // 22-24→11
    const waterPercentage = ((data[11] << 8) | data[10]) / 10.0; // 24-28→12-14
    const BMR = (data[12] << 8) | data[11]; // 28-32→14-16
    const bodyAge = data[13]; // 32-34→16-17

    // 构建基础模型
    const bodyBaseModel = new PPBodyBaseModel();
    bodyBaseModel.weight = weightKg * 100;
    bodyBaseModel.impedance = 0;
    bodyBaseModel.userModel = userModel;
    bodyBaseModel.deviceModel = deviceModel;
    bodyBaseModel.unit = PPUnitType.Unit_KG;

    // 构建体脂模型
    const bodyFatModel = new PPBodyFatInScaleVo();
    bodyFatModel.ppBodyBaseModel = bodyBaseModel;
    bodyFatModel.ppBMI = bmi;
    bodyFatModel.ppFat = bodyfatPercentage;
    bodyFatModel.ppBoneKg = boneKg;
    bodyFatModel.ppMuscleKg = muscleKg;
    bodyFatModel.ppVisceralFat = VFL;
    bodyFatModel.ppWaterPercentage = waterPercentage;
    bodyFatModel.ppBMR = BMR;
    bodyFatModel.ppBodyAge = bodyAge;
    bodyFatModel.ppSDKVersion = LF_X_L_17;

    PPLogger.d("liyp_ " + bodyFatModel.toString());
    return bodyFatModel;
  }
}