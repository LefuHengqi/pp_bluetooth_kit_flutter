import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPDeviceCalculateType } from '../../enums/PPDeviceEnums';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPLogger } from '../../log/PPLogger';
import { ByteUtil } from '../../utils/ByteUtil';
import HexUtil from '../../utils/HexUtil';
import { ProtocolNormalDeviceHelper } from '../../utils/ProtocolNormalDeviceHelper';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import call from '@ohos.telephony.call';
import { PPScaleState, PPScaleStateHeartRateType, PPScaleStateImpedanceType } from '../../../../../Index';

export class PPAppleDeviceDataAnalysis {
  private _lastReceiveData: string = "";
  private lastTimes: number = 0;
  private lockWeightKg: number = 0.0;
  private lockImpedance: number = 0;
  private myWeightKgInt: number = 0;
  private myImpedance: number = 0;
  private impedance50: number = 0;
  private impedance100: number = 0;
  private heartRate: number = 0;
  private lastReceiveData: string = "";
  private lastReceiveData11: string = "";
  private ssidHex: Uint8Array = new Uint8Array(0);
  public dataChangeListener?: PPDataChangeListener;
  public historyDataInterface?: PPHistoryDataInterface;
  public monitorConfigResultCallback?: (sn: string | null, stateMenu: PPConfigWifiStateMenu | null) => void;
  public modifyServerDomainResultCallback?: (resultState: boolean) => void;
  public getWifiInfoCallback?: (ssid: string | null) => void;
  public onResetStateResultCallBack?: (resultState: boolean) => void;

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
      switch (data[0]) {
        case 0x06: // SN响应
          const sn = ByteUtil.bufferToAscii(data.slice(1));
          PPLogger.i(`sn:${sn}`);
          this.monitorConfigResultCallback?.(sn, PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS);
          break;

        case 0x0A: // WiFi信息
          this.processWifiInfo(data);
          break;

        case 0xF8: // 修改服务器域名响应
          this.modifyServerDomainResultCallback?.(data[1] === 0x00);
          break;

        case 0xF1:
          if (data.length === 8) {
            // F1指令处理
          } else if (data[1] === 0x00) {
            // F1 00指令处理
          }
          break;
        case 0xF5:
          if (data.length > 3) {
            //域名参数获取
          } else if (data[1] == 0x01) {
            if (this.getWifiInfoCallback) {
              this.getWifiInfoCallback?.("");
            }
          }

          break;
        case 0xF9:
          if (data[1] === 0x00 || data[1] === 0x01) {
            if (this.onResetStateResultCallBack) {
              this.onResetStateResultCallBack?.(true);
            }
          }
          break;

        case 0xF2:
          if (data[1] === 0x00) {
            this.resetCacheLockWeight();
            if (this.historyDataInterface) {
              this.historyDataInterface.monitorHistoryEnd?.();
            }
          }
          break;

        default:
        // 4. 根据数据长度处理不同类型数据
          if (receiveData.length === 34) {
            // 34字节数据处理
          } else if (receiveData.length === 36 || receiveData.length === 40) {
            // 18字节历史数据（实际36/40字符）
            this._analysisDataHistory(data, deviceModel);
          } else if (receiveData.length === 22) {
            // 22字节体脂数据
            this.analyticalDataFatV2(data, deviceModel);
          }
      }
    }
  }

  // 处理WiFi信息（从0x0A指令中提取）
  private processWifiInfo(data: Uint8Array): void {
    // 确保数据长度足够
    if (data.length < 6) {
      return;
    }

    // 提取包信息（直接读取Uint8Array中的字节）
    const total = data[1]; // 总包数（原totalStr位置）
    const num = data[2]; // 当前包序号（原numStr位置）

    // 计算SSID数据部分的起始和结束位置
    const ssidStart = 4; // 跳过指令头(0x0A)、total和num
    const ssidEnd = data.length - 1; // 去掉末尾校验位等

    // 如果是第一包，重置SSID
    if (num <= 1) {
      this.ssidHex = new Uint8Array(0);
    }

    if (ssidEnd > ssidStart) {
      const ssidBytes = data.slice(ssidStart, ssidEnd);
      this.ssidHex = ByteUtil.concatArrays([this.ssidHex, ssidBytes])
    }

    // 如果是最后一包，回调结果
    if (num === total - 1) {
      const ssid = ByteUtil.uint8ArrayToString(this.ssidHex);
      if (this.getWifiInfoCallback) {
        this.getWifiInfoCallback?.(ssid);
      }
    }
  }

  // 历史数据分析
  // 历史数据分析入口
  private _analysisDataHistory(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    if (data.length === 0) {
      return;
    }

    // 直接比较第一个字节的值
    switch (data[0]) {
      case 0xCF: // CF 类型数据
      case 0xCE: // CE 类型数据
        this._onHistoryCForCE(data, deviceModel);
        break;
      case 0xFF: // FF 类型数据
        this._onHistoryFF(data, deviceModel);
        break;
      default:
        break;
    }
  }

  // CF/CE 格式历史数据处理
  private _onHistoryCForCE(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    const bodyBaseModel = new PPBodyBaseModel();

    // 1. 获取单位类型
    bodyBaseModel.unit = ProtocolNormalDeviceHelper.getPpUnitType(data, deviceModel);

    // 2. 获取重量（克）
    bodyBaseModel.weight = ProtocolNormalDeviceHelper.getWeightG(data);
    console.debug(`historyData WeightKg = ${bodyBaseModel.weight}`);

    // 3. 获取阻抗
    bodyBaseModel.impedance = ProtocolNormalDeviceHelper.getImpedance(data);

    // 4. 心率处理（检查第4-5字节是否为C0开头）
    if (data.length >= 6 && data[2] == 0xC0) {
      bodyBaseModel.heartRate = data[1];
    } else {
      bodyBaseModel.heartRate = 0;
    }

    // 5. 设置设备模型
    bodyBaseModel.deviceModel = deviceModel ?? undefined;
    bodyBaseModel.userModel = undefined;

    // 6. 获取测量时间
    bodyBaseModel.measureTime = ProtocolNormalDeviceHelper.getClock(data, deviceModel);
    console.debug(`historyData weightInt:${bodyBaseModel.weight} measureTime:${bodyBaseModel.measureTime}`);

    // 7. 回调数据
    if (this.historyDataInterface) {
      this.historyDataInterface.monitorHistoryData?.(bodyBaseModel);
    }
  }

  // FF 格式历史数据处理
  private _onHistoryFF(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    const bodyBaseModel = new PPBodyBaseModel();

    // 1. 固定单位类型为KG
    bodyBaseModel.unit = PPUnitType.Unit_KG;

    // 2. 提取重量（6-7字节，小端序）
    if (data.length >= 8) {
      const weightHigh = data[2];
      const weightLow = data[3];

      // 小端序组合（低位在前）: weightLow + weightHigh
      const weightKgInt = (weightLow << 8) | weightHigh;
      PPLogger.d(`onHistoryFF historyData WeightKg:${weightKgInt}`);
    }

    // 3. 提取阻抗（50KHz和100KHz）
    if (data.length >= 16) {
      bodyBaseModel.impedance = ByteUtil.bytesToLong(data.slice(12, 16), true);
      bodyBaseModel.ppImpedance100EnCode = ByteUtil.bytesToLong(data.slice(16, 20));
    }

    console.info(`onHistoryFF 4电极双频算法，阻抗50:${bodyBaseModel.impedance} 阻抗100:${bodyBaseModel.ppImpedance100EnCode}`);

    // 4. 心率（22-23字节）
    if (data.length >= 24) {
      bodyBaseModel.heartRate = data[11];
    }

    // 5. 设置设备模型
    bodyBaseModel.deviceModel = deviceModel ?? undefined;

    // 6. 获取测量时间
    bodyBaseModel.measureTime = ProtocolNormalDeviceHelper.getV4Clock(data, 8);
    console.debug(`onHistoryFF historyData weightInt:${bodyBaseModel.weight} measureTime:${bodyBaseModel.measureTime}`);

    // 7. 回调数据
    if (this.historyDataInterface) {
      this.historyDataInterface.monitorHistoryData?.(bodyBaseModel);
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
        bodyBaseModel.isOverload = true;
        this.dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
      } else {
        switch (prefixByte) {
          case 0xCF: // 'CF'
            if (deviceModel?.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeAlternate4_1) {
              // 双阻抗体脂秤
              this.analyzeDualImpedanceDataCF(data, deviceModel, this.dataChangeListener);
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

  analyzeDualImpedanceDataCF(data: Uint8Array, deviceModel: PPDeviceModel | null,
    dataChangeListener?: PPDataChangeListener): void {
    if (data.length < 20) {
      return;
    } // Minimum required length check

    // Get unit type from bytes
    const unitType = ProtocolNormalDeviceHelper.getPpUnitType(data, deviceModel);

    // Get weight values
    const weightKg = ProtocolNormalDeviceHelper.getWeightKg(data);
    const weightKgInt = ProtocolNormalDeviceHelper.getWeightG(data);

    // Create base model
    const bodyBaseModel = new PPBodyBaseModel();
    bodyBaseModel.deviceModel = deviceModel ?? undefined;
    bodyBaseModel.unit = unitType;
    bodyBaseModel.weight = weightKgInt;
    let scaleState = bodyBaseModel?.scaleState ?? new PPScaleState();
    bodyBaseModel.scaleState = scaleState;
    // Process heart rate data (bytes 2-3)
    const heartRateSign = data[2]; // Original substring(4,6) → byte[2]
    if (heartRateSign === 0xC0) {
      scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_NO_MEASURE
      bodyBaseModel.scaleState = scaleState;
      const heartRate = data[1]; // Original substring(2,4) → byte[1]
      bodyBaseModel.heartRate = heartRate;
    }

    // Get data type (byte 9 - original substring(18,20))
    const dataType = data[9];

    switch (dataType) {
      case 0x08: // "08"
        // Weight stable, measuring impedance
        // const lockWeightKg = bodyBaseModel.getPpWeightKg();
        scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_MEASURING;
        bodyBaseModel.scaleState = scaleState;
        dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
        break;

      case 0x03: // "03"
        // Measuring heart rate
        scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_MEASURING;
        bodyBaseModel.scaleState = scaleState;
        dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
        break;

      case 0x01: // "01"
        // Process data
        dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
        break;

      case 0x00: // "00"
        // Locked data, test complete
        PPLogger.i("ppScale_ lockData weightKg = " + weightKg + " myWeightKg = " + this.myWeightKgInt);
        if (weightKg > 0) {
          this.myWeightKgInt = weightKgInt;
        }
        bodyBaseModel.impedance = this.impedance50;
        bodyBaseModel.ppImpedance100EnCode = this.impedance100;
        bodyBaseModel.weight = this.myWeightKgInt;
        scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_SUCCESS
        bodyBaseModel.scaleState = scaleState;
        bodyBaseModel.heartRate = this.heartRate;

        dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel);
        this.resetCacheLockWeight();
        break;
    }
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