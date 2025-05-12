import { PPBleFFF2ErrorCode } from "../../enums/PPBleFFF2ErrorCode";
import { PPLogger } from "../../log/PPLogger";
import { PPDeviceModel } from "../../vo/PPDeviceModel";

import { PPBleDfuCmd } from "../dfu/PPBleDfuCmd";
import { ByteUtil } from "../../utils/ByteUtil";

import HexUtil from "../../utils/HexUtil";
import { TorreHelper } from "../torre/TorreHelper";
import PPLogSyncCmd from "../torre/log/PPLogSyncCmd";
import { PPHistorySyncCmd } from "../torre/history/PPHistorySyncCmd";
import { PPTorreWifiSyncCmd } from "../torre/wifi/PPTorreWifiSyncCmd";
import { PPUserInfoSyncCmd } from "../torre/userinfo/PPUserInfoSyncCmd";


export class PPIceDeviceDataAnalysisExtF2 {
  // 回调函数类型定义
  bleRequestLogCallBack?: (error: PPBleFFF2ErrorCode, logData: string, progress: number, isComplete: boolean) => void;
  fetchLogSizeAndStartAddressCallBack?: (error: PPBleFFF2ErrorCode) => void;
  queryDfuProtocolVersionCallBack?: (result: Object) => void;
  queryDFUStateCallBack?: (result: Object) => void;
  startDfuDataTransferCallBack?: (result: Object) => void;
  onBleDfuWaitChunkEndCallBack?: () => void;
  onBleDfuChunkSendErrorCallBack?: (error: PPBleFFF2ErrorCode) => void;
  currentFileDfuEndCallBack?: (result: Object) => void;
  dfuEndCallBack?: (result: Object) => void;
  //7天体重数据
  syncUserSevenWeightInfoConfirmCallBack?: (error: PPBleFFF2ErrorCode) => void;
  syncUserSevenWeightInfoResultCallBack?: (error: PPBleFFF2ErrorCode) => void;
  sendTag: number = TorreHelper.SEND_TAG_NORMAL; //用于区分接收到的数据类型

  cacheReceiveData: Uint8Array = new Uint8Array(0);

  protocolDataF2(data: Uint8Array, deviceModel?: PPDeviceModel | null): void {
    if (data.length === 0) {
      return;
    }
    const sign = data[0];
    switch (sign) {
    /// 分包数据
      case 0x00: {
        PPLogger.v("protocoDataF2--------- receiveData---------  " + ByteUtil.uint8ArrayToHex(data));
        this.cacheData(data)
        break;
      }

    /// log相关
      case 0x01: {
        if (data[2] === 0x01) {
          const result = PPLogSyncCmd.fetchLogSizeAndStartAddressBack(data);
          this.fetchLogSizeAndStartAddressCallBack?.(result);
        } else if (data[2] === 0x03) {
          const result = PPLogSyncCmd.logEndBack(data);
          this.bleRequestLogCallBack?.(result, "", 100, true);
        }
        break;
      }

    //历史数据
      case 0x02: {
        PPHistorySyncCmd.processHistoryData(data, deviceModel)
        break;
      }

    //配网相关
      case 0x03: {
        PPTorreWifiSyncCmd.processConfigWifi(data, this.cacheReceiveData, deviceModel);
        break;
      }

    //Wifi列表
      case 0x04: {
        PPTorreWifiSyncCmd.processWifiList(data, this.cacheReceiveData, deviceModel);
        break;
      }

    //用户数据下发开始
      case 0x05: {
        PPUserInfoSyncCmd.processSyncUserInfo(data, this.cacheReceiveData, deviceModel);
        break;
      }

    //7天数据下发开始
      case 0x0A: {
        this.processSyncUserSevenWeightInfo(data);
        break;
      }

    /// dfu相关
      case 0x0b: {
        if (data[2] === 0x01) {
          const result = PPBleDfuCmd.queryDfuProtocolVersionBack(data);
          PPLogger.d(`PPTorreDeviceDataAnalysis queryDfuProtocolVersionBack result: + ${JSON.stringify(result)}`);
          this.queryDfuProtocolVersionCallBack?.(result);
        } else if (data[2] === 0x02) {
          const result = PPBleDfuCmd.queryDfuStateBack(data);
          PPLogger.d(`PPTorreDeviceDataAnalysis queryDfuStateBack result: ${JSON.stringify(result)}`);
          this.queryDFUStateCallBack?.(result);
        } else if (data[2] === 0x03) {
          const result = PPBleDfuCmd.startDfuDataTransferBack(data);
          PPLogger.d(`PPTorreDeviceDataAnalysis startDfuDataTransferBack result: ${JSON.stringify(result)}`);
          this.startDfuDataTransferCallBack?.(result);
        } else if (data[2] === 0x04) {
          let result = PPBleDfuCmd.dfuDataSliceTransferBack(data);
          if (result === PPBleFFF2ErrorCode.Ok) {
            if (this.onBleDfuWaitChunkEndCallBack) {
              this.onBleDfuWaitChunkEndCallBack();
            }
          } else {
            if (this.onBleDfuChunkSendErrorCallBack) {
              this.onBleDfuChunkSendErrorCallBack(result);
            }
          }
        } else if (data[2] === 0x05) {
          const result = PPBleDfuCmd.currentFileDfuEndBack(data);
          this.currentFileDfuEndCallBack?.(result);
        } else if (data[2] === 0x06) {
          const result = PPBleDfuCmd.dfuEndBack(data);
          this.dfuEndCallBack?.(result);
        }
        break;
      }

      default:
        break;
    }
  }

