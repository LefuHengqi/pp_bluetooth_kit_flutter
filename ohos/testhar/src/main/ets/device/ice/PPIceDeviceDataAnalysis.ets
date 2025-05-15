import { PPBleFFF2ErrorCode } from '../../enums/PPBleFFF2ErrorCode';
import { OnOTAStateListener } from '../../listener/OnOTAStateListener';
import { PPDeviceModel } from '../../vo/PPDeviceModel';
import { PPBodyBaseModel } from '../../vo/PPBodyBaseModel';
import { PPUnitType } from '../../enums/PPUnitType';
import { PPConfigWifiStateMenu } from '../../enums/PPConfigWifiStateMenu';
import { PPLogger } from '../../log/PPLogger';
import { ByteUtil } from '../../utils/ByteUtil';
import { TorreHelper } from '../torre/TorreHelper';
import HexUtil from '../../utils/HexUtil';
import { PPHistoryDataInterface } from '../../listener/PPHistoryDataInterface';
import { PPTorreWifiSyncCmd } from '../torre/wifi/PPTorreWifiSyncCmd';
import { PPWifiModel } from '../../vo/PPWifiModel';
import { ProtocolNormalDeviceHelper } from '../../utils/ProtocolNormalDeviceHelper';
import { PPUserModel } from '../../vo/PPUserModel';
import { PPDataChangeListener } from '../../listener/PPDataChangeListener';
import { PPScaleState, PPScaleStateHeartRateType, PPScaleStateImpedanceType } from '../../../../../Index';

/**
 * TORRE设备数据分析类
 */
export class PPIceDeviceDataAnalysis {
  private lastTimes: number = 0; // 用于过滤相同数据，但是又不是同一组数据3s之外

  public lockWeightKg: number = 0.0;
  public lockImpedance: number = 0;
  public myWeightKgInt: number = 0;
  public myImpedance: number = 0;
  public impedance50: number = 0;
  public impedance100: number = 0;
  public heartRate: number = 0;
  lastReceiveData: Uint8Array = new Uint8Array(0);
  public lastReceiveData11: string = "";
  public ssid: string = "";
  // 回调函数定义
  public onConfigWifiResultCallBack?: (sn: string | null, stateMenu: PPConfigWifiStateMenu | null) => void;
  public onModifyServerDomainResultCallBack?: (resultState: boolean | null) => void;
  public mtuCallBack?: (mtu: number | null) => void;
  public onLightCallBack?: (light: number | null) => void;
  public onDeviceUnitCallBack?: (unitType: PPUnitType | null) => void;
  public onLightResultCallBack?: (isSuccess: boolean | null) => void;


  public onConfigWifiStateResultCallback?: (state: number | null) => void;
  public onClearDataResultCallBack?: (isSuccess: boolean | null) => void;
  public onBindStateResultCallBack?: (isSuccess: boolean | null) => void;
  public onBindStateCallBack?: (state: number | null) => void;
  public onStartMeasureResultCallBack?: (state: number | null) => void;
  public onReadDeviceWifiMacCallBack?: (mac: string | null) => void;
  // DFU相关回调
  public queryDfuProtocolVersionCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;
  public queryDFUStateCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;
  public startDfuDataTransferCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;
  public currentFileDfuEndCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;
  public dfuEndCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;
  //调试过来的回调
  public monitorConfigResultCallback?: (sn: string | null, stateMenu: PPConfigWifiStateMenu) => void;
  public modifyServerDomainResultCallback?: (resultState: boolean) => void;
  public onWifiInfoCallBack?: (ssid: string | null) => void;
  public historyDataInterface?: PPHistoryDataInterface;
  public onResetStateResultCallBack?: (isSuccess: boolean | null) => void;
  public otaStateListener?: OnOTAStateListener;
  public dataChangeListener?: PPDataChangeListener;
  public onControlImpedanceResultCallBack?: (isSuccess: boolean) => void;
  public onImpedanceStateCallBack?: (isOn: boolean) => void;
  public onControlHeartRateResultCallback?: (isSuccess: boolean) => void;
  public onHeartRateStateCallBack?: (isOn: boolean) => void;

