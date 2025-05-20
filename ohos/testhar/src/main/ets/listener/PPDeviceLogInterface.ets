/**
 * 设备日志接口 (PPDeviceLogInterface)
 * 用于处理设备日志同步的生命周期
 */
export interface PPDeviceLogInterface {
  /**
   * 开始同步日志
   */
  syncLogStart(): void;

  /**
   * 日志同步进度更新
   * @param progress 当前进度 (0-100)
   */
  syncLoging(progress: number): void;

  /**
   * 完成日志同步
   * @param logFilePath 生成的日志文件路径
   */
  syncLogEnd(logFilePath: string): void;
}