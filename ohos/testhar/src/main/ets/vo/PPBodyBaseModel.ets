import { PPScaleState } from "../enums/PPScaleState";
import { PPUnitType } from "../enums/PPUnitType";
import { PPDeviceModel } from "./PPDeviceModel";
import { PPUserModel } from "./PPUserModel";

/**
 * 身体基础数据JSON接口
 */
export interface PPBodyBaseModelJson {
  weight: number;
  impedance: number;
  zTwoLegsDeCode: number;
  ppImpedance100EnCode: number;
  ppImpedance100DeCode: number;
  isHeartRating: boolean;
  heartRate: number;
  footLen: number;
  isOverload: boolean;
  isPlus: boolean;
  measureTime: number;
  memberId: string;
  z100KhzLeftArmEnCode: number;
  z100KhzLeftLegEnCode: number;
  z100KhzRightArmEnCode: number;
  z100KhzRightLegEnCode: number;
  z100KhzTrunkEnCode: number;
  z20KhzLeftArmEnCode: number;
  z20KhzLeftLegEnCode: number;
  z20KhzRightArmEnCode: number;
  z20KhzRightLegEnCode: number;
  z20KhzTrunkEnCode: number;
  z100KhzLeftArmDeCode: number;
  z100KhzLeftLegDeCode: number;
  z100KhzRightArmDeCode: number;
  z100KhzRightLegDeCode: number;
  z100KhzTrunkDeCode: number;
  z20KhzLeftArmDeCode: number;
  z20KhzLeftLegDeCode: number;
  z20KhzRightArmDeCode: number;
  z20KhzRightLegDeCode: number;
  z20KhzTrunkDeCode: number;
  deviceModel?: PPDeviceModel;
  userModel?: PPUserModel;
  unit?: PPUnitType;
  scaleState?: PPScaleState;
}

/**
 * 严格按照DeviceConfigVo格式重构的身体基础数据模型
 */
export class PPBodyBaseModel {
  // 所有属性都改为可选
  public weight: number = 0;
  public impedance: number = 0;
  public zTwoLegsDeCode: number = 0;
  public ppImpedance100EnCode: number = 0;
  public ppImpedance100DeCode: number = 0;
  public heartRate: number = 0;
  public measureTime: number = 0;
  public z100KhzLeftArmEnCode: number = 0;
  public z100KhzLeftLegEnCode: number = 0;
  public z100KhzRightArmEnCode: number = 0;
  public z100KhzRightLegEnCode: number = 0;
  public z100KhzTrunkEnCode: number = 0;
  public z20KhzLeftArmEnCode: number = 0;
  public z20KhzLeftLegEnCode: number = 0;
  public z20KhzRightArmEnCode: number = 0;
  public z20KhzRightLegEnCode: number = 0;
  public z20KhzTrunkEnCode: number = 0;
  public z100KhzLeftArmDeCode: number = 0;
  public z100KhzLeftLegDeCode: number = 0;
  public z100KhzRightArmDeCode: number = 0;
  public z100KhzRightLegDeCode: number = 0;
  public z100KhzTrunkDeCode: number = 0;
  public z20KhzLeftArmDeCode: number = 0;
  public z20KhzLeftLegDeCode: number = 0;
  public z20KhzRightArmDeCode: number = 0;
  public z20KhzRightLegDeCode: number = 0;
  public z20KhzTrunkDeCode: number = 0;
  // String properties default to empty string
  public memberId: string = '';
  // Boolean properties default to false
  public isHeartRating: boolean = false;
  public isOverload: boolean = false;
  public isPlus: boolean = false;
  // Complex types default to null
  public deviceModel?: PPDeviceModel;
  public userModel?: PPUserModel;
  public unit?: PPUnitType;
  public scaleState?: PPScaleState | null;
  public footLen: number = 0

  /**
   * 从JSON创建身体数据模型（完全按照DeviceConfigVo格式）
   */
  public fromJson(json: PPBodyBaseModelJson): PPBodyBaseModel {
    const model = new PPBodyBaseModel();
    model.weight = json.weight;
    model.impedance = json.impedance;
    model.zTwoLegsDeCode = json.zTwoLegsDeCode;
    model.ppImpedance100EnCode = json.ppImpedance100EnCode;
    model.ppImpedance100DeCode = json.ppImpedance100DeCode;
    model.isHeartRating = json.isHeartRating;
    model.heartRate = json.heartRate;
    model.footLen = json.footLen;
    model.isOverload = json.isOverload;
    model.isPlus = json.isPlus;
    model.measureTime = json.measureTime;
    model.memberId = json.memberId;
    model.z100KhzLeftArmEnCode = json.z100KhzLeftArmEnCode;
    model.z100KhzLeftLegEnCode = json.z100KhzLeftLegEnCode;
    model.z100KhzRightArmEnCode = json.z100KhzRightArmEnCode;
    model.z100KhzRightLegEnCode = json.z100KhzRightLegEnCode;
    model.z100KhzTrunkEnCode = json.z100KhzTrunkEnCode;
    model.z20KhzLeftArmEnCode = json.z20KhzLeftArmEnCode;
    model.z20KhzLeftLegEnCode = json.z20KhzLeftLegEnCode;
    model.z20KhzRightArmEnCode = json.z20KhzRightArmEnCode;
    model.z20KhzRightLegEnCode = json.z20KhzRightLegEnCode;
    model.z20KhzTrunkEnCode = json.z20KhzTrunkEnCode;
    model.z100KhzLeftArmDeCode = json.z100KhzLeftArmDeCode;
    model.z100KhzLeftLegDeCode = json.z100KhzLeftLegDeCode;
    model.z100KhzRightArmDeCode = json.z100KhzRightArmDeCode;
    model.z100KhzRightLegDeCode = json.z100KhzRightLegDeCode;
    model.z100KhzTrunkDeCode = json.z100KhzTrunkDeCode;
    model.z20KhzLeftArmDeCode = json.z20KhzLeftArmDeCode;
    model.z20KhzLeftLegDeCode = json.z20KhzLeftLegDeCode;
    model.z20KhzRightArmDeCode = json.z20KhzRightArmDeCode;
    model.z20KhzRightLegDeCode = json.z20KhzRightLegDeCode;
    model.z20KhzTrunkDeCode = json.z20KhzTrunkDeCode;
    return model;
  }

