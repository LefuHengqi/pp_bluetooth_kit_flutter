import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPDeviceCalculateType } from '../../enums/PPDeviceEnums';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPLogger } from '../../log/PPLogger';
import { ByteUtil } from '../../utils/ByteUtil';
import HexUtil from '../../utils/HexUtil';
import { ProtocolNormalDeviceHelper } from '../../utils/ProtocolNormalDeviceHelper';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';

export class PPBananaDeviceDataAnalysis {
  private _lastReceiveData: string = "";
  private lastTimes: number = 0;
  private lockWeightKg: number = 0.0;
  private lockImpedance: number = 0;
  private myWeightKgInt: number = 0;
  private myImpedance: number = 0;
  private heartRate: number = 0;
  private impedance50: number = 0;
  private impedance100: number = 0;
  private lastReceiveData: string = "";
  private lastReceiveData11: string = "";
  private ssid: string = "";
  public dataChangeListener?: PPDataChangeListener;
  public historyDataInterface?: PPHistoryDataInterface;
  public monitorConfigResultCallback?: (sn: string | null, stateMenu: PPConfigWifiStateMenu | null) => void;
  public modifyServerDomainResultCallback?: (resultState: boolean) => void;
  public getWifiInfoCallback?: (ssid: string | null) => void;
  public monitorResetStateResultCallback?: (resultState: boolean) => void;

  analysisData(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    if (data.length === 0) {
      return;
    }

    // 1. 字节数组转字符串
    const receiveData = HexUtil.formatHexString(data);
    PPLogger.i(`analysisData data:${receiveData}`);

    // 2. 过滤重复数据（2.5秒内相同数据视为重复）
    if (this._lastReceiveData !== receiveData || Date.now() - this.lastTimes > 2500) {
      this.lastTimes = Date.now();
      this._lastReceiveData = receiveData;

      // 3. 根据指令头进行分支处理
      if (receiveData.length === 22) {
        // 22字节体脂数据
        this.analyticalDataFatV2(data, deviceModel);
      }
    }
  }

  analyticalDataFatV2(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    if (data.length < 2) {
      return;
    }

    // 获取前导字节（原substring(0,2) → 取第0个字节）
    const prefixByte = data[0];

    // 4电极双频算法，阻抗解析
    if (deviceModel?.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate4_1
      && prefixByte === 0xEF
      && data.length === 14) { // 原28字符=14字节

      PPLogger.i("analyticalData V2协议 4电极双频算法，阻抗解析");

      // 提取阻抗数据（原substring(10,18) → 字节5-9）
      const impedance50 = ByteUtil.bytesToLong(data.slice(5, 9), true); // 小端序

      // 提取阻抗数据（原substring(18,26) → 字节9-13）
      const impedance100 = ByteUtil.bytesToLong(data.slice(9, 13), true); // 小端序

      PPLogger.i(`阻抗50: ${impedance50}, 阻抗100: ${impedance100}`);
    } else {
      // 检查超重标记（原substring(6,10) → 字节3-5）
      if (data.length > 5 && data[3] === 0xFF && data[4] === 0xFF) {
        PPLogger.i("analyticalData V2协议 超重");
        const bodyBaseModel = new PPBodyBaseModel();
        bodyBaseModel.deviceModel = deviceModel ?? undefined;
        this.dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
      } else {
        switch (prefixByte) {
          case 0xCF: // 'CF'
            if (deviceModel?.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate4_1) {
              // 双阻抗体脂秤
            } else {
              // 单阻抗体脂秤
              this.analyzeSingleImpedanceDataCF(data, deviceModel, this.dataChangeListener);
            }
            break;

          case 0xCE: // 'CE'
            // 体重秤
            this.analyzeSingleImpedanceDataCE(data, deviceModel, this.dataChangeListener);
            break;
        }
      }
    }
  }

