import { PPUserGender } from "../enums/PPDeviceEnums";

/**
 * 用户数据JSON接口
 */
export interface PPUserModelJson {
  userHeight: number | 0.0;
  age?: number;
  sex?: number; // 0: Female, 1: Male
  groupNum?: number;
  isAthleteMode?: boolean;
  isPregnantMode?: boolean;
  userID?: string;
  memberID?: string;
  userName?: string;
  deviceHeaderIndex?: number;
  weightKg?: number;
  targetWeight?: number;
  ideaWeight?: number;
  userWeightArray?: number[];
  userWeightTimeArray?: number[];
  PIndex?: number;
  bmi?: number;
  bodyfat?: number;
  heartRate?: number;
  muscleRate?: number;
  muscle?: number;
  bone?: number;
  boneRate?: number;
  waterRate?: number;
}

/**
 * 严格按照DeviceConfigVo格式优化的用户数据模型类
 */
export class PPUserModel {
  // 所有属性都改为可选，与DeviceConfigVo保持一致
  public userHeight: number | 0.0 = 0.0;
  public age?: number;
  public sex?: PPUserGender;
  public groupNum?: number;
  //运动员模式
  public isAthleteMode?: boolean;
  //孕妇模式
  public isPregnantMode?: boolean;
  public userID?: string;
  public memberID?: string;
  public userName?: string;
  public deviceHeaderIndex?: number;
  public weightKg?: number;
  public targetWeight?: number;
  public ideaWeight?: number;
  public userWeightArray?: number[];
  public userWeightTimeArray?: number[];
  public PIndex?: number;
  public bmi?: number;
  public bodyfat?: number;
  public heartRate?: number;
  public muscleRate?: number;
  public muscle?: number;
  public bone?: number;
  public boneRate?: number;
  public waterRate?: number;

  /**
   * 从JSON创建用户模型（完全按照DeviceConfigVo格式）
   */
  public static fromJson(json: PPUserModelJson): PPUserModel {
    const model = new PPUserModel();
    model.userHeight = json.userHeight;
    model.age = json.age;
    model.sex = json.sex === 1 ? PPUserGender.PPUserGenderMale : PPUserGender.PPUserGenderFemale;
    model.groupNum = json.groupNum;
    model.isAthleteMode = json.isAthleteMode;
    model.isPregnantMode = json.isPregnantMode;
    model.userID = json.userID;
    model.memberID = json.memberID;
    model.userName = json.userName;
    model.deviceHeaderIndex = json.deviceHeaderIndex;
    model.weightKg = json.weightKg;
    model.targetWeight = json.targetWeight;
    model.ideaWeight = json.ideaWeight;
    model.userWeightArray = json.userWeightArray;
    model.userWeightTimeArray = json.userWeightTimeArray;
    model.PIndex = json.PIndex;
    model.bmi = json.bmi;
    model.bodyfat = json.bodyfat;
    model.heartRate = json.heartRate;
    model.muscleRate = json.muscleRate;
    model.muscle = json.muscle;
    model.bone = json.bone;
    model.boneRate = json.boneRate;
    model.waterRate = json.waterRate;
    return model;
  }

  /**
   * 转换为JSON对象（完全按照DeviceConfigVo格式）
   */
  public toJson(): PPUserModelJson {
    return {
      userHeight: this.userHeight,
      age: this.age,
      sex: this.sex === PPUserGender.PPUserGenderMale ? 1 : 0,
      groupNum: this.groupNum,
      isAthleteMode: this.isAthleteMode,
      isPregnantMode: this.isPregnantMode,
      userID: this.userID,
      memberID: this.memberID,
      userName: this.userName,
      deviceHeaderIndex: this.deviceHeaderIndex,
      weightKg: this.weightKg,
      targetWeight: this.targetWeight,
      ideaWeight: this.ideaWeight,
      userWeightArray: this.userWeightArray,
      userWeightTimeArray: this.userWeightTimeArray,
      PIndex: this.PIndex,
      bmi: this.bmi,
      bodyfat: this.bodyfat,
      heartRate: this.heartRate,
      muscleRate: this.muscleRate,
      muscle: this.muscle,
      bone: this.bone,
      boneRate: this.boneRate,
      waterRate: this.waterRate
    };
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return JSON.stringify(this.toJson());
  }
}