// pp_data_change_listener.ets
import { PPScaleFootState, PPScaleState } from "../enums/PPScaleState";
import { PPBodyBaseModel } from "../vo/PPBodyBaseModel";
import { PPBodyFatInScaleVo } from "../vo/PPBodyFatInScaleVo";
import { PPDeviceModel } from "../vo/PPDeviceModel";


/**
 * @author liyp
 * @email liyp520@foxmail.com
 * @date 2025/2/6 15:57
 * @description 体重秤数据变化监听器
 */
export class PPDataChangeListener {
  // 监听过程数据
  monitorProcessData?: (bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) => void;
  // 锁定数据
  monitorLockData?: (bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) => void;
  // 秤状态
  monitorScaleState?: (scaleState: PPScaleState | null) => void;
  // 脚长测量状态
  monitorFootLenMeasure?: (scaleState: PPScaleFootState | null, footLen: number) => void;
  // 测量失败
  monitorDataFail?: (bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) => void;
  // 阻抗测量状态
  onImpedanceFatting?: () => void;
  // 秤端计算的数据
  monitorLockDataByCalculateInScale?: (bodyFatModel: PPBodyFatInScaleVo | null) => void;
  // 超重
  monitorOverWeight?: () => void;
  // 设备关机回调
  onDeviceShutdown?: () => void;
}