  analyzeSingleImpedanceDataCF(data: Uint8Array, deviceModel: PPDeviceModel | null,
    dataChangeListener?: PPDataChangeListener): void {
    if (data.length < 10) {
      return;
    } // Minimum length check (original 20 chars = 10 bytes)

    // Get unit type from bytes
    const unitType = ProtocolNormalDeviceHelper.getPpUnitType(data, deviceModel);

    // Get weight values
    const weightKg = ProtocolNormalDeviceHelper.getWeightKg(data);
    const weightKgInt = ProtocolNormalDeviceHelper.getWeightG(data);

    // Get signLocked (byte 9 - original substring(18,20))
    const signLocked = data[9];
    const bodyBaseModel = new PPBodyBaseModel();
    let finalImpedance = 0;

    // Process impedance based on signLocked
    if (signLocked === 0x00) {
      finalImpedance = ProtocolNormalDeviceHelper.getImpedance(data);
    } else if (signLocked === 0xA0) {
      // DC scale
      finalImpedance = ProtocolNormalDeviceHelper.getImpedance(data);
      if (finalImpedance > 1200) {
        finalImpedance = Math.floor(finalImpedance / 10);
      }
    }

    // Get impedance/heart rate (bytes 1-2 - original substring(2,6))
    const impedanceOrHeartRate = (data[2] << 8) | data[1]; // Little-endian conversion
    PPLogger.i(`impedanceOrHeartRate = ${impedanceOrHeartRate} heartRateHex = ${data[1].toString(16)}${data[2].toString(16)}`);

    // Set base model properties
    bodyBaseModel.impedance = finalImpedance;
    bodyBaseModel.deviceModel = deviceModel ?? undefined;
    bodyBaseModel.unit = unitType;
    bodyBaseModel.weight = weightKgInt;

    if (signLocked === 0x01) {
      // Process data
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel ?? null);
      if (impedanceOrHeartRate > 12000) {
        if (weightKg > 0) {
          this.myWeightKgInt = weightKgInt;
        }
        bodyBaseModel.weight = this.myWeightKgInt;
        if (finalImpedance > 0) {
          this.myImpedance = finalImpedance;
        }
        bodyBaseModel.impedance = this.myImpedance;

        const heartRateSign = data[2]; // byte 2 (original substring(4,6))
        if ((heartRateSign & 0x80) === 0x80) {
          // Measuring heart rate
          bodyBaseModel.isHeartRating = true;
          this.cacheLockWeightKg(bodyBaseModel);
          dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel ?? null);
        }
      }
    } else if (signLocked === 0xA0) {
      bodyBaseModel.impedance = finalImpedance;
      this.onLockDataHearRateDevice(bodyBaseModel, dataChangeListener);
    } else {
      // Locked data
      PPLogger.e(`ppScale_ lockData weightKg = ${weightKg} myWeightKg = ${this.myWeightKgInt}`);
      if (impedanceOrHeartRate > 12000) {
        if (weightKg > 0) {
          this.myWeightKgInt = weightKgInt;
        }
        bodyBaseModel.weight = this.myWeightKgInt;
        if (finalImpedance > 0) {
          this.myImpedance = finalImpedance;
        }
        bodyBaseModel.impedance = this.myImpedance;

        const heartRateSign = data[2]; // byte 2 (original substring(4,6))
        if ((heartRateSign & 0xC0) === 0xC0) {
          if (this.myWeightKgInt > 0) {
            // Stop measuring
            bodyBaseModel.isHeartRating = false;
            const heartRate = data[1]; // byte 1 (original substring(2,4))
            bodyBaseModel.heartRate = heartRate;

            this.cacheLockWeightKg(bodyBaseModel);
            dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel ?? null);
          }
          this.myWeightKgInt = 0;
          this.myImpedance = 0;
        } else if ((heartRateSign & 0x80) === 0x80) {
          // Measuring heart rate
          bodyBaseModel.isHeartRating = true;
          this.cacheLockWeightKg(bodyBaseModel);
          dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel ?? null);
        } else {
          if (this.myWeightKgInt > 0) {
            bodyBaseModel.isHeartRating = false;
            this.cacheLockWeightKg(bodyBaseModel);
            dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel ?? null);
          } else {
            bodyBaseModel.isHeartRating = false;
            this.cacheLockWeightKg(bodyBaseModel);
            dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel ?? null);
          }
          this.resetCacheLockWeight();
        }
      } else {
        bodyBaseModel.impedance = finalImpedance;
        this.onLockDataHearRateDevice(bodyBaseModel, dataChangeListener);
      }
    }
  }

  onLockDataHearRateDevice(bodyBaseModel: PPBodyBaseModel, dataChangeListener?: PPDataChangeListener): void {
    // Cache the weight data first
    this.cacheLockWeightKg(bodyBaseModel);

    if (bodyBaseModel.weight > 0) {
      PPLogger.i(`onLockDataHearRateDevice monitorLockData weight: ${bodyBaseModel.weight}`);

      try {
        // In ArkTS, we can directly pass the object without JSON conversion
        dataChangeListener?.monitorLockData?.(bodyBaseModel,
          bodyBaseModel.deviceModel == undefined ? null : bodyBaseModel.deviceModel);
      } catch (e) {
        PPLogger.e(e.toString());
      }
    } else {
      PPLogger.i(`onLockDataHearRateDevice monitorDataFail weight: ${bodyBaseModel.weight}`);
      dataChangeListener?.monitorDataFail?.(bodyBaseModel,
        bodyBaseModel.deviceModel == undefined ? null : bodyBaseModel.deviceModel);
    }
  }

  cacheLockWeightKg(bodyBaseModel: PPBodyBaseModel): void {
    this.lockWeightKg = bodyBaseModel.getPpWeightKg(); // Accessing as TypeScript property
    this.lockImpedance = bodyBaseModel.impedance; // Direct property access
  }

  resetCacheLockWeight(): void {
    this.lockWeightKg = 0.0;
    this.lockImpedance = 0;
    this.myWeightKgInt = 0;
    this.myImpedance = 0;
    this.impedance50 = 0;
    this.impedance100 = 0;
    this.heartRate = 0;
  }

  analyzeSingleImpedanceDataCE(data: Uint8Array, deviceModel: PPDeviceModel | null,
    dataChangeListener?: PPDataChangeListener): void {
    // Minimum length check (original 20 chars = 10 bytes)
    if (data.length < 10) {
      return;
    }

    // Get unit type from bytes
    const unitType = ProtocolNormalDeviceHelper.getPpUnitType(data, deviceModel);

    // Get weight values
    const weightKg = ProtocolNormalDeviceHelper.getWeightKg(data);
    const weightKgInt = ProtocolNormalDeviceHelper.getWeightG(data);

    // Get signLocked (byte 9 - original substring(18,20))
    const signLocked = data[9];
    const bodyBaseModel = new PPBodyBaseModel();

    // Initialize model
    bodyBaseModel.impedance = 0;
    bodyBaseModel.deviceModel = deviceModel ?? undefined;
    bodyBaseModel.unit = unitType;
    bodyBaseModel.weight = weightKgInt;

    if (signLocked === 0x01) {
      // Process data (0x01 = "01")
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel ?? null);
    } else {
      // Locked data
      PPLogger.i(`ppScale_ weight scale lockData weightKg:${weightKg}`);
      this.cacheLockWeightKg(bodyBaseModel);
      dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel ?? null);
    }
  }
}