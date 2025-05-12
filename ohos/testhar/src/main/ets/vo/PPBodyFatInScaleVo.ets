// pp_body_fat_inscale_vo.ets
import { PPBodyBaseModel } from "./PPBodyBaseModel";

/**
 * @author liyp
 * @email liyp520@foxmail.com
 * @date 2025/2/6 16:02
 * @description 秤端计算的体脂数据模型
 */
export class PPBodyFatInScaleVo {
  // 用于存储计算所必须的参数
  ppBodyBaseModel: PPBodyBaseModel | null = null;

  // Body Mass Index
  ppBMI: number = 0.0;

  // 脂肪率(%)
  ppFat: number = 0.0;

  // 骨量(kg)
  ppBoneKg: number = 0.0;

  // 肌肉量(kg)
  ppMuscleKg: number = 0.0;

  // 内脏脂肪等级
  ppVisceralFat: number = 0;

  // 水分率(%), 分辨率0.1
  ppWaterPercentage: number = 0.0;

  // 基础代谢
  ppBMR: number = 0;

  // 计算库版本号
  ppSDKVersion: string | null = null;

  // 身体年龄
  ppBodyAge: number = 0;


}