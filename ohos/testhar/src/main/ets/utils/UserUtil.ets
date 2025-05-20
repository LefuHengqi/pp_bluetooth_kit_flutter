// user-util.ets
import { PPUserGender } from "../enums/PPDeviceEnums";


export class UserUtil {
  /**
   * 获取性别枚举对应的数值
   * @param enumSex 性别枚举
   * @returns 性别数值（1=男，0=女）
   */
  static getEnumSex(enumSex: PPUserGender): number {
    switch (enumSex) {
      case PPUserGender.PPUserGenderMale:
        return 1;
      case PPUserGender.PPUserGenderFemale:
        return 0;
      default:
        return 0; // 默认返回女性
    }
  }

  /**
   * 获取数值对应的性别枚举
   * @param sex 性别数值（1=男，0=女）
   * @returns 性别枚举
   */
  static getEnumSexType(sex: number): PPUserGender {
    return sex === 1
      ? PPUserGender.PPUserGenderMale
      : PPUserGender.PPUserGenderFemale;
  }
}