import { PPLefuStreamHandler } from './PPLefuStreamHandler';
import bluetooth from '@ohos.bluetooth';
import { access, ble, constant } from '@kit.ConnectivityKit';
import { AbilityPluginBinding, MethodResult } from '@ohos/flutter_ohos';
import { PPLefuBleExtensionData, DeviceDict } from './Extension/PPLefuBleExtensionData';
import { PPLoggerPluginOhos } from './util/PPLoggerPluginOhos';

import { PPBluetoothKit } from 'ppsdkkit/src/main/ets/PPBluetoothKit';
import { PPDeviceModel } from 'ppsdkkit/src/main/ets/vo/PPDeviceModel';
import { PPDevicePeripheralType } from 'ppsdkkit/src/main/ets/enums/PPDeviceEnums';
import { PPBleSearch } from 'ppsdkkit/src/main/ets/ble/search/PPBleSearch';
import { PPBaseDeviceControl } from 'ppsdkkit/src/main/ets/device/PPBaseDeviceControl';
import { PPAppleDeviceControl } from 'ppsdkkit/src/main/ets/device/apple/PPAppleDeviceControl';
import { PPIceDeviceControl } from 'ppsdkkit/src/main/ets/device/ice/PPIceDeviceControl';
import { PPBananaDeviceControl } from 'ppsdkkit/src/main/ets/device/banana/PPBananaDeviceControl';
import { PPCoconutDeviceControl } from 'ppsdkkit/src/main/ets/device/coconut/PPCoconutDeviceControl';
import { PPJambulDeviceControl } from 'ppsdkkit/src/main/ets/device/jambul/PPJambulDeviceControl';
import { PPTorreDeviceControl } from 'ppsdkkit/src/main/ets/device/torre/PPTorreDeviceControl';
import { PPUserModel } from 'ppsdkkit/src/main/ets/vo/PPUserModel';

import {
  abilityAccessCtrl,
  bundleManager,
  Permissions,
  common,
  Context,
  featureAbility,
  UIAbility
} from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

enum PPLefuScanType {
  SCAN = 0
}

export class PPLefuBleConnectManager {
  scanResultStreamHandler: PPLefuStreamHandler | null = null;
  loggerStreamHandler: PPLefuStreamHandler | null = null;
  connectStateStreamHandler: PPLefuStreamHandler | null = null;
  measureStreamHandler: PPLefuStreamHandler | null = null;
  historyStreamHandler: PPLefuStreamHandler | null = null;
  batteryStreamHandler: PPLefuStreamHandler | null = null;
  blePermissionStreamHandler: PPLefuStreamHandler | null = null;
  dfuStreamHandler: PPLefuStreamHandler | null = null;
  deviceLogStreamHandler: PPLefuStreamHandler | null = null;
  scanStateStreamHandler: PPLefuStreamHandler | null = null;
  private bluetoothState: bluetooth.BluetoothState | null = null;
  private needScan: boolean = false;
  private scanType: PPLefuScanType = PPLefuScanType.SCAN;
  private isScaning: boolean = false;
  private connectState: number = 0;
  deviceControl: PPBaseDeviceControl | null = null;
  currentDevice: PPDeviceModel | null = null;
  deviceModels: Map<String, PPDeviceModel> = new Map();
  private abilityPluginBinding: AbilityPluginBinding | null = null;

  constructor() {
    // 初始化蓝牙管理器
    this.initBluetooth();
  }

  private initBluetooth(): void {
    // 监听蓝牙状态变化
    PPBluetoothKit.addBleStateListener((state: number) => {
      this.onBluetoothStateChange(state);
    })
  }

  private onBluetoothStateChange(state: bluetooth.BluetoothState): void {
    if (this.bluetoothState !== state) {
      this.sendBlePermissionState(state);
    }

    this.bluetoothState = state;
    this.loggerStreamHandler?.success(`蓝牙状态:${state}`);

    if (this.needScan && access.BluetoothState.STATE_ON === state) {
      this.needScan = false;
      // this.startScan();
    } else if (state === access.BluetoothState.STATE_OFF) {
      this.needScan = false;
      if (this.isScaning) {
        this.stopScan();
      }
    }
  }

  onAttachedToAbility(binding: AbilityPluginBinding) {
    this.abilityPluginBinding = binding;
  }

