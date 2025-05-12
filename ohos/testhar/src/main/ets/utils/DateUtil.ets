// date_util.ets
import { BusinessError } from '@ohos.base';

export class DateUtil {
  /**
   * 检查当前是否处于夏令时
   */
  static isDaylightSavingTime(): boolean {
    try {
      // 获取当前时间
      const now = new Date();

      // 获取标准时间（不考虑夏令时）
      const standardTime = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate(),
        now.getHours(),
        now.getMinutes(),
        now.getSeconds(),
        now.getMilliseconds()
      );

      // 获取标准时间和当前时间的时区偏移量（分钟）
      const standardOffset = -standardTime.getTimezoneOffset();
      const currentOffset = -now.getTimezoneOffset();

      // 如果偏移量不同则处于夏令时
      return currentOffset !== standardOffset;
    } catch (err) {
      return false;
    }
  }

  /**
   * 获取当前时区与UTC的小时偏移量
   */
  static getUtcOffsetInHours(): number {
    try {
      // 获取时区偏移（分钟）并转换为小时
      return -new Date().getTimezoneOffset() / 60;
    } catch (err) {
      return 0;
    }
  }

  /**
   * 格式化时间戳为 YYYY-MM-DD HH:MM:SS
   * @param timestamp 毫秒时间戳
   */
  static timestampToYYYYMMDDHHMMSS(timestamp: number): string {
    try {
      const date = new Date(timestamp);

      const year = date.getFullYear();
      const month = (date.getMonth() + 1).toString().padStart(2, '0');
      const day = date.getDate().toString().padStart(2, '0');
      const hours = date.getHours().toString().padStart(2, '0');
      const minutes = date.getMinutes().toString().padStart(2, '0');
      const seconds = date.getSeconds().toString().padStart(2, '0');

      return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
    } catch (err) {
      return '';
    }
  }
}