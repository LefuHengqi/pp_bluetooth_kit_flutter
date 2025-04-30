// Logger.ets
import hilog from '@ohos.hilog';
import { PPLoggerListener } from 'ppsdkkit/src/main/ets/log/PPLogger';

export class PPLoggerPluginOhos {
  private static listener: PPLoggerListener | null = null;
  private static tag: string = "PPLoggerPluginOhos"
  private static debug = true

  public addListener(listener: PPLoggerListener): void {
    PPLoggerPluginOhos.listener = listener;
  }

  public static setDebug(debug: boolean) {
    PPLoggerPluginOhos.debug = debug;
  }

  public static cancleListener(): void {
    PPLoggerPluginOhos.listener = null;
  }

  public static d(msg: string): void {
    PPLoggerPluginOhos.listener?.d(msg);
    if (PPLoggerPluginOhos.debug) {
      hilog.debug(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
    }
  }

  public static e(msg: string): void {
    PPLoggerPluginOhos.listener?.e(msg);
    hilog.error(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
  }

  public static i(msg: string): void {
    PPLoggerPluginOhos.listener?.i(msg);
    if (PPLoggerPluginOhos.debug) {
      hilog.info(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
    }
  }

  public static w(msg: string): void {
    PPLoggerPluginOhos.listener?.w(msg);
    hilog.warn(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
  }

  public static v(msg: string): void {
    PPLoggerPluginOhos.listener?.d(msg);
    if (PPLoggerPluginOhos.debug) {
      hilog.debug(0x0000, PPLoggerPluginOhos.tag, "%{public}s", msg);
    }
  }
}