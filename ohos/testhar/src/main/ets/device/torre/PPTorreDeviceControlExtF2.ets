import { PPBleFFF2ErrorCode } from "../../enums/PPBleFFF2ErrorCode";
import { ble } from "@kit.ConnectivityKit";
import { PPLogger } from "../../log/PPLogger";
import PPLogSyncCmd from "./log/PPLogSyncCmd";
import { ByteUtil } from "../../utils/ByteUtil";
import { BusinessError } from "@kit.BasicServicesKit";
import { PPTorreDeviceDataAnalysisExtF2 } from "./PPTorreDeviceDataAnalysisExtF2";
import { PPTorreWifiSyncCmd } from "./wifi/PPTorreWifiSyncCmd";
import { PPConfigWifiStateMenu } from "../../enums/PPConfigWifiStateMenu";
import { PPDeviceModel } from "../../vo/PPDeviceModel";
import { PPWifiModel } from "../../vo/PPWifiModel";
import { PPUserModel } from "../../vo/PPUserModel";
import { PPHistoryDataInterface } from "../../listener/PPHistoryDataInterface";
import { PPHistorySyncCmd } from "./history/PPHistorySyncCmd";
import { PPUserInfoSyncCmd } from "./userinfo/PPUserInfoSyncCmd";


enum PPBleDfuFileType {
  ble = 0x01,
  mcu = 0x02,
  wifi = 0x03,
  res = 0x04
}

export class PPTorreDeviceControlExtF2 {
  characteristicFFF2: ble.BLECharacteristic | null = null;
  gattClient?: ble.GattClientDevice | null
  deviceDataAnalysis: PPTorreDeviceDataAnalysisExtF2 | null = null; // 保持原始类型

  deviceLogInterface: VideoInterface | null = null;
  deviceModel: PPDeviceModel | null = null;

