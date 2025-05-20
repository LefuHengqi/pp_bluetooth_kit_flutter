import { PPUnitType } from "../../enums/PPUnitType";
import { OnOTAStateListener } from "../../listener/OnOTAStateListener";
import { PPLogger } from "../../log/PPLogger";
import { ByteUtil } from "../../utils/ByteUtil";
import HexUtil from "../../utils/HexUtil";
import { UnitUtil } from "../../utils/UnitUtil";
import { PPDeviceModel } from "../../vo/PPDeviceModel";


/**
 * F1协议数据处理扩展
 */
export class PPTorreDeviceDataAnalysisExtF1 {
  public otaStateListener?: OnOTAStateListener;
  // 回调函数定义
  public mtuCallBack?: (mtu: number | null) => void;
  public onLightCallBack?: (light: number) => void;
  public onDeviceUnitCallBack?: (unitType: PPUnitType | null) => void;
  public onDeviceUnitResultCallBack?: (isSuccess: boolean | null) => void;
  public onLightResultCallBack?: (isSuccess: boolean) => void;
  public onControlHeartRateResultCallback?: (isSuccess: boolean) => void;
  public onControlImpedanceResultCallBack?: (isSuccess: boolean) => void;
  public onControlBabyResultCallBack?: (isSuccess: boolean) => void;
  public onImpedanceStateCallBack?: (isOn: boolean) => void;
  public onHeartRateStateCallBack?: (isOn: boolean) => void;
  public onResetStateResultCallBack?: (isSuccess: boolean | null) => void;
  public onConfigWifiStateResultCallback?: (state: number | null) => void;
  public onClearDataResultCallBack?: (isSuccess: boolean) => void;
  public onBindStateResultCallBack?: (isSuccess: boolean) => void;
  public onBindStateCallBack?: (isBinding:boolean) => void;
  public onStartMeasureResultCallBack?: (state: number) => void;
  public onReadDeviceWifiMacCallBack?: (mac: string | null) => void;
  public onDemoModeSwitchResultCallBack?: (isSuccess: boolean | null) => void;
  public onDemoModeSwitchStateCallBack?: (state: number | null) => void;
  public onSetRGBCallBack?: (state: number | null) => void;
  public onSetLanguageCallBack?: (isSuccess: boolean) => void;
  public onGetLanguageCallBack?: (language: number) => void;
  public onGetLanguageListCallBack?: (languages: Array<number>) => void;
  lockWeightKg?: number = 0.0;
  lockImpedance?: number = 0;
  myWeightKgInt?: number = 0;
  myImpedance?: number = 0;
  impedance50?: number = 0;
  impedance100: number = 0;
  heartRate?: number = 0;
  lastReceiveData?: string = "";
  lastReceiveData11?: string = "";