  //wifi列表回调 @state 0:成功，1:失败，2:电量低
  public monitorWiFiListCallBack?: (wifiModels: PPWifiModel[] | null, state: number) => void;
  //用于区分接收到的数据类型
  sendTag: number = TorreHelper.SEND_TAG_NORMAL;
  cacheReceiveData: Uint8Array = new Uint8Array(0);
  private ssidHex: Uint8Array = new Uint8Array(0);
  // 获取日志相关回调
  public bleRequestLogCallBack?: (
    errorCode: PPBleFFF2ErrorCode,
    log: string,
    progress: number,
    isEnd: boolean
  ) => void;
  public onBleDfuWaitChunkEndCallBack?: () => void;
  public onBleDfuChunkSendErrorCallBack?: (errorCode: PPBleFFF2ErrorCode) => void;

  /**
   * 处理F3协议数据
   * @param data 数据数组
   * @param deviceModel 设备模型
   * @param bodyBaseModel 身体基础模型
   */
  public protocolDataF4(data: Uint8Array, deviceModel: PPDeviceModel | null, bodyBaseModel: PPBodyBaseModel | null = null): void {
    // 实现F3协议数据处理
    PPLogger.i("PPIceDeviceDataAnalysis protocolDataF4: " + ByteUtil.uint8ArrayToHex(data));
    if (data.length === 0) {
      return;
    }
    if (this.sendTag == TorreHelper.SEND_TAG_HISTORY && data.length > 2 && data[2] == 0xAA) {
      this.protocolFilterHistoryData(data);
    } else if (data.length > 2 && data[1] == 0xAA) {
      this.protocolFilterHistoryDataNew(data);
    } else if (this.sendTag == TorreHelper.SEND_TAG_HISTORY && data.length > 2 && data[0] == 0x00) {
      this.protocolFilterWifiData(data);
    } else {
      this.protocolFilterData(data, bodyBaseModel, deviceModel);
    }
  }


  /**
   * 历史数据过滤
   * @param data
   */
  private protocolFilterHistoryData(receiveData: Uint8Array) {
    // 初始化缓冲区
    const dataContent = receiveData.subarray(2); // 公共部分提取
    this.pushReceiveData(dataContent);
  }

  /**
   * 历史数据新协议
   * @param data
   */
  private protocolFilterHistoryDataNew(receiveData: Uint8Array): void {
    // 初始化缓冲区
    const dataContent = receiveData.subarray(2); // 公共部分提取
    this.pushReceiveData(dataContent);
  }

  private protocolFilterWifiData(receiveData: Uint8Array): void {
    // 初始化缓冲区
    const dataContent = receiveData.subarray(2); // 公共部分提取
    this.pushReceiveData(dataContent);
  }

