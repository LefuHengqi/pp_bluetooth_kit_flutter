// pp_log_sync_cmd.ets
import util from '@ohos.util';
import { PPBleFFF2ErrorCode } from '../../../enums/PPBleFFF2ErrorCode';
import { PPLogger } from '../../../log/PPLogger';
import { BleLoggerManager } from '../../../utils/BleLoggerManager';
import { ByteUtil } from '../../../utils/ByteUtil';

export class PPLogSyncCmd {
  private static logLength: number = 0;
  private static logStartIndex: number = 0;
  private static logIndex: number = 0;
  static loggerFireManager: BleLoggerManager | null = null;

  static fetchLogSizeAndStartAddress(logFolder: string, deviceName: string, deviceMac: string): number[] {
    PPLogSyncCmd.loggerFireManager = new BleLoggerManager(logFolder, deviceName, deviceMac);
    return [0x01, 0x01, 0x01];
  }

  static fetchLogSizeAndStartAddressBack(data: Uint8Array): PPBleFFF2ErrorCode {
    if (data.length > 2 && (data.length - 2 === data[1])) {
      PPLogSyncCmd.logLength = (data[6] << 24) | (data[5] << 16) | (data[4] << 8) | data[3];
      PPLogSyncCmd.logStartIndex = (data[10] << 24) | (data[9] << 16) | (data[8] << 8) | data[7];
      PPLogger.i("PPLogSync _logLength:" + PPLogSyncCmd.logLength + "_logStartIndex" + PPLogSyncCmd.logStartIndex);
      return PPBleFFF2ErrorCode.Ok;
    }
    return PPBleFFF2ErrorCode.Unknown;
  }

  static requestLogData(): number[] {
    PPLogSyncCmd.logIndex = 0;
    let cmd: number[] = [0x01, 0x09, 0x02];
    const lenByte = ByteUtil.decimalToByteList(PPLogSyncCmd.logLength, 4);
    const startByte = ByteUtil.decimalToByteList(PPLogSyncCmd.logStartIndex, 4);
    cmd.push(...lenByte);
    cmd.push(...startByte);
    return cmd;
  }

  static requestLogDataBack(data: Uint8Array): number {
    if (data.length > 2) {
      const logData = data.subarray(2);
      const textDecoder = new util.TextDecoder('ascii');
      const logDataStr = textDecoder.decode(logData);

      PPLogSyncCmd.logIndex += logData.length;
      PPLogger.v('PPLogSync _logIndex:' + PPLogSyncCmd.logIndex);

      const progress = Math.ceil((PPLogSyncCmd.logIndex / PPLogSyncCmd.logLength) * 100);
      PPLogSyncCmd.loggerFireManager?.receive(logDataStr);
      return progress;
    }
    return 0;
  }

  static logEnd(): number[] {
    PPLogSyncCmd.loggerFireManager?.forceFlush();
    return [0x01, 0x01, 0x03];
  }

  static getLogFilePath(): string {
    return PPLogSyncCmd.loggerFireManager?.getLogFilePath() || "";
  }

  static logEndBack(data: Uint8Array): PPBleFFF2ErrorCode {
    if (data.length > 2 && (data.length - 2 === data[1])) {
      return data[2] === 0x03 ? PPBleFFF2ErrorCode.Ok : PPBleFFF2ErrorCode.Unknown;
    }
    return PPBleFFF2ErrorCode.Unknown;
  }
}

export default PPLogSyncCmd;