  /**
   * 数据缓存（ArkTS版）
   * @param receiveData 接收到的数据字符串
   */
  private cacheData(receiveData: Uint8Array): void {
    // 初始化缓冲区
    const dataContent = receiveData.subarray(2); // 公共部分提取

    // 根据标签类型处理数据
    switch (this.sendTag) {
      case TorreHelper.SEND_TAG_LOG:
        // this.bufferList.push(dataContent);
        let result = PPLogSyncCmd.requestLogDataBack(receiveData);
        this.bleRequestLogCallBack?.(PPBleFFF2ErrorCode.Ok, result.get("logData") as string, result.get("progress") as number,
          false
        );
        break;

      case TorreHelper.SEND_TAG_HISTORY:
      case TorreHelper.SEND_TAG_WIFI_LIST:
      case TorreHelper.SEND_TAG_INDEX_ACQUISITION:
      case TorreHelper.SEND_TAG_USER_LIST:
      case TorreHelper.SEND_TAG_CONFIG_WIFI_INFO:
      case TorreHelper.SEND_TAG_ALL_HISTORY:
        this.pushReceiveData(dataContent)
        break;

      case TorreHelper.SEND_TAG_USER_HISTORY:
        PPLogger.d(`历史数据原始数据：receiveData：${HexUtil.formatHexString(receiveData)}`);
        PPHistorySyncCmd.pushReceiveData(dataContent);
        break;

      default:
        break;
    }
  }

  processSyncUserSevenWeightInfo(receiveData: Uint8Array) {
    if (receiveData[2] == 0x01) {
      if (receiveData[3] == 0x00) {
        PPLogger.d("processSyncUserSevenWeightInfo 开始用户下发7天体重信息确认成功");
        this.syncUserSevenWeightInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Ok);
      } else if (receiveData[3] == 0x01) {
        PPLogger.e("processSyncUserSevenWeightInfo 开始用户下发7天体重信息确认失败");
        this.syncUserSevenWeightInfoConfirmCallBack?.(PPBleFFF2ErrorCode.Unknown);
      }
    } else if (receiveData[2] == 0x02) {
      if (receiveData[3] == 0x00) {
        PPLogger.d("processSyncUserSevenWeightInfo 下发7天体重用户信息成功");
        this.syncUserSevenWeightInfoResultCallBack?.(PPBleFFF2ErrorCode.Ok);
      } else if (receiveData[3] == 0x01) {
        PPLogger.e("processSyncUserSevenWeightInfo 下发7天体重信息失败");
        this.syncUserSevenWeightInfoResultCallBack?.(PPBleFFF2ErrorCode.Unknown);
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
