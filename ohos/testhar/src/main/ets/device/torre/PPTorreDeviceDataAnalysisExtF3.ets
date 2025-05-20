import { PPDeviceCalculateType } from '../../enums/PPDeviceEnums';
import { PPScaleFootState, PPScaleState } from '../../enums/PPScaleState';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPLogger } from '../../log/PPLogger';
import { UnitUtil } from '../../utils/UnitUtil';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { TorreHelper } from './TorreHelper';

export class PPTorreDeviceDataAnalysisExtF3 {
  dataChangeListener: PPDataChangeListener | null = null;
  onHistoryDataChange: (() => void) | null = null;

  /**
   * 处理F3协议数据（Uint8Array版）
   * @param data 接收到的Uint8Array数据
   * @param deviceModel 设备模型
   * @param bodyBaseModel 身体数据模型
   */
  protocolDataF3(data: Uint8Array, deviceModel: PPDeviceModel | null, bodyBaseModel: PPBodyBaseModel | null): void {
    if (!data || data.length === 0) {
      return;
    }

    // 检查数据长度是否足够（至少2字节）
    if (data.length < 2) {
      PPLogger.w("protocolDataF3_: Data length too short");
      return;
    }
    const preByte = data[0];
    switch (preByte) {
      case 0x01:
      case 0x11:
        if (bodyBaseModel) {
          this.handleMeasurementData(data, deviceModel, bodyBaseModel);
        }
        break;
      case 0x02:
        if (bodyBaseModel) {
          this.handleEncryptedImpedance(data, bodyBaseModel);
        }
        break;
      case 0x03:
        this.handlePlainTextImpedance(data);
        break;
      case 0x04:
        PPLogger.d("Gsensor触发状态");
        break;
      case 0x05:
        PPLogger.d("称端有新的历史数据");
        this.onHistoryDataChange?.();
        break;
      case 0x06:
        PPLogger.d("设备端用户选择状态上报");
        break;
      default:
        PPLogger.w(`protocolDataF3_: Unknown prefix byte 0x${preByte.toString(16).padStart(2, '0')}`);
        break;
    }
  }

  /**
   * 处理测量数据（0x01）
   */
  handleMeasurementData(data: Uint8Array, deviceModel: PPDeviceModel | null, bodyBaseModel: PPBodyBaseModel): void {
    const measuStateLow = data[2];
    const measuStateHigh = data[3];

    const scaleState = TorreHelper.updateMeasureState(measuStateLow, measuStateHigh, bodyBaseModel?.scaleState ?? new PPScaleState());
    bodyBaseModel.scaleState = scaleState;

    this.dataChangeListener?.monitorScaleState?.(scaleState);

    // 提取重量数据（4字节，小端序）
    const weightKgInt = TorreHelper.getWeightG(data.subarray(4, 6))

    bodyBaseModel.unit = UnitUtil.getUnitTypeSimple(data[6]);
    // 处理测量状态
    if ((measuStateLow & 0x0C) === 0x0C) {
      PPLogger.d(`protocolDataF3 离秤 重量: ${weightKgInt}`);
      bodyBaseModel.weight = weightKgInt;
      bodyBaseModel.isOverload = false;
    } else if ((measuStateLow & 0x08) === 0x08) {
      PPLogger.d(`protocolDataF3 超重 重量: ${weightKgInt}`);
      bodyBaseModel.isOverload = true;
    } else if ((measuStateLow & 0x04) === 0x04) {
      PPLogger.d(`protocolDataF3 稳定重量: ${weightKgInt}`);
      bodyBaseModel.weight = weightKgInt;
      bodyBaseModel.isOverload = false;
    } else {
      PPLogger.d(`protocolDataF3 实时重量: ${weightKgInt}`);
      bodyBaseModel.weight = weightKgInt;
      bodyBaseModel.isOverload = false;
    }

    //处理脚长测量状态
    if ((measuStateHigh & 0x0C) === 0x0C) {
      // 脚长测量成功
      if (data.length >= 17) {
        const footLenBytes = data.subarray(15, 17);
        bodyBaseModel.footLen = TorreHelper.getWeightG(footLenBytes);
        PPLogger.d(`protocolDataF3 lock footLen: ${bodyBaseModel.footLen}`);
        this.dataChangeListener?.monitorFootLenMeasure?.(scaleState?.footState ?? PPScaleFootState.PPScaleFootStateMeasurementSuccessful,
          bodyBaseModel.footLen);
      }
    } else if ((measuStateHigh & 0x04) === 0x04) {
      // 脚长准备中
      PPLogger.d("protocolDataF3 脚长准备中");
      this.dataChangeListener?.monitorFootLenMeasure?.(scaleState?.footState ?? PPScaleFootState.PPScaleFootStatePrepare, 0);
    } else if ((measuStateHigh & 0x08) === 0x08) {
      // 脚长测量中
      if (data.length >= 17) {
        const footLenBytes = data.subarray(15, 17);
        bodyBaseModel.footLen = TorreHelper.getWeightG(footLenBytes);
        PPLogger.d(`protocolDataF3 process footLen: ${bodyBaseModel.footLen}`);
        this.dataChangeListener?.monitorFootLenMeasure?.(scaleState?.footState ?? PPScaleFootState.PPScaleFootStateMeasuring, bodyBaseModel.footLen);
      }
    } else if ((measuStateHigh & 0x10) === 0x10) {
      // 脚长测量失败
      PPLogger.e("protocolDataF3 脚长测量失败");
      this.dataChangeListener?.monitorFootLenMeasure?.(scaleState?.footState ?? PPScaleFootState.PPScaleFootStateMeasurementFailed, 0);
    } else {
      // 脚长未测量
      PPLogger.d("protocolDataF3 脚长未测量");
    }

    // 处理测量完成状态
    if ((measuStateHigh & 0x80) === 0x80) {
      this.dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel);
    } else {
      this.dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
    }

