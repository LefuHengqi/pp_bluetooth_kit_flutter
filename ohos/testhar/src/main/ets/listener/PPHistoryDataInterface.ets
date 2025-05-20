// pp_history_data_interface.ets
import { PPBodyBaseModel } from "../vo/PPBodyBaseModel";

/**
 * @author liyp
 * @email liyp520@foxmail.com
 * @date 2025/2/12 09:31
 * @description 历史数据监听接口
 */
export interface PPHistoryDataInterface {
  // 监控历史数据
  monitorHistoryData?: (bodyBaseModel: PPBodyBaseModel | null) => void;

  // 监控历史结束
  monitorHistoryEnd?: () => void;

  // 监控历史失败
  monitorHistoryFail?: () => void;

  // 历史数据变化
  onHistoryChange?: () => void;


}