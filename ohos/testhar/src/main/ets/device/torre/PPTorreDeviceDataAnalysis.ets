import { PPBleFFF2ErrorCode } from '../../enums/PPBleFFF2ErrorCode';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPLogger } from '../../log/PPLogger';
import { PPTorreDeviceDataAnalysisExtF1 } from './PPTorreDeviceDataAnalysisExtF1';
import { PPTorreDeviceDataAnalysisExtF2 } from './PPTorreDeviceDataAnalysisExtF2';
import { ByteUtil } from '../../utils/ByteUtil';
import { PPTorreDeviceDataAnalysisExtF3 } from './PPTorreDeviceDataAnalysisExtF3';

/**
 * TORRE设备数据分析类
 */
export class PPTorreDeviceDataAnalysis {

  public lockWeightKg: number = 0.0;
  public lockImpedance: number = 0;
  public myWeightKgInt: number = 0;
  public myImpedance: number = 0;
  public impedance50: number = 0;
  public impedance100: number = 0;
  public heartRate: number = 0;
  public lastReceiveData: string = "";
  public lastReceiveData11: string = "";
  public ssid: string = "";
  // 获取日志相关回调
  public bleRequestLogCallBack?: (
    errorCode: PPBleFFF2ErrorCode,
    log: string,
    progress: number,
    isEnd: boolean
  ) => void;
  public onBleDfuWaitChunkEndCallBack?: () => void;
  public onBleDfuChunkSendErrorCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;
  dataAnalysisExtF1 = new PPTorreDeviceDataAnalysisExtF1();
  dataAnalysisExtF2 = new PPTorreDeviceDataAnalysisExtF2();
  dataAnalysisExtF3 = new PPTorreDeviceDataAnalysisExtF3();

  /**
   * 处理F1协议数据
   * @param data 数据数组
   * @param deviceModel 设备模型
   */
  public protocolDataF1(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    // 实现F1协议数据处理
    this.logi("PPTorreDeviceDataAnalysis protocolDataF1_: " + ByteUtil.uint8ArrayToHex(data));
    this.dataAnalysisExtF1.protocolDataF1(data, deviceModel)
  }

  /**
   * 处理F2协议数据
   * @param data 数据数组
   * @param deviceModel 设备模型
   */
  public protocolDataF2(data: Uint8Array, deviceModel: PPDeviceModel | null): void {
    // 实现F2协议数据处理
    // 需要导入并调用 pp_torre_device_data_analysis_ext_f2.ts 中的实现
    this.logi("PPTorreDeviceDataAnalysis protocolDataF2_: " + ByteUtil.uint8ArrayToHex(data));
    this.dataAnalysisExtF2.protocolDataF2(data, deviceModel)
  }

  /**
   * 处理F3协议数据
   * @param data 数据数组
   * @param deviceModel 设备模型
   * @param bodyBaseModel 身体基础模型
   */
  public protocolDataF3(data: Uint8Array, deviceModel: PPDeviceModel | null, bodyBaseModel: PPBodyBaseModel): void {
    // 实现F3协议数据处理
    this.logi("PPTorreDeviceDataAnalysis protocolDataF3: " + ByteUtil.uint8ArrayToHex(data));
    this.dataAnalysisExtF3.protocolDataF3(data, deviceModel, bodyBaseModel)
  }

  /**
   * 记录信息日志
   * @param log 日志内容
   */
  public logi(log: string): void {
    PPLogger.i(`PPTorreDeviceDataAnalysis ${log}`);
  }

  /**
   * 记录错误日志
   * @param log 日志内容
   */
  public loge(log: string): void {
    PPLogger.e(`PPTorreDeviceDataAnalysis ${log}`);
  }


  /**
   * 重置缓存锁定重量
   */
  public resetCacheLockWeight(): void {
    this.lockWeightKg = 0.0;
    this.lockImpedance = 0;
    this.myWeightKgInt = 0;
    this.myImpedance = 0;
    this.impedance50 = 0;
    this.impedance100 = 0;
    this.heartRate = 0;
  }

  /**
   * 重置历史数据
   */
  public resetHistory(): void {
    this.logi("liyp_ reset cache data");
    this.lastReceiveData = "";
    this.lastReceiveData11 = "";
    this.lockWeightKg = 0.0;
    this.lockImpedance = 0;
  }
}