  /**
   * 转换为JSON对象（完全按照DeviceConfigVo格式）
   */
  public toJson(): PPBodyBaseModelJson {
    return {
      weight: this.weight,
      impedance: this.impedance,
      zTwoLegsDeCode: this.zTwoLegsDeCode,
      ppImpedance100EnCode: this.ppImpedance100EnCode,
      ppImpedance100DeCode: this.ppImpedance100DeCode,
      isHeartRating: this.isHeartRating,
      heartRate: this.heartRate,
      footLen: this.footLen,
      isOverload: this.isOverload,
      isPlus: this.isPlus,
      measureTime: this.measureTime,
      memberId: this.memberId,
      z100KhzLeftArmEnCode: this.z100KhzLeftArmEnCode,
      z100KhzLeftLegEnCode: this.z100KhzLeftLegEnCode,
      z100KhzRightArmEnCode: this.z100KhzRightArmEnCode,
      z100KhzRightLegEnCode: this.z100KhzRightLegEnCode,
      z100KhzTrunkEnCode: this.z100KhzTrunkEnCode,
      z20KhzLeftArmEnCode: this.z20KhzLeftArmEnCode,
      z20KhzLeftLegEnCode: this.z20KhzLeftLegEnCode,
      z20KhzRightArmEnCode: this.z20KhzRightArmEnCode,
      z20KhzRightLegEnCode: this.z20KhzRightLegEnCode,
      z20KhzTrunkEnCode: this.z20KhzTrunkEnCode,
      z100KhzLeftArmDeCode: this.z100KhzLeftArmDeCode,
      z100KhzLeftLegDeCode: this.z100KhzLeftLegDeCode,
      z100KhzRightArmDeCode: this.z100KhzRightArmDeCode,
      z100KhzRightLegDeCode: this.z100KhzRightLegDeCode,
      z100KhzTrunkDeCode: this.z100KhzTrunkDeCode,
      z20KhzLeftArmDeCode: this.z20KhzLeftArmDeCode,
      z20KhzLeftLegDeCode: this.z20KhzLeftLegDeCode,
      z20KhzRightArmDeCode: this.z20KhzRightArmDeCode,
      z20KhzRightLegDeCode: this.z20KhzRightLegDeCode,
      z20KhzTrunkDeCode: this.z20KhzTrunkDeCode,
      deviceModel: this.deviceModel, // 添加缺失的属性
      userModel: this.userModel, // 添加缺失的属性
      unit: this.unit                // 添加缺失的属性
    };
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return JSON.stringify(this.toJson());
  }

  /**
   * 获取体重(kg) - 作为工具函数而不是类方法
   */
  public getPpWeightKg(): number {
    return this.weight ? this.weight / 100.0 : 0.0;
  }

  /**
   * 重置体脂数据 - 作为工具函数而不是类方法
   */
  public static resetBodyFat(model: PPBodyBaseModel): void {
    model.scaleState = new PPScaleState();
    model.z20KhzRightArmEnCode = 0;
    model.z100KhzRightArmEnCode = 0;
    model.z20KhzLeftArmEnCode = 0;
    model.z100KhzLeftArmEnCode = 0;
    model.z20KhzTrunkEnCode = 0;
    model.z100KhzTrunkEnCode = 0;
    model.z20KhzRightLegEnCode = 0;
    model.z100KhzRightLegEnCode = 0;
    model.z20KhzLeftLegEnCode = 0;
    model.z100KhzLeftLegEnCode = 0;
    model.impedance = 0;
    model.ppImpedance100EnCode = 0;
    model.heartRate = 0;
    model.footLen = 0;
    model.zTwoLegsDeCode = 0.0;
    model.z100KhzLeftArmDeCode = 0.0;
    model.z100KhzLeftLegDeCode = 0.0;
    model.z100KhzRightArmDeCode = 0.0;
    model.z100KhzRightLegDeCode = 0.0;
    model.z100KhzTrunkDeCode = 0.0;
    model.z20KhzLeftArmDeCode = 0.0;
    model.z20KhzLeftLegDeCode = 0.0;
    model.z20KhzRightArmDeCode = 0.0;
    model.z20KhzRightLegDeCode = 0.0;
    model.z20KhzTrunkDeCode = 0.0;
    model.isHeartRating = false;
    model.isOverload = false;
    model.isPlus = false;
    model.measureTime = 0;
    model.memberId = "";
    model.ppImpedance100DeCode = 0.0;
    model.z100KhzLeftArmEnCode = 0;

  }
}