    // 处理阻抗数据（如果存在）
    if (data.length >= 14) {
      const impedancePosition = data[8];
      const impedanceType = data[9];

      if (deviceModel?.deviceCalculateType === PPDeviceCalculateType.PPDeviceCalculateTypeDirect) {
        const impedance = ((data[11] << 8) | data[10]) / 10; // 小端序处理
        bodyBaseModel.impedance = impedance;
        PPLogger.d(`protocolDataF3 明文阻抗 ${impedance}`);
      }
      //明文阻抗值[在单频阻抗模式下此字段为0]
      const impedance2 = (data[13] << 8) | data[12]; // 12-13字节
    }
  }

  /**
   * 处理加密阻抗数据（0x02）
   */
  handleEncryptedImpedance(data: Uint8Array, bodyBaseModel: PPBodyBaseModel): void {
    if (data.length < 4) {
      PPLogger.w("handleEncryptedImpedance: Data length insufficient");
      return;
    }

    const impedanceMeasureFrequencyByte = data[1];
    const bodyPartsByte = data[2];

    if (impedanceMeasureFrequencyByte === 0x02) {
      let impedance = TorreHelper.getImpedance(data.subarray(4, 8));
      const impedance100EnCode = TorreHelper.getImpedance(data.subarray(8, 12));
      bodyBaseModel.impedance = impedance;
      bodyBaseModel.ppImpedance100EnCode = impedance100EnCode;
      PPLogger.d(`protocolDataF3 四电极 双频 impedance: ${impedance} impedance100EnCode: ${impedance100EnCode}`);
    } else if (impedanceMeasureFrequencyByte === 0x01) {
      const impedance = TorreHelper.getImpedance(data.subarray(4, 8));
      bodyBaseModel.impedance = impedance;
      PPLogger.d(`protocolDataF3 四电极 impedance: ${impedance}`);
    } else {
      // 八电极处理逻辑
      const impedanceData = data.subarray(4);
      const len = 4;

      if ((bodyPartsByte & 0x01) === 0x01) {
        //右手
        bodyBaseModel.z20KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
        bodyBaseModel.z100KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
      }
      if ((bodyPartsByte & 0x02) == 0x02) {
        //左手
        bodyBaseModel.z20KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(2 * len, 3 * len));
        bodyBaseModel.z100KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(3 * len, 4 * len));
      }
      if ((bodyPartsByte & 0x04) == 0x04) {
        //躯干
        bodyBaseModel.z20KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
        bodyBaseModel.z100KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
      }
      if ((bodyPartsByte & 0x08) == 0x08) {
        //右脚
        bodyBaseModel.z20KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(2 * len, 3 * len));
        bodyBaseModel.z100KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(3 * len, 4 * len));
      }
      if ((bodyPartsByte & 0x10) == 0x10) {
        //左脚
        bodyBaseModel.z20KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
        bodyBaseModel.z100KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
      }
      PPLogger.d("protocolDataF3 八电极 bodyBaseModel:" + bodyBaseModel.toString());
    }
  }

  /**
   * 处理明文阻抗数据（0x03）
   */
  handlePlainTextImpedance(data: Uint8Array): void {
    if (data.length < 10) {
      PPLogger.w("handlePlainTextImpedance: Data length insufficient");
      return;
    }

    const plainTextBodyPartsByte = data[2];
    const plainTextImpedanceTypeByte = data[4];

    if (plainTextBodyPartsByte === 0x20) {
      const impedance = (data[5] << 8) | data[4]; // 小端序
      // 处理双脚阻抗数据
    }
  }
}