  /**
   * 处理F1协议数据
   * @param data 数据数组
   * @param deviceModel 设备模型
   */
  public protocolDataF1(dataArray: Uint8Array, deviceModel: PPDeviceModel | null): void {
    const receiveData: string = HexUtil.formatHexString(dataArray);
    if (receiveData.length === 0) {
      return;
    }

    const preStr = dataArray[0];
    switch (preStr) {
      case 0x02: // 回复当前支持的MTU[设备->App][FFF1]
        if (dataArray[1] === 0x02) {
          const mtuLen = ByteUtil.hexToTen(receiveData.substring(6, 8) + receiveData.substring(4, 6));
          PPLogger.d(`receive mtu = ${mtuLen}`);
          this.mtuCallBack?.(mtuLen);
        }
        break;

      case 0x03: // 回复设备屏幕亮度结果[设备->App][FFF1]
        if (dataArray[2] === 0x01) {
          // 设置亮度
          this.onLightResultCallBack?.(dataArray[3] === 0x00);
        } else {
          // 获取亮度
          // const lightNum = ByteUtil.hexToTen(receiveData.substring(6, 8));
          this.onLightCallBack?.(dataArray[3]);
        }
        break;

      case 0x04: // 时间数据回复[设备->App][FFF1]
        PPLogger.d(`syncTime receiveData: ${receiveData}`);
        const syncTimeResult = receiveData.substring(4, 6);
        if (syncTimeResult === "00") {
          PPLogger.d("syncTime success");
        } else {
          PPLogger.d(`syncTime fail receiveData: ${receiveData}`);
        }
        break;

      case 0x05: // 回复设置单位结果[设备->App][FFF1]
        if (dataArray[2] === 0x01) {
          // 设置单位
          const syncUnitResult = receiveData.substring(6, 8);
          PPLogger.d(`syncUnit result:${syncUnitResult}`);
          this.onDeviceUnitResultCallBack?.(syncUnitResult === "00");
        } else {
          // 获取单位
          PPLogger.d("getUnit success");
          let ppUnitType = UnitUtil.unitTorre2PPUnit(ByteUtil.hexToTen(receiveData.substring(6, 8)));
          if (this.onDeviceUnitCallBack) {
            this.onDeviceUnitCallBack(ppUnitType);
          }
        }
        break;

      case 0x06: //回复设置心率结果[设备->App][FFF1]
        const heartRateType = receiveData.substring(4, 6);
        if (heartRateType === "01") {
          //设置心率
          const result = receiveData.substring(6, 8);
          this.onControlHeartRateResultCallback?.(result === "00");
        } else {
          //获取心率 0开启，1关闭
          const heartRateState = ByteUtil.hexToTen(receiveData.substring(6, 8));
          this.onHeartRateStateCallBack?.(heartRateState == 0);
        }
        break;

      case 0x07:
        const impedanceType = receiveData.substring(4, 6);
        const impedanceState = receiveData.substring(6, 8);

        if (impedanceType === "01") {
          this.onControlImpedanceResultCallBack?.(impedanceState === "00");
        } else {
          this.onImpedanceStateCallBack?.(impedanceState === "00");
        }
        break;

      case 0x09:
        const resetResult = receiveData.substring(4, 6);
        this.onResetStateResultCallBack?.(resetResult === "00");
        break;

      case 0x10:
        const keepAliveResult = receiveData.substring(4, 6);
        if (keepAliveResult === "00") {
          PPLogger.d(`keepAlive keepAliveResult Success code : ${keepAliveResult}`);
        } else {
          PPLogger.d(`keepAlive keepAliveResult Error code : ${keepAliveResult}`);
        }
        break;

      case 0x0B:
        const localOtaResult = receiveData.substring(4, 6);
        if (this.otaStateListener != null) {
          if (localOtaResult === "00") {
            this.otaStateListener?.onStartUpdate?.();
          } else if (localOtaResult === "01") {
            this.otaStateListener?.onUpdateFail?.(0);
          }
        }
        break;

      case 0x0E: // 获取设备配网状态回复
        const stateHex = receiveData.substring(6, 8);
        this.onConfigWifiStateResultCallback?.(ByteUtil.hexToTen(stateHex));
        break;

      case 0x0F:
        const otaResult = receiveData.substring(4, 6);
        if (this.otaStateListener != null) {
          if (otaResult === "00") {
            this.otaStateListener?.onStartUpdate?.();
          } else if (otaResult === "01") {
            this.otaStateListener?.onUpdateFail?.(1);
          } else if (otaResult === "02") {
            this.otaStateListener?.onUpdateFail?.(2);
          } else {
            this.otaStateListener?.onUpdateFail?.(ByteUtil.hexToTen(otaResult));
          }
        }
        break;

      case 0x16: //清除设备数据结果[设备->App][FFF1]
        const clearDataResult = receiveData.substring(4, 6);
        this.onClearDataResultCallBack?.(clearDataResult === "00");
        break;

      case 0x1C: // 设备绑定状态
        const bindStateType = receiveData.substring(4, 6);
        const bindStateResult = receiveData.substring(6, 8);
        PPLogger.d(`DeviceBindState 设备绑定状态：${bindStateType} bindStateResult:${bindStateResult}`);
        if (bindStateType === "01") {
          this.onBindStateResultCallBack?.(bindStateResult === "00");
        } else {
          this.onBindStateCallBack?.(bindStateResult !== "00");
        }
        break;

      case 0x24: //启动测量结果[设备->App][FFF1]
        const startMeasure = receiveData.substring(4, 6);
        PPLogger.d(`startMeasure 启动测量结果：${startMeasure}`);
        this.onStartMeasureResultCallBack?.(ByteUtil.hexToTen(startMeasure));
        break;

      case 0x27:
        const wifiMac = receiveData.substring(4);
        let wifiMacBuffer = "";
        for (let i = 0; i < wifiMac.length; i += 2) {
          wifiMacBuffer += wifiMac.substring(i, i + 2);
          if (i !== wifiMac.length - 2) {
            wifiMacBuffer += ":";
          }
        }
        this.onReadDeviceWifiMacCallBack?.(wifiMacBuffer);
        break;

      case 0x2C: //阻抗开关
        const impedanceType2 = receiveData.substring(4, 6);
        if (impedanceType2 === "00") {
          PPLogger.d("controlImpedance 阻抗设置开关：类型错误");
        } else if (impedanceType2 === "01") {
          const impedanceState = receiveData.substring(6, 8);
          PPLogger.d(`controlImpedance 阻抗设置开关：${impedanceState}`);
          this.onControlImpedanceResultCallBack?.(impedanceState === "00");
        } else {
          const impedanceState = receiveData.substring(6, 8);
          PPLogger.d(`controlImpedance 获取阻抗开关：${impedanceState}`);
          this.onImpedanceStateCallBack?.(impedanceState === "00");
        }
        break;

      case 0x2E: //婴儿模式设置和获取
        if (dataArray[2] === 0x00) {
          const babyModelResult = dataArray[3];
          PPLogger.d(`controlBaby 婴儿模式启动：${babyModelResult}`);
          this.onControlBabyResultCallBack?.(babyModelResult === 0x00);
        } else {
          const babyModelState = dataArray[3];
          PPLogger.d(`controlImpedance 获取婴儿模式：${babyModelState}`);
          this.onControlBabyResultCallBack?.(babyModelState === 0x00);
        }
        break;

      case 0x31:
        const demoModeType = receiveData.substring(4, 6);
        const demoModeState2 = receiveData.substring(6, 8);
        if (demoModeType === "01") {
          PPLogger.d(`demoMode 设置演示模式状态：${demoModeState2}`);
          this.onDemoModeSwitchResultCallBack?.(demoModeState2 === "00");
        } else {
          PPLogger.d(`demoMode 获取演示模式状态：${demoModeState2}`);
          this.onDemoModeSwitchStateCallBack?.(demoModeState2 === "00" ? 0 : 1);
        }
        break;

      case 0x39: // 回复设置RGB显示模式[设备 ->APP]
        const rgbBack = receiveData.substring(4, 6);
        PPLogger.d(`rgbBack 设置RGB显示模式：rgbBack:${rgbBack}`);
        this.onSetRGBCallBack?.(rgbBack === "00" ? 0 : 1);
        break;

      case 0x42:
        if (receiveData.substring(4, 6) === "01") {
          // 设置语言
          const languageResult = receiveData.substring(6, 8);
          PPLogger.d(`语言设置languageResult：${languageResult}`);
          this.onSetLanguageCallBack?.(languageResult === "00");
        } else {
          // 获取语言
          const lightNum = parseInt(receiveData.substring(6, 8), 16);
          if (receiveData.substring(4, 6) === "02") {
            // 获取当前语言
            PPLogger.d(`获取当前设备语言lightNum：${lightNum}`);
            this.onGetLanguageCallBack?.(lightNum);
          } else {
            // 获取所有语言
            const supportedLanguages: number[] = [];
            if ((lightNum & 0x01) === 0x01) {
              supportedLanguages.push(0);
            }
            if ((lightNum & 0x02) === 0x02) {
              supportedLanguages.push(1);
            }
            if ((lightNum & 0x04) === 0x04) {
              supportedLanguages.push(2);
            }
            if ((lightNum & 0x08) === 0x08) {
              supportedLanguages.push(3);
            }
            if ((lightNum & 0x10) === 0x10) {
              supportedLanguages.push(4);
            }
            if ((lightNum & 0x20) === 0x20) {
              supportedLanguages.push(5);
            }
            if ((lightNum & 0x40) === 0x40) {
              supportedLanguages.push(6);
            }
            if ((lightNum & 0x80) === 0x80) {
              supportedLanguages.push(7);
            }
            supportedLanguages.forEach((lang) => {
              PPLogger.d(`获取设备语言列表是：${lang}`);
            });
            this.onGetLanguageListCallBack?.(supportedLanguages);
          }
        }
        break;

      default:
        break;
    }
  }
}