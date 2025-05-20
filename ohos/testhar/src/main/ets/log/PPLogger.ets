// Logger.ets
import hilog from '@ohos.hilog';
import { PPLoggerListener } from './PPLoggerListener';

export class PPLogger {
  private static listener: PPLoggerListener | null = null;
  private static tag: string = "PPScale"
  private static debug = true

  public static addListener(listener: PPLoggerListener): void {
    PPLogger.listener = listener;
  }

  public static setDebug(debug: boolean) {
    PPLogger.debug = debug;
  }

  public static cancleListener(): void {
    PPLogger.listener = null;
  }

  public static d(msg: string): void {
    PPLogger.listener?.d?.(msg);
    if (PPLogger.debug) {
      hilog.debug(0x0000, PPLogger.tag, "%{public}s", msg);
    }
  }

  public static e(msg: string): void {
    PPLogger.listener?.e?.(msg);
    hilog.error(0x0000, PPLogger.tag, "%{public}s", msg);
  }

  public static i(msg: string): void {
    PPLogger.listener?.i?.(msg);
    if (PPLogger.debug) {
      hilog.info(0x0000, PPLogger.tag, "%{public}s", msg);
    }
  }

  public static w(msg: string): void {
    PPLogger.listener?.w?.(msg);
    hilog.warn(0x0000, PPLogger.tag, "%{public}s", msg);
  }

  public static v(msg: string): void {
    PPLogger.listener?.d?.(msg);
    if (PPLogger.debug) {
      hilog.debug(0x0000, PPLogger.tag, "%{public}s", msg);
    }
  }
}