  async checkPermission(): Promise<void> {
    let checkPermission: Permissions = "ohos.permission.ACCESS_BLUETOOTH";
    let isPermission: boolean = await this.checkSelfPermission(checkPermission);
    if (isPermission) {
      let permissions = new Array<Permissions>();
      permissions.push("ohos.permission.ACCESS_BLUETOOTH");
      await this.ensurePermissions(permissions);
    } else {
      if (!this.isAdapterOn()) {
        PPLoggerPluginOhos.i(`checkPermission 蓝牙可以使用`)
        return;
      }
    }

  }

  isAdapterOn(): boolean {
    try {
      return access.getState() == access.BluetoothState.STATE_ON;
    } catch (e) {
      return false;
    }
  }

  async checkSelfPermission(permission: Permissions): Promise<boolean> {
    PPLoggerPluginOhos.i("checkSelfPermission");
    let tokenId: number = 0;
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let bundleInfo: bundleManager.BundleInfo =
      await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
    let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
    tokenId = appInfo.accessTokenId;
    grantStatus = await atManager.checkAccessToken(tokenId, permission);
    PPLoggerPluginOhos.i(`checkSelfPermission grantStatus${grantStatus}`);
    return grantStatus == -1;
  }

  async ensurePermissions(permissions: Permissions[]) {
    let permissionsNeeded = new Array<Permissions>();
    for (const permission of permissions) {
      let flag = await this.checkSelfPermission(permission);
      if (permission != null && flag) {
        permissionsNeeded.push(permission);
      }
    }
    if (permissionsNeeded.length == 0 || permissionsNeeded == null) {
      // result.success(true);
      return;
    }

    const c: UIAbility | null = this.abilityPluginBinding?.getAbility() ?? null;
    let context = c?.context;

    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();

    // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
    atManager.requestPermissionsFromUser(context, permissionsNeeded).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          PPLoggerPluginOhos.i("拿到蓝牙权限");
        } else {
          // 用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限
          PPLoggerPluginOhos.e("用户拒绝授权，提示用户必须授权才能访问当前页面的功能，并引导用户到系统设置中打开相应的权限");
        }
      }
      // 授权成功
    }).catch((err: BusinessError) => {
      PPLoggerPluginOhos.e(`蓝牙权限获取失败 Code is ${err.code}, message is ${err.message}`);
    })
  }


  startScan(result: MethodResult): void {
    this.stopScan();
    this.disconnect();
    this.isScaning = true;
    this.scanType = PPLefuScanType.SCAN;

    this.sendScanState(true);

    PPBleSearch.getInstance().startScan((deviceModel: PPDeviceModel) => {
      if (!deviceModel.deviceMac) {
        return;
      }

      if (deviceModel) {
        this.deviceModels[deviceModel.deviceMac] = deviceModel;
        if (this.scanType === PPLefuScanType.SCAN) {
          PPLoggerPluginOhos.d(`startScan findDevice deviceName:${deviceModel.deviceName} deviceMac:${deviceModel.deviceMac}`);
          let deviceDict: DeviceDict = PPLefuBleExtensionData.convertDeviceDict(deviceModel);
          PPLoggerPluginOhos.d(`startScan findDevice deviceDict deviceName:${deviceDict.deviceName} deviceMac:${deviceDict.deviceMac}`);
          // 转换设备信息为统一格式
          this.scanResultStreamHandler?.success(deviceDict);
        }
      }
    });
    this.sendCommonState(true, result)
  }

  stopScan(): void {
    PPBleSearch.getInstance().stopScan();
    if (this.isScaning) {
      this.isScaning = false;
      this.sendScanState(false);
    }
  }

  connectDevice(deviceMac: string) {

    let deviceModel: PPDeviceModel = this.deviceModels[deviceMac];
    if (!deviceModel) {
      this.addLog(`设备${deviceMac}未找到，请先搜索设备`)
      this.sendConnectState(2);
    } else {
      this.stopScan();
      if (this.deviceControl) {
        if (this.deviceControl.deviceModel?.deviceMac === deviceMac) {
          if (this.deviceControl.isConnect()) {
            this.addLog('设备已连接,无需重复连接')
            this.sendConnectState(1);
          } else {
            this.startConnectDevice();
          }
        } else {
          this.disconnect();
          this.createDeviceControl(deviceModel);
          this.startConnectDevice();
        }
      } else {
        this.createDeviceControl(deviceModel);
        this.startConnectDevice();
      }
    }
  }


  private createDeviceControl(deviceModel: PPDeviceModel) {
    switch (deviceModel.getDevicePeripheralType()) {
      case PPDevicePeripheralType.PeripheralApple:
        this.deviceControl = new PPAppleDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralIce:
        this.deviceControl = new PPIceDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralBanana:
        this.deviceControl = new PPBananaDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralCoconut:
        this.deviceControl = new PPCoconutDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralJambul:
        this.deviceControl = new PPJambulDeviceControl(deviceModel);
        break;
      case PPDevicePeripheralType.PeripheralTorre:
        this.deviceControl = new PPTorreDeviceControl(deviceModel);
        break;
      default:
        this.addLog(`不支持的设备类型:${deviceModel.getDevicePeripheralType()}`);
        break;
    }
  }

  private startConnectDevice() {
    this.deviceControl?.startConnect((state: ble.ProfileConnectionState) => {
      this.connectState = state;
      PPLoggerPluginOhos.i(`BluetoothPage bluetooth connect state changed state:${state}}`);
      if (this.connectState === constant.ProfileConnectionState.STATE_DISCONNECTED) {
        this.addLog('设备断开');
        this.sendConnectState(0);
      } else if (this.connectState === constant.ProfileConnectionState.STATE_CONNECTED) {
        this.addLog('连接成功');
      }
    }, (isSuccess: boolean) => {
      if (isSuccess) {
        this.addLog('服务发现成功,可以调用指令');
        this.sendConnectState(1);
      } else {
        this.addLog('服务发现失败');
        this.sendConnectState(2);
      }
    });
  }

  disconnect(): void {
    // 实现断开连接逻辑
    this.deviceControl?.stopSearch();
    this.deviceControl?.disConnect();
    this.clearData();
  }

  private clearData(): void {
    // 清理设备相关数据
    this.currentDevice = null;
    this.deviceControl = null;
    this.sendConnectState(0);
  }

  /// 发送连接状态 连接状态 0:断开连接 1:连接成功 2:连接错误
  sendConnectState(state: number): void {
    this.loggerStreamHandler?.success(`连接状态:${state}`);
    this.connectState = state;

    this.connectStateStreamHandler?.success({
      deviceMac: this.currentDevice?.deviceMac || '',
      state: state
    });
  }

  sendBlePermissionState(state: number): void {
    let stateValue = 0;
    switch (state) {
      case 1: // unauthorized
        stateValue = 1;
        break;
      case 2: // poweredOn
        stateValue = 2;
        break;
      case 3: // poweredOff
        stateValue = 3;
        break;
    }

    this.blePermissionStreamHandler?.success({ state: stateValue });
  }

  sendScanState(scaning: boolean): void {
    let code = scaning ? 1 : 0;
    this.scanStateStreamHandler?.success({ state: code });
  }

  // 发送通用状态
  sendCommonState(state: boolean, callBack: MethodResult): void {
    callBack.success({ state: state });
  }

  fetchHistory(userID: string, memberID: string, callBack: MethodResult) {
    this.addLog(`获取历史记录 userID:${userID},memberID:${memberID}`)
  }

  deleteHistory() {
    this.addLog(`deleteHistory`)
  }

  configWifi(domain: string, ssId: string, password: string | null = null, result: MethodResult) {
    this.addLog(`configWifi domain:${domain},ssId:${ssId},password:${password}`)
  }

  syncTime(is24Hour: boolean, result: MethodResult) {
    this.addLog(`is24Hour`)
  }

  syncUnit(unit: number, sex: number, age: number, height: number, isPregnantMode: boolean, isAthleteMode: boolean) {
    this.addLog(`同步单位 unit:${unit},sex:${sex},age:${age},height:${height},isPregnantMode:${isPregnantMode},isAthleteMode:${isAthleteMode}`)
  }

  fetchWifiInfo(result: MethodResult) {
    this.addLog('获取WiFi信息')
  }

  fetchDeviceInfo(result: MethodResult) {
    this.addLog('获取设备信息')
  }

  fetchBatteryInfo(result: MethodResult) {
    this.addLog('获取电池信息')
  }

  resetDevice(): void {
    this.addLog('重置设备')
  }

  fetchConnectedDevice(result: MethodResult): void {
    this.addLog('获取已连接设备')
  }

  addBlePermissionListener(): void {
    this.addLog('添加蓝牙权限监听')
  }

  fetchWifiMac(result: MethodResult): void {
    this.addLog('获取WiFi MAC地址')
  }

  scanWifiNetworks(result: MethodResult): void {
    this.addLog('扫描WiFi网络')
  }

  wifiOTA(result: MethodResult): void {
    this.addLog('WiFi OTA升级')
  }

  heartRateSwitchControl(open: boolean, result: MethodResult): void {
    this.addLog(`心率开关控制 open:${open}`)
  }

  fetchHeartRateSwitch(result: MethodResult): void {
    this.addLog('获取心率开关状态')
  }

  impedanceSwitchControl(open: boolean, result: MethodResult): void {
    this.addLog(`阻抗开关控制 open:${open}`)
  }

  fetchImpedanceSwitch(result: MethodResult): void {
    this.addLog('获取阻抗开关状态')
  }

  setBindingState(binding: boolean, result: MethodResult): void {
    this.addLog(`设置绑定状态 binding:${binding}`)
  }

  fetchBindingState(result: MethodResult): void {
    this.addLog('获取绑定状态')
  }

  setScreenBrightness(brightness: number, result: MethodResult): void {
    this.addLog(`设置屏幕亮度 brightness:${brightness}`)
  }

  getScreenBrightness(result: MethodResult): void {
    this.addLog('获取屏幕亮度')
  }

  syncUserInfo(model: PPUserModel, result: MethodResult): void {
    this.addLog(`同步用户信息 model:${JSON.stringify(model)}`)
  }

  syncUserList(userArray: PPUserModel[], result: MethodResult): void {
    this.addLog(`同步用户列表 userArray:${JSON.stringify(userArray)}`)
  }

  fetchUserIDList(result: MethodResult): void {
    this.addLog('获取用户ID列表')
  }

  selectUser(user: PPUserModel, result: MethodResult): void {
    this.addLog(`选择用户 user:${JSON.stringify(user)}`)
  }

  deleteUser(user: PPUserModel, result: MethodResult): void {
    this.addLog(`删除用户 user:${JSON.stringify(user)}`)
  }

  startMeasure(result: MethodResult): void {
    this.addLog('开始测量')
  }

  stopMeasure(result: MethodResult): void {
    this.addLog('停止测量')
  }

  startBabyModel(step: number, weight: number, result: MethodResult): void {
    this.addLog(`开始婴儿模式 step:${step},weight:${weight}`)
  }

  exitBabyModel(result: MethodResult): void {
    this.addLog('退出婴儿模式')
  }

  startDFU(filePath: string, deviceFirmwareVersion: string, isForceCompleteUpdate: boolean,
    result: MethodResult): void {
    this.addLog(`开始DFU升级 filePath:${filePath},deviceFirmwareVersion:${deviceFirmwareVersion},isForceCompleteUpdate:${isForceCompleteUpdate}`)
  }

  syncDeviceLog(logFolder: string): void {
    this.addLog(`同步设备日志 logFolder:${logFolder}`)
  }

  keepAlive(): void {
    this.addLog('保持连接')
  }

  clearDeviceData(type: number, result: MethodResult): void {
    this.addLog(`清除设备数据 type:${type}`)
  }

  setDeviceLanguage(type: number, result: MethodResult): void {
    this.addLog(`设置设备语言 type:${type}`)
  }

  fetchDeviceLanguage(result: MethodResult): void {
    this.addLog('获取设备语言')
  }

  setDisplayBodyFat(bodyFat: number, result: MethodResult): void {
    this.addLog(`设置显示体脂 bodyFat:${bodyFat}`)
  }

  exitScanWifiNetworks(result: MethodResult): void {
    this.addLog('退出WiFi扫描')
  }

  exitNetworkConfig(result: MethodResult): void {
    this.addLog('退出网络配置')
  }

  receiveBroadcastData(deviceMac: string, result: MethodResult): void {
    this.addLog(`接收广播数据 deviceMac:${deviceMac}`)
  }

  sendBroadcastData(cmd: string, unit: number, result: MethodResult): void {
    this.addLog(`发送广播数据 cmd:${cmd},unit:${unit}`)
  }

  addLog(message: string) {
    this.loggerStreamHandler?.success(message);
    PPLoggerPluginOhos.d(`${message}`)
  }
}