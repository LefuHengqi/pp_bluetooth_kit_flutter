// pp_ota_state_listener.ets
/**
 * @author liyp
 * @email liyp520@foxmail.com
 * @date 2025/2/22 13:52
 * @description OTA状态监听器
 */
export class OnOTAStateListener {
  /**
   * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
   */
  onUpdateFail?: (errorCode: number) => void;

  // 开始更新回调
  onStartUpdate?: () => void;

  // 更新进度回调
  onUpdateProgress?: (progress: number) => void;

  // 更新成功回调
  onUpdateSuccess?: () => void;

  // 准备更新回调
  onReadyToUpdate?: () => void;

  // 更新结束回调
  onUpdateEnd?: () => void;


}