  private protocolFilterData(data: Uint8Array, bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) {

    // 1. 字节数组转字符串
    const receiveData = HexUtil.formatHexString(data);
    PPLogger.i(`analysisData data:${receiveData}`);

    // 3. 根据指令头进行分支处理
    if (data[0] == 0x55) {
      if (data[2] == 0x38) {
        //安全模式-掉电存储- 不测脂
        this.onControlImpedanceResultCallBack?.(true)
      } else if (data[2] == 0x41) {
        //安全模式-掉电存储-测脂
        this.onControlImpedanceResultCallBack?.(true)
      } else if (data[2] == 0x44) {
        //掉电存储-测心率
        this.onControlHeartRateResultCallback?.(true)
      } else if (data[2] == 0x43) {
        //掉电存储-不测心率
        this.onControlHeartRateResultCallback?.(true)
      }
    } else  if (data[0] == 0xFD && data[1] == 0xA0) {
      const impedanceState = data[2];
      const heartRateState = data[3];
      ////安全模式 0-失效，支持测脂。1-使能 不支持测脂
      this.onImpedanceStateCallBack?.(impedanceState==0);
      //心率禁用 0-失效 支持心率测试 1-使能 不支持心率测试
      this.onHeartRateStateCallBack?.(heartRateState==0);
    } else {

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
            this.onWifiInfoCallBack?.("");
          }
          break;
        case 0xF9:
          if (data[1] === 0x01) {
            this.onResetStateResultCallBack?.(true);
          } else {
            this.onResetStateResultCallBack?.(false);
          }
          break;

        case 0xF2: //历史数据结束
          this.processHistoryData(data, this.cacheReceiveData);
          break;

        case 0xFB: ////WiFi列表成功返回
          this.processWifiList(data, this.cacheReceiveData);
          break;

        case 0xEF:
          //state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
          if (data[1] == 0x00) { //接收成功,启动OTA
            this.otaStateListener?.onUpdateSuccess?.()
          } else if (data[1] == 0x01) { //接收失败，没有配置过ssid，退出OTA
            this.otaStateListener?.onUpdateFail?.(3)
          } else if (data[1] == 0x02) { //电量不足，退出OTA
            this.otaStateListener?.onUpdateFail?.(2)
          } else if (data[1] == 0x03) { //充电中，退出OTA
            this.otaStateListener?.onUpdateFail?.(4)
          }
          break;
        case 0xBF: //阻抗解析
          this.analyticalImpedance(data, bodyBaseModel);
          break;
        case 0xEF: //阻抗解析
          this.analyticalImpedanceDF(data, bodyBaseModel);
          break;
        case 0xCF: //体脂秤解析
          this.analyticalCF(data, bodyBaseModel, deviceModel, this.dataChangeListener);
          break;
        case 0xCE: //体重秤数据解析
          this.analyticalCE(data, bodyBaseModel, deviceModel, this.dataChangeListener);
          break;
        case 0x0C://配网失败返回

          this.configWifiFail(data, bodyBaseModel, deviceModel)
          break;
        default:
          break;
      }
    }
  }

  analyticalImpedance(receiveData: Uint8Array, baseModel: PPBodyBaseModel | null = null) {

    if (baseModel) {
      const impedanceData = receiveData.subarray(2);
      const len = 4;
      if (receiveData[1] == 0x00) {
        //0x00:20KHz阻抗
        //右手
        baseModel.z20KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
        //左手
        baseModel.z20KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
        //躯干
        baseModel.z20KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(2 * len, 3 * len));
        //右脚
        baseModel.z20KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(3 * len, 4 * len));
        //左脚
        baseModel.z20KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(4 * len, 5 * len));
      } else {
        //0x01:100KHz阻抗
        //右手
        baseModel.z100KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
        //左手
        baseModel.z100KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
        //躯干
        baseModel.z100KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(2 * len, 3 * len));
        //右脚
        baseModel.z100KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(3 * len, 4 * len));
        //左脚
        baseModel.z100KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(4 * len, 5 * len));
      }
    }
  }

  analyticalImpedanceDF(receiveData: Uint8Array, baseModel: PPBodyBaseModel | null) {
    if (baseModel) {
      const impedanceData = receiveData.subarray(2);
      const len = 4;
      if (receiveData[2] == 0x00) {
        if (receiveData[3] == 0x00) {
          //0x00:20KHz阻抗
          //右手
          baseModel.z20KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
          //左手
          baseModel.z20KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
          //躯干
          baseModel.z20KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(2 * len, 3 * len));
        } else {
          //0x01:100KHz阻抗
          //右手
          baseModel.z100KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
          //左手
          baseModel.z100KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
          //躯干
          baseModel.z100KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(2 * len, 3 * len));
        }
      } else {
        if (receiveData[3] == 0x00) {
          //0x00:20KHz阻抗
          //右脚
          baseModel.z20KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
          //左脚
          baseModel.z20KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
        } else {
          //0x01:100KHz阻抗
          //右脚
          baseModel.z100KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(0, len));
          //左脚
          baseModel.z100KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(len, 2 * len));
        }
      }
    }
  }

  analyticalCF(data: Uint8Array, bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null, dataChangeListener?: PPDataChangeListener) {
    //1、CF......01//动态数据
    //2、CF.....00//锁定数据,没有阻抗，没有心率 至此，测量结束

    //1、CF......01//动态数据
    //2、CF......05//锁定数据,没有心率
    //3、BF 00 ....... //20KHZ阻抗
    //4、BF 01 ........//100KHZ阻抗
    //5、CF ......00  //至此，测量结束

    //1、CF......01//动态数据
    //2、CF..80....05//锁定数据,心率待测
    //3、BF 00 ....... //20KHZ阻抗
    //4、BF 01 ........//100KHZ阻抗
    //5、CF xx c0......00  //心率。至此，测量结束
    // 2. 过滤重复数据（2.5秒内相同数据视为重复）
    if (this.lastReceiveData === data && Date.now() - this.lastTimes < 2500) {
      return;
    }
    if (!bodyBaseModel) {
      return;
    }
    this.lastTimes = Date.now();
    this.lastReceiveData = data;

    // Get unit type from bytes
    const unitType = ProtocolNormalDeviceHelper.getPpUnitType(data, deviceModel);

    // Get weight values
    const weightKgInt = ProtocolNormalDeviceHelper.getWeightG(data);

    // Get signLocked (byte 9 - original substring(18,20))
    const signLocked = data[9];
    let finalImpedance = 0;

    if (signLocked === 0xA0) {
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
    let scaleState = bodyBaseModel?.scaleState ?? new PPScaleState();
    bodyBaseModel.scaleState = scaleState;

    if (signLocked === 0x01) {
      bodyBaseModel.weight = weightKgInt;
      // Process data
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel ?? null);
    } else if (signLocked === 0x02) {
      bodyBaseModel.isOverload = true;
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
    } else if (signLocked === 0x05) {
      //锁定数据+阻抗(发BF)
      if ((data[2] & 0x80) === 0x80) {
        scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_NO_MEASURE
        bodyBaseModel.scaleState = scaleState;
        //心率测量中
        dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
      }
      bodyBaseModel.weight = weightKgInt;
    } else if (signLocked === 0x06) {
      //锁定数据+阻抗测试失败
    } else if (signLocked === 0x08) {
      //阻抗测量中
      scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_MEASURING;
      bodyBaseModel.scaleState = scaleState;
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
    } else if (signLocked === 0x00) {
      //表示锁定数据/心率；测量结束
      if ((data[2] & 0xC0) === 0xC0) {
        bodyBaseModel.heartRate = data[1];
      } else {
        bodyBaseModel.weight = weightKgInt;
      }
      bodyBaseModel.isHeartRating = false;

      dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel);
    }
  }

  configWifiFail(data: Uint8Array, bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null) {

    switch (data[data.length -1]) {
      case 1:

        break;

    }


  }

  analyticalCE(data: Uint8Array, bodyBaseModel: PPBodyBaseModel | null, deviceModel: PPDeviceModel | null, dataChangeListener?: PPDataChangeListener) {
    // 2. 过滤重复数据（2.5秒内相同数据视为重复）
    if (this.lastReceiveData === data && Date.now() - this.lastTimes < 2500) {
      return;
    }
    if (!bodyBaseModel) {
      return;
    }
    this.lastTimes = Date.now();
    this.lastReceiveData = data;

    // Get unit type from bytes
    const unitType = ProtocolNormalDeviceHelper.getPpUnitType(data, deviceModel);

    // Get weight values
    const weightKgInt = ProtocolNormalDeviceHelper.getWeightG(data);

    // Get signLocked (byte 9 - original substring(18,20))
    const signLocked = data[9];
    let finalImpedance = 0;

    if (signLocked === 0xA0) {
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
    let scaleState = bodyBaseModel?.scaleState ?? new PPScaleState();
    bodyBaseModel.scaleState = scaleState;
    if (signLocked === 0x01) {
      bodyBaseModel.weight = weightKgInt;
      // Process data
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel ?? null);
    } else if (signLocked === 0x02) {
      this.dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
    } else if (signLocked === 0x05) {
      //锁定数据+阻抗(发BF)
      if ((data[2] & 0x80) === 0x80) {
        scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_MEASURING;
        bodyBaseModel.scaleState = scaleState;
        //心率测量中
        dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
      }
      bodyBaseModel.weight = weightKgInt;
    } else if (signLocked === 0x06) {
      //锁定数据+阻抗测试失败
    } else if (signLocked === 0x08) {
      //阻抗测量中
      scaleState.impedanceType = PPScaleStateImpedanceType.IMPEDANCE_MEASURING;
      bodyBaseModel.scaleState = scaleState;
      dataChangeListener?.monitorProcessData?.(bodyBaseModel, deviceModel);
    } else if (signLocked === 0x00) {
      //表示锁定数据/心率；测量结束
      if ((data[2] & 0xC0) === 0xC0) {
        bodyBaseModel.heartRate = data[1];
      } else {
        bodyBaseModel.weight = weightKgInt;
      }
      scaleState.heartRateType = PPScaleStateHeartRateType.HEARTRATE_SUCCESS
      bodyBaseModel.scaleState = scaleState;

      dataChangeListener?.monitorLockData?.(bodyBaseModel, deviceModel);
    }
  }


  processHistoryData(receiveData: Uint8Array, historyData: Uint8Array) {
    const historyAllLen = historyData.length;
    const historyItemLen = 50;
    const arrLen = historyAllLen / historyItemLen
    if (arrLen > 0) {
      for (let i = 0; i < arrLen; i++) {
        const itemHex = historyData.subarray(i * historyItemLen, (i + 1) * historyItemLen)
        this.historyItem(itemHex);
      }
    } else {
    }
    this.historyDataInterface?.monitorHistoryEnd?.();
  }


  historyItem(itemData: Uint8Array) {

    const weightInt = TorreHelper.getWeightG(itemData.subarray(0, 2))

    const time = ProtocolNormalDeviceHelper.getV4Clock(itemData, 2)
    if (time < TorreHelper.ABNORMAL_HISTORY_INTERVAL_TIME_TORRE) {
      return;
    }

    let heartRateHex = itemData[9]
    if (heartRateHex !== 0x00 && heartRateHex !== 0xFF) {
      heartRateHex = 0;
    }

    const bodyBaseModel = new PPBodyBaseModel();
    const userModel = new PPUserModel();
    bodyBaseModel.weight = weightInt;
    bodyBaseModel.heartRate = heartRateHex;
    bodyBaseModel.measureTime = time * 1000;
    bodyBaseModel.userModel = userModel;
    bodyBaseModel.isHeartRating = false;

    //八电极设备 20kHz密文阻抗[4byte]  100kHz密文阻抗[4byte]
    //指定部位阻抗值 数据起始为最低位到高位：
    //如：0x03 (bit1 | bit0) ， 数据组成为：右手20KHz密文阻抗 + 右手100KHz密文阻抗 + 左手20KHz密文阻抗 + 左手100KHz密文阻抗

    const impedanceData = itemData.subarray(10);

    PPLogger.d("syncHistory item 8电极 impedanceData : " + HexUtil.formatHexString(impedanceData));

    const len = 4;

    let offset = 0;

    // 右手 (20KHz和100KHz)
    bodyBaseModel.z20KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;
    bodyBaseModel.z100KhzRightArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;

    // 左手
    bodyBaseModel.z20KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;
    bodyBaseModel.z100KhzLeftArmEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;

    // 躯干
    bodyBaseModel.z20KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;
    bodyBaseModel.z100KhzTrunkEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;

    // 右脚
    bodyBaseModel.z20KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;
    bodyBaseModel.z100KhzRightLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;

    // 左脚
    bodyBaseModel.z20KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));
    offset += len;
    bodyBaseModel.z100KhzLeftLegEnCode = TorreHelper.getImpedance(impedanceData.subarray(offset, offset + len));

    this.historyDataInterface?.monitorHistoryData?.(bodyBaseModel);

  }

  processWifiList(receiveData: Uint8Array, cacheReceiveData: Uint8Array) {
    if (receiveData[1] == 0x00) {
      PPLogger.d(`PPWifiSyncCmd.processWifiList receiveData: ${HexUtil.formatHexString(receiveData)}`);

      const dataArray = PPTorreWifiSyncCmd.splitByNullByte(cacheReceiveData);

      const wifiModels: PPWifiModel[] = [];

      for (const data of dataArray) {
        PPLogger.d(`PPWifiSyncCmd.processWifiList ssidHex: ${HexUtil.formatHexString(data)}`);
        try {
          // 1. 解析sign（前2个字节）
          const sign = data[0];

          // 2. 截取SSID部分（从18字节开始）
          const ssidBytes = data.subarray(18);

          // 3. 字节转字符串
          const ssid = ByteUtil.uint8ArrayToString(ssidBytes);

          // 4. 构建模型
          const wifiModel = new PPWifiModel();
          wifiModel.ssid = ssid;
          wifiModel.sign = sign;
          wifiModels.push(wifiModel);

          PPLogger.i(`Parsed WiFi: SSID=${ssid}, sign=${sign}`);
        } catch (e) {
          PPLogger.e(`Error parsing WiFi data: ${e}`);
        }
      }
      PPLogger.d(`PPWifiSyncCmd.processWifiList wifiModels: ${JSON.stringify(wifiModels)}`);
      this.monitorWiFiListCallBack?.(wifiModels, 0);
    } else if (receiveData[1] == 0x01) { //WiFi列表失败返回
      this.monitorWiFiListCallBack?.(null, 1);
    } else if (receiveData[1] == 0x02) {
      this.monitorWiFiListCallBack?.(null, 2);
    }

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
      if (this.onWifiInfoCallBack) {
        this.onWifiInfoCallBack?.(ssid);
      }
    }
  }

  pushReceiveData(newData: Uint8Array) {
    // 创建新数组并拷贝旧数据 + 新数据
    const mergedData = new Uint8Array(this.cacheReceiveData.length + newData.length);
    mergedData.set(this.cacheReceiveData, 0);
    mergedData.set(newData, this.cacheReceiveData.length);
    // 更新累积数据
    this.cacheReceiveData = mergedData;
  }
}