  // 保持原始方法名和参数
  async fetchLog(onProgress?: (progress: number, logStr: string) => void): Promise<boolean> {
    try {
      PPLogger.d("PPTorreDeviceControlExtF2 获取Log大小和开始地址");
      const cmd1 = PPLogSyncCmd.fetchLogSizeAndStartAddress();
      if (!this.deviceDataAnalysis) {
        PPLogger.e("PPTorreDeviceControlExtF2 fetchLog deviceDataAnalysis is null");
        return false;
      }
      const step1Result = await this._writeResponseBytesF2WaitResult(new Uint8Array(cmd1),
        {
          operationName: 'fetchLogSizeAndStartAddress',
          setCallback: (callback) => this.deviceDataAnalysis!!.fetchLogSizeAndStartAddressCallBack = callback,
          timeoutMs: 15000
        });
      if (step1Result !== PPBleFFF2ErrorCode.Ok) {
        return false;
      }
      PPLogger.d("PPTorreDeviceControlExtF2 请求Log原始数据");
      const step2Result = await this.requestLogWithProgress(onProgress);
      if (step2Result !== PPBleFFF2ErrorCode.Ok) {
        return false;
      }
      PPLogger.d("PPTorreDeviceControlExtF2 Log数据发送结束");
      const cmd3 = PPLogSyncCmd.logEnd();
      return await this._writeResponseBytesF2(new Uint8Array(cmd3));
    } catch (err) {
      PPLogger.e(`PPTorreDeviceControlExtF2 fetchLog error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  async requestLogWithProgress(onProgress?: (progress: number,
    log: string) => void): Promise<PPBleFFF2ErrorCode> {
    if (!this.deviceDataAnalysis) {
      return PPBleFFF2ErrorCode.Unknown
    }
    // 1. 创建Promise控制器
    let resolvePromise: () => void = () => {
    }; // 初始化为空函数
    const completionPromise = new Promise<void>((resolve) => {
      resolvePromise = resolve;
    });
    //2. 设置超时（默认30秒）
    const timeoutMs = 30000;
    let timeoutId: number = setTimeout(() => {
      PPLogger.e('PPTorreDeviceControlExtF2  获取日志超时')
      resolvePromise(); // 超时后仍然resolve避免永久阻塞
      return PPBleFFF2ErrorCode.Timeout;
    }, timeoutMs);
    try {
      let endResult = false
      // 3. 注册回调（确保单次绑定）
      this.deviceDataAnalysis.bleRequestLogCallBack = (
        errorCode: PPBleFFF2ErrorCode,
        logStr: string,
        progress: number,
        isEnd: boolean
      ) => {
        PPLogger.v(`PPTorreDeviceControlExtF2  progress: ${progress}, isEnd: ${isEnd}, logStr: ${logStr}, errorCode: ${errorCode}`);
        // 实时进度回调
        onProgress?.(progress, logStr);
        if (timeoutId != 0) {
          clearTimeout(timeoutId); // 取消超时检测
          timeoutId = 0;
          PPLogger.d("PPTorreDeviceControlExtF2 取消超时检测");
        }
        endResult = isEnd
        // 收到结束标记时
        if (isEnd) {
          PPLogger.d('PPTorreDeviceControlExtF2 收到结束标记时，释放同步锁')
          resolvePromise(); // 释放同步锁
        } else if (errorCode !== PPBleFFF2ErrorCode.Ok) {
          resolvePromise(); // 释放同步锁
        }
      };

      // 4. 发送请求命令
      const cmd = PPLogSyncCmd.requestLogData();
      const writeSuccess = await this._writeResponseBytesF2(new Uint8Array(cmd));
      if (!writeSuccess) {
        PPLogger.e("PPTorreDeviceControlExtF2 写入命令失败");
        return PPBleFFF2ErrorCode.Unknown;
      }
      // 5. 等待日志传输完成（同步点）
      await completionPromise;

      if (endResult) {
        return PPBleFFF2ErrorCode.Ok
      } else {
        return PPBleFFF2ErrorCode.Unknown
      }
    } catch (error) {
      PPLogger.e(`请求日志失败: ${error}`);
      return PPBleFFF2ErrorCode.Unknown
    } finally {
      // 6. 清理资源
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      this.deviceDataAnalysis.bleRequestLogCallBack = undefined; // 移除回调
      return PPBleFFF2ErrorCode.Unknown
    }
  }

  async exitConfigWifi(): Promise<boolean> {
    const exitConfigWifiCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.exitConfigWifiCmd(),
      {
        operationName: 'exitConfigWifiCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiConfirmStartCallBack = callback,
        timeoutMs: 15000
      });
    if (exitConfigWifiCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    return true;
  }

  async getWifiSSID(readDeviceSsidCallBack?: (ssid: string) => void) {
    PPLogger.d("PPTorreDeviceControlExtF2 getWifiList start");
    PPTorreWifiSyncCmd.readDeviceSsidCallBack = readDeviceSsidCallBack;
    const getWifiSSIDCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.getWifiSSIDCmd(),
      {
        operationName: 'getWifiSSIDCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.confirmGetWifiInfoEndCallBack = callback,
        timeoutMs: 15000
      });
    if (getWifiSSIDCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 getWifiSSIDCmd success");
    return await this._writeResponseBytesF2(PPTorreWifiSyncCmd.confirmWifiSSIDEndCmd());
  }

  async getWifiList(monitorWiFiListCallBack?: (wifiModels: PPWifiModel[] | null) => void): Promise<boolean> {
    PPLogger.d("PPTorreDeviceControlExtF2 getWifiList start");
    PPTorreWifiSyncCmd.monitorWiFiListCallBack = monitorWiFiListCallBack;
    const getWifiListCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.getWifiListCmd(),
      {
        operationName: 'getWifiListCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.wifiListEndCallBack = callback,
        timeoutMs: 15000
      });
    if (getWifiListCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 getWifiList success");
    return await this._writeResponseBytesF2(PPTorreWifiSyncCmd.confirmWifiListEndCmd());
  }

  async configWifi(domainName: string, ssid: string, password: string,
    configWifiResultCallBack?: (configState: PPConfigWifiStateMenu, resultCode: string) => void): Promise<boolean> {

    PPLogger.d(`PPTorreDeviceControlExtF2 configWifi ssid: ${ssid}, password: ${password}, domainName: ${domainName}`);

    PPTorreWifiSyncCmd.configWifiResultCallBack = configWifiResultCallBack;

    const startConfigCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.startConfigCmd(),
      {
        operationName: 'fetchLogSizeAndStartAddress',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiConfirmStartCallBack = callback,
        timeoutMs: 15000
      });
    if (startConfigCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi start success");
    const domainNameStartCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.domainNameStartCmd(domainName),
      {
        operationName: 'domainNameStartCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiConfirmSendDataCallBack = callback,
        timeoutMs: 3000
      });
    if (domainNameStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      PPLogger.e("PPTorreDeviceControlExtF2 configWifi domain start error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi start send domain data");
    const domainNameCmdResult = await this._writeResponseBytesF2List(PPTorreWifiSyncCmd.domainNameCmd(this.deviceModel?.mtu ?? 20));

    if (domainNameCmdResult == false) {
      PPLogger.d("PPTorreDeviceControlExtF2 configWifi send domain data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi send domain data success");

    const sendDomainDataEndCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.sendDataEndCmd(),
      {
        operationName: 'domainNameEndCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiDomainResultCallBack = callback,
        timeoutMs: 5000
      });
    if (sendDomainDataEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi domain success");
    const ssidStartCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.ssidStartCmd(ssid),
      {
        operationName: 'ssidStartCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiConfirmSendDataCallBack = callback,
        timeoutMs: 3000
      });
    if (ssidStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi start send ssid data");
    const ssidCmdResult = await this._writeResponseBytesF2List(PPTorreWifiSyncCmd.ssidCmd(this.deviceModel?.mtu ?? 20));
    if (!ssidCmdResult) {
      PPLogger.e("PPTorreDeviceControlExtF2 configWifi send ssid data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi send ssid data success");
    const sendSSIDDataEndCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.sendDataEndCmd(),
      {
        operationName: 'ssidNameEndCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiSSIDResultCallBack = callback,
        timeoutMs: 5000
      });
    if (sendSSIDDataEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi ssid success");

    const pwdStartCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.pwdStartCmd(password),
      {
        operationName: 'pwdStartCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiConfirmSendDataCallBack = callback,
        timeoutMs: 3000
      });
    if (pwdStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi start send pwd data");
    const pwdCmdResult = await this._writeResponseBytesF2List(PPTorreWifiSyncCmd.pwdCmd(this.deviceModel?.mtu ?? 20));
    if (!pwdCmdResult) {
      PPLogger.e("PPTorreDeviceControlExtF2 configWifi send pwd data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi send pwd data success");
    const sendPwdDataEndCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.sendDataEndCmd(),
      {
        operationName: 'pwdNameEndCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiPwdResultCallBack = callback,
        timeoutMs: 5000
      });
    if (sendPwdDataEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 configWifi pwd success");

    const registerToServerCmdResult = await this._writeResponseBytesF2WaitResult(PPTorreWifiSyncCmd.registerToServerCmd(),
      {
        operationName: 'confirmCmd',
        setCallback: (callback) => PPTorreWifiSyncCmd.configWifiRegisterResultCallBack = callback,
        timeoutMs: 3000
      });
    if (registerToServerCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    return true;

  }

  async syncUserHistory(userModel: PPUserModel, historyDataInterface: PPHistoryDataInterface | null): Promise<boolean> {

    PPLogger.d(`PPTorreDeviceControlExtF2 syncUserHistory username: ${userModel.userName}, userId: ${userModel.userID}, memberId: ${userModel.memberID}`);

    PPHistorySyncCmd.historyDataInterface = historyDataInterface;

    const syncUserHistoryStartCmdResult = await this._writeResponseBytesF2WaitResult(PPHistorySyncCmd.syncUserHistoryStartCmd(userModel.userID ?? ""),
      {
        operationName: 'syncUserHistoryStartCmd',
        setCallback: (callback) => PPHistorySyncCmd.historyStartSendUserInfoCallBack = callback,
        timeoutMs: 5000
      });
    if (syncUserHistoryStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory start send userid data");
    const syncUserHistoryToUserInfoCmdResult = await this._writeResponseBytesF2List(PPHistorySyncCmd.syncUserHistoryToUserInfoCmd(this.deviceModel?.mtu ?? 20));

    if (!syncUserHistoryToUserInfoCmdResult) {
      PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory send userid data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory send userid data success");

    const syncUserHistoryToUserInfoEndCmdResult = await this._writeResponseBytesF2WaitResult(PPHistorySyncCmd.syncUserHistoryToUserInfoEndCmd(),
      {
        operationName: 'syncUserHistoryToUserInfoEndCmd',
        setCallback: (callback) => PPHistorySyncCmd.historySendUserInfoEndCallBack = callback,
        timeoutMs: 5000
      });
    if (syncUserHistoryToUserInfoEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory userid success");

    const syncHistoryCmdResult = await this._writeResponseBytesF2WaitResult(PPHistorySyncCmd.syncUserHistoryCmd(),
      {
        operationName: 'syncUserHistoryCmd',
        setCallback: (callback) => PPHistorySyncCmd.bleRequestHistoryEndCallBack = callback,
        timeoutMs: 5000
      });
    if (syncHistoryCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory domain success");
    return true;
  }


  async syncUserInfo(userModel:PPUserModel): Promise<boolean> {

    PPLogger.d(`PPTorreDeviceControlExtF2 syncUserInfo username: ${userModel.userName}, userId: ${userModel.userID}, memberId: ${userModel.memberID}`);

    const syncUserInfoStartCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.syncUserInfoStartCmd(userModel, this.deviceModel),
      {
        operationName: 'syncUserInfoStartCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.syncUserInfoConfirmCallBack = callback,
        timeoutMs: 5000
      });
    if (syncUserInfoStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory start send UserInfo data");

    const syncUserInfoCmdResult = await this._writeResponseBytesF2List(await PPUserInfoSyncCmd.syncUserInfoCmd(this.deviceModel?.mtu ?? 20));

    if (!syncUserInfoCmdResult) {
      PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory send UserInfo data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory send UserInfo data success");

    const setUserInfoEndCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.setUserInfoEndCmd(),
      {
        operationName: 'domainNameEndCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.syncUserInfoResultCallBack = callback,
        timeoutMs: 5000
      });
    if (setUserInfoEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserInfo  success");

    return true;
  }


  /**
   * 根据UserId删除该UserId下所有用户
   * @param userModel
   * @returns
   */
  async deleteUserInfo(userModel:PPUserModel): Promise<boolean> {

    PPLogger.d(`PPTorreDeviceControlExtF2 deleteUserInfo userId: ${userModel.userID}`);

    const deleteAllUserInfoStartCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.deleteAllUserInfoStartCmd(userModel),
      {
        operationName: 'deleteAllUserInfoStartCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.delUserInfoConfirmCallBack = callback,
        timeoutMs: 5000
      });
    if (deleteAllUserInfoStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 syncUserHistory start send UserInfo data");

    const deleteAllUserInfoDataCmdResult = await this._writeResponseBytesF2List(PPUserInfoSyncCmd.deleteAllUserInfoDataCmd(this.deviceModel?.mtu ?? 20));

    if (!deleteAllUserInfoDataCmdResult) {
      PPLogger.d("PPTorreDeviceControlExtF2 deleteUserInfo send UserInfo data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 deleteUserInfo send UserInfo data success");

    const deleteAllUserInfoEndCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.deleteAllUserInfoEndCmd(),
      {
        operationName: 'deleteAllUserInfoEndCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.delUserInfoResultCallBack = callback,
        timeoutMs: 5000
      });
    if (deleteAllUserInfoEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 deleteUserInfo  success");

    return true;
  }


  /**
   * 下发当前上秤的用户，该用户必须已经同步给设备
   * @param userModel
   * @returns
   */
  async sendCurrentUserInfo(userModel:PPUserModel): Promise<boolean> {

    PPLogger.d(`PPTorreDeviceControlExtF2 sendCurrentUserinfo userId: ${userModel.userID}`);

    const sendCurrentUserinfoStartCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.sendCurrentUserinfoStartCmd(userModel),
      {
        operationName: 'sendCurrentUserinfoStartCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.confirmCurrentUserInfoConfirmCallBack = callback,
        timeoutMs: 5000
      });
    if (sendCurrentUserinfoStartCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 sendCurrentUserinfo start send UserInfo data");

    const sendCurrentUserinfoDataCmdResult = await this._writeResponseBytesF2List(PPUserInfoSyncCmd.sendCurrentUserinfoDataCmd(this.deviceModel?.mtu ?? 20));

    if (!sendCurrentUserinfoDataCmdResult) {
      PPLogger.d("PPTorreDeviceControlExtF2 sendCurrentUserinfo send UserInfo data error");
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 sendCurrentUserinfo send UserInfo data success");

    const sendCurrentUserinfoEndCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.sendCurrentUserinfoEndCmd(),
      {
        operationName: 'sendCurrentUserinfoEndCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.confirmCurrentUserInfoResultCallBack = callback,
        timeoutMs: 5000
      });
    if (sendCurrentUserinfoEndCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 sendCurrentUserinfo  success");

    return true;
  }

  async getUserList(monitorUserListCallBack?: (userIds: string[]) => void): Promise<boolean> {

    PPUserInfoSyncCmd.monitorUserListCallBack = monitorUserListCallBack;

    const getUserListCmdResult = await this._writeResponseBytesF2WaitResult(PPUserInfoSyncCmd.getUserListCmd(),
      {
        operationName: 'getUserListCmd',
        setCallback: (callback) => PPUserInfoSyncCmd.monitorUserListResultCallBack = callback,
        timeoutMs: 5000
      });
    if (getUserListCmdResult !== PPBleFFF2ErrorCode.Ok) {
      return false;
    }
    PPLogger.d("PPTorreDeviceControlExtF2 getUserList success");

    return true;
  }


  // async bleDfu(
  //   filePath: string,
  //   manualUpgradeList?: PPBleDfuFileType[],
  //   scheduleCallback?: (totalCount: number, currentIndex: number, fileProgress: number, fileType: PPBleDfuFileType) => void
  // ): Promise<PPBleFFF2ErrorCode> {
  //   try {
  //     const firmware = this.deviceModel?.firmwareVersion ?? "";
  //     let bleVer = "9999", mcuVer = "9999", wifiVer = "9999", resVer = "9999";
  //
  //     if (manualUpgradeList) {
  //       bleVer = manualUpgradeList.includes(PPBleDfuFileType.ble) ? "000" : "9999";
  //       mcuVer = manualUpgradeList.includes(PPBleDfuFileType.mcu) ? "000" : "9999";
  //       wifiVer = manualUpgradeList.includes(PPBleDfuFileType.wifi) ? "000" : "9999";
  //       resVer = manualUpgradeList.includes(PPBleDfuFileType.res) ? "000" : "9999";
  //     }
  //
  //     // 保持原始PPBleOtaTool逻辑（需实现）
  //     const otaTool = new PPBleOtaTool(filePath, new PPFirmwareVersionVo
  //       ble: bleVer,
  //       mcu: mcuVer,
  //       wifi: wifiVer,
  //       res: resVer
  //     );
  //     const config = await otaTool.parsePackageJson();
  //     const vos = await otaTool.compareVersions(config?.packages);
  //
  //     const dfuCmd = new PPBleDfuCmd({
  //       packageVos: vos,
  //       platform: /* 根据实际平台设置 */,
  //       mtu: (this.deviceModel?.mtu ?? 244) - 5
  //     });
  //
  //     // 保持原始DFU流程
  //     PPLogger.d("查询DFU协议版本");
  //     const cmd1 = dfuCmd.queryDfuProtocolVersion();
  //     const step1Result = await this._writeResponseBytesF2WaitResult(
  //       cmd1,
  //       "_queryDfuProtocolVersion",
  //       (callback) => this.deviceDataAnalysis.queryDfuProtocolVersionCallBack = callback
  //     );
  //     if (step1Result !== PPBleFFF2ErrorCode.ok) return step1Result;
  //
  //     PPLogger.d("查询DFU状态");
  //     const cmd2 = dfuCmd.queryDFUState();
  //     const step2Result = await this._writeResponseBytesF2WaitResult(
  //       cmd2,
  //       "_queryDFUState",
  //       (callback) => this.deviceDataAnalysis.queryDFUStateCallBack = callback
  //     );
  //     if (step2Result !== PPBleFFF2ErrorCode.ok) return step2Result;
  //
  //     let bleDfuErrorCode = PPBleFFF2ErrorCode.ok;
  //     this.deviceDataAnalysis.onBleDfuChunkSendErrorCallBack = (errorCode: PPBleFFF2ErrorCode) => {
  //       bleDfuErrorCode = errorCode;
  //     };
  //
  //     for (let voIndex = 0; voIndex < vos.length; voIndex++) {
  //       const vo = vos[voIndex];
  //       PPLogger.d(`当前下发的文件类型是:${vo.fileType}`);
  //       scheduleCallback?.(vos.length, voIndex, 0, vo.fileType);
  //
  //       const cmd3 = dfuCmd.startDfuDataTransfer(vo);
  //       const step3Result = await this._writeResponseBytesF2WaitResult(
  //         cmd3,
  //         "_startDfuDataTransfer",
  //         (callback) => this.deviceDataAnalysis.startDfuDataTransferCallBack = callback
  //       );
  //       if (step3Result !== PPBleFFF2ErrorCode.ok) return step3Result;
  //
  //       let packageEnd = false;
  //       let sendIndex = 0;
  //       while (!packageEnd && bleDfuErrorCode === PPBleFFF2ErrorCode.ok) {
  //         const result = dfuCmd.dfuDataDeliver(vo, sendIndex);
  //         await this._writeWithoutResponseBytesF2(result.cmd);
  //         scheduleCallback?.(vos.length, voIndex, result.progress, vo.fileType);
  //
  //         if (result.chunkEnd) {
  //           await this._waitDfuChunkEndNotify();
  //         }
  //         packageEnd = result.packageEnd;
  //         sendIndex++;
  //       }
  //
  //       const cmd5 = dfuCmd.currentFileDfuEnd();
  //       const step5Result = await this._writeResponseBytesF2WaitResult(
  //         cmd5,
  //         "_currentFileDfuEnd",
  //         (callback) => this.deviceDataAnalysis.currentFileDfuEndCallBack = callback
  //       );
  //       if (step5Result !== PPBleFFF2ErrorCode.ok) return step5Result;
  //     }
  //
  //     PPLogger.d("系统DFU流程结束");
  //     const cmd6 = dfuCmd.dfuEnd();
  //     return await this._writeResponseBytesF2WaitResult(
  //       cmd6,
  //       "dfuEnd",
  //       (callback) => this.deviceDataAnalysis.dfuEndCallBack = callback
  //     );
  //   } catch (err) {
  //     PPLogger.e(`bleDfu error: ${JSON.stringify(err)}`);
  //     return PPBleFFF2ErrorCode.unknown;
  //   }
  // }

  private async _writeResponseBytesF2(bytes: Uint8Array): Promise<boolean> {
    try {
      const dataHex = ByteUtil.uint8ArrayToHex(bytes);
      PPLogger.d(`PPTorreDeviceControl write response targetF2 data:${dataHex}`);

      if (!this.characteristicFFF2) {
        PPLogger.e(`PPTorreDeviceControl Characteristic Response FFF2 not initialized`);
        return false;
      }
      let writeFlag: boolean = false;

      let writeValue: ArrayBuffer = ByteUtil.typedArrayToBuffer(bytes);
      this.characteristicFFF2.characteristicValue = writeValue;
      let errorMessage: string = ""
      let errorCode: string = ""
      try {
        await this.gattClient?.writeCharacteristicValue(this.characteristicFFF2, ble.GattWriteType.WRITE)
      } catch (e) {
        errorMessage = e.message;
        errorCode = e.code.toString()
        writeFlag = true;
      }
      if (writeFlag) {
        PPLogger.e(`PPTorreDeviceControl writeCharacteristic errorcde: ${errorCode} ,  errmessage: ${errorMessage}`);
        return false;
      }
      PPLogger.e(`PPTorreDeviceControl _writeResponseBytesF2 Write success`);
      return true;
    } catch (err) {
      PPLogger.e(`PPTorreDeviceControl _writeResponseBytesF2 error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  private async _writeResponseBytesF2List(bytesArray: Uint8Array[]): Promise<boolean> {
    PPLogger.d(`PPTorreDeviceControl _writeResponseBytesF2List ${bytesArray.length}`);
    for (const bytes of bytesArray) {
      const success = await this._writeResponseBytesF2(bytes);
      if (!success) {
        PPLogger.e(`PPTorreDeviceControl _writeResponseBytesF2List Fail`);
        return false;
      }
    }
    PPLogger.e(`PPTorreDeviceControl _writeResponseBytesF2List Success`);
    return true;
  }

  private async _writeWithoutResponseBytesF2(bytes: Uint8Array): Promise<boolean> {
    try {
      if (!this.characteristicFFF2) {
        PPLogger.e(`PPTorreDeviceControl Characteristic no Response FFF2 not initialized`);
        return false;
      }

      let writeFlag: boolean = false;

      PPLogger.d(`write no response targetF2 data:${ByteUtil.uint8ArrayToHex(bytes)}`)

      let writeValue: ArrayBuffer = ByteUtil.typedArrayToBuffer(bytes);
      this.characteristicFFF2.characteristicValue = writeValue;
      let errorMessage: string = ""
      let errorCode: string = ""
      try {
        await this.gattClient?.writeCharacteristicValue(this.characteristicFFF2, ble.GattWriteType.WRITE_NO_RESPONSE)
      } catch (e) {
        errorMessage = e.message;
        errorCode = e.code.toString()
        writeFlag = true;
        PPLogger.e(`_writeResponseBytesF2 error: ${JSON.stringify(e)}`);
      }
      if (writeFlag) {
        PPLogger.e(`PPTorreDeviceControl writeCharacteristic errorcde: ${errorCode} ,  errmessage: ${errorMessage}`);
        return false;
      }
      PPLogger.e(`PPTorreDeviceControl Write without respones success`);
      return true;
    } catch (err) {
      PPLogger.e(`_writeResponseBytesF2 error: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /**
   * 写入数据并等待响应
   * @param bytes 要写入的二进制数据
   * @param options 配置参数
   */
  async _writeResponseBytesF2WaitResult(bytes: Uint8Array, options: WriteOptions): Promise<PPBleFFF2ErrorCode> {
    const operationName = options.operationName;
    const setCallback = options.setCallback;
    const timeoutMs = options.timeoutMs ?? 2000;

    PPLogger.d(`${operationName} 操作开始`);
    // 1. 创建Promise控制器（只需resolve）
    let resolvePromise: (value: PPBleFFF2ErrorCode) => void;
    const operationPromise = new Promise<PPBleFFF2ErrorCode>((resolve) => {
      PPLogger.d(`${operationName} 主控制器返回`)
      resolvePromise = resolve;
    });
    let mErrorCode = PPBleFFF2ErrorCode.Unknown;
    // 2. 设置超时控制
    let timeoutId: number | undefined;
    const timeoutPromise = new Promise<PPBleFFF2ErrorCode>((_, reject) => {
      timeoutId = setTimeout(() => {
        PPLogger.e(`${operationName} 操作超时`);
        reject(new Error(`${operationName} 操作超时`));
        return PPBleFFF2ErrorCode.Timeout;
      }, timeoutMs);
    });

    try {
      // 3. 设置单次回调
      setCallback((errorCode: PPBleFFF2ErrorCode) => {
        PPLogger.d(`${operationName} 操作结束，错误码: ${errorCode}`);
        if (timeoutId) {
          clearTimeout(timeoutId);
          timeoutId = undefined;
        }
        mErrorCode = errorCode
        resolvePromise(errorCode);
      });
      PPLogger.d(`${operationName} 开始写入`)
      // 4. 执行写入
      await this._writeResponseBytesF2(bytes);

      // 5. 等待结果
      await Promise.race([operationPromise, timeoutPromise.catch(() => PPBleFFF2ErrorCode.Timeout)]);

      return mErrorCode;
    } catch (error) {
      PPLogger.e(`${operationName} 写入错误: ${JSON.stringify(error)}`);
      return PPBleFFF2ErrorCode.Unknown;
    } finally {
      // 6. 确保清理资源
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      return mErrorCode;
    }
  }

  /**
   * 写入数据并等待响应
   * @param bytes 要写入的二进制数据
   * @param options 配置参数
   */
  async _writeResponseBytesF2ListWaitResult(bytesArray: Uint8Array[], options: WriteOptions): Promise<PPBleFFF2ErrorCode> {
    const operationName = options.operationName;
    const setCallback = options.setCallback;
    const timeoutMs = options.timeoutMs ?? 2000;

    PPLogger.d(`${operationName} 操作开始`);
    // 1. 创建Promise控制器（只需resolve）
    let resolvePromise: (value: PPBleFFF2ErrorCode) => void;
    const operationPromise = new Promise<PPBleFFF2ErrorCode>((resolve) => {
      PPLogger.d(`${operationName} 主控制器返回`)
      resolvePromise = resolve;
    });
    let mErrorCode = PPBleFFF2ErrorCode.Unknown;
    // 2. 设置超时控制
    let timeoutId: number | undefined;
    const timeoutPromise = new Promise<PPBleFFF2ErrorCode>((_, reject) => {
      timeoutId = setTimeout(() => {
        PPLogger.e(`${operationName} 操作超时`);
        reject(new Error(`${operationName} 操作超时`));
        return PPBleFFF2ErrorCode.Timeout;
      }, timeoutMs);
    });

    try {
      // 3. 设置单次回调
      setCallback((errorCode: PPBleFFF2ErrorCode) => {
        PPLogger.d(`${operationName} 操作结束，错误码: ${errorCode}`);
        if (timeoutId) {
          clearTimeout(timeoutId);
          timeoutId = undefined;
        }
        mErrorCode = errorCode
        resolvePromise(errorCode);
      });
      PPLogger.d(`${operationName} 开始写入`)
      // 4. 执行写入
      await this._writeResponseBytesF2List(bytesArray);

      // 5. 等待结果
      await Promise.race([operationPromise, timeoutPromise.catch(() => PPBleFFF2ErrorCode.Timeout)]);

      return mErrorCode;
    } catch (error) {
      PPLogger.e(`${operationName} 写入错误: ${JSON.stringify(error)}`);
      return PPBleFFF2ErrorCode.Unknown;
    } finally {
      // 6. 确保清理资源
      if (timeoutId) {
        clearTimeout(timeoutId);
      }
      return mErrorCode;
    }
  }

  /**
   * 等待DFU数据块结束通知
   * @param timeoutMs 超时时间(毫秒)，默认2000ms
   */
  async waitDfuChunkEndNotify(timeoutMs: number = 2000): Promise<void> {
    // 1. 创建Promise控制器
    let resolvePromise: () => void = () => {
    }; // 初始化为空函数

    const promise = new Promise<void>((resolve, reject) => {
      resolvePromise = resolve;
    });

    try {
      if (this.deviceDataAnalysis) {
        // 2. 设置回调
        this.deviceDataAnalysis.onBleDfuWaitChunkEndCallBack = () => {
          console.log('收到DFU数据块结束通知');
          resolvePromise(); // 相当于 completer.complete()
        };
      }
      // 3. 设置超时
      const timeoutPromise = new Promise<void>((_, reject) => {
        setTimeout(() => {
          reject(new Error('等待DFU数据块结束通知超时'));
        }, timeoutMs);
      });

      // 4. 等待结果
      return await Promise.race([promise, timeoutPromise]);
    } catch (error) {
      console.error(`等待通知出错: ${(error as BusinessError).message}`);
      // throw error;
    } finally {
      // 5. 清理回调
      if (this.deviceDataAnalysis) {
        this.deviceDataAnalysis.onBleDfuWaitChunkEndCallBack = undefined;
      }
    }
  }
}


export interface WriteOptions {
  operationName: string;
  setCallback: (callback: (errorCode: PPBleFFF2ErrorCode) => void) => void;
  timeoutMs?: number;
}

