// PPBluetoothKit.ts
import fs from '@ohos.file.fs';
import { access } from '@kit.ConnectivityKit';
import { PPLogger } from './log/PPLogger';
import { DeviceConfigVo, DeviceConfigVoJson } from './vo/DeviceConfigVo';
import { ByteUtil } from './utils/ByteUtil';
import { PPLoggerListener } from './log/PPLoggerListener';

export class PPBluetoothKit {
  // 静态变量存储设备配置
  public static deviceConfigVos: Array<DeviceConfigVo> | null = null;

  // 单例实例
  private constructor() {
  }

  static async initSdk(context: Context, appKey: string, secretKey: string, configPath: string): Promise<void> {

    PPLogger.d(`PPBluetoothKit initSdk configPath:${configPath}`);

    if (configPath.endsWith('.config')) {
      try {
        const file = fs.openSync(configPath, fs.OpenMode.READ_ONLY);
        const encodedStr = fs.readSync(file.fd, new ArrayBuffer(1024));
        PPLogger.d('PPBluetoothKit initSdk encodedStr: ${encodedStr}');
        fs.closeSync(file);
        // decodeDeviceConfig(context, appKey, secretKey, configPath);
      } catch (err) {
        PPLogger.e("PPBluetoothKit Failed to read config file: ${err}");
      }
    } else if (configPath.endsWith('.json')) {
      try {

        const dataUint8Array = await context.resourceManager.getRawFileContent(configPath);

        const dataJson = ByteUtil.uint8ArrayToString(dataUint8Array);

        PPLogger.d(`PPBluetoothKit initSdk deviceJsonStr: ${dataJson}`);

        PPBluetoothKit.setDeviceSetting(dataJson);

      } catch (err) {
        PPLogger.e(`PPBluetoothKit initSdk Failed to read JSON file: ${err}`);
      }
    }
  }

  // 设置设备配置JSON字符串
  static setDeviceSetting(jsonStr: string): void {
    try {
      const jsonObj = JSON.parse(jsonStr) as Array<DeviceConfigVoJson>;
      const deviceConfigList = jsonObj.map(item => DeviceConfigVo.fromJson(item));
      PPLogger.d(`PPBluetoothKit setConfigDeviceList device size ${deviceConfigList?.length}`);
      PPBluetoothKit.setConfigDeviceList(deviceConfigList);
    } catch (err) {
      PPLogger.e(`PPBluetoothKit Failed to parse JSON: ${err}`);
    }
  }

  // 设置设备配置列表
  static setConfigDeviceList(deviceConfigVos: Array<DeviceConfigVo> | null): void {
    if (deviceConfigVos && deviceConfigVos.length > 0) {
      PPBluetoothKit.deviceConfigVos = deviceConfigVos;
      deviceConfigVos.forEach(it => {
        PPLogger.i(`PPBluetoothKit setConfigDeviceList ${JSON.stringify(it)}`);
      });
    } else {
      PPLogger.e(`PPBluetoothKit setConfigDeviceList Error deviceConfigVos is empty`);
    }
  }

  // 设置调试模式
  static setDebug(isDebug: boolean): void {
    // OHOS 的日志级别设置方式
    PPLogger.setDebug(isDebug);
  }

  static addLoggerListener(listener: PPLoggerListener): void {
    PPLogger.addListener(listener);
  }

  // 添加蓝牙状态监听器
  static addBleStateListener(stateCallback: (bleState: number) => void): void {
    // OHOS 蓝牙状态监听
    access.on('stateChange', (state: number) => {
      stateCallback(state);
    });
  }

  static async enableBluetooth() {
    try {
      await access.enableBluetooth();
    } catch (err) {
      PPLogger.e("蓝牙状态切换失败:${err}")
    }
  }

  static async disableBluetooth() {
    try {
      await access.disableBluetooth();
    } catch (e) {
      PPLogger.e("蓝牙状态切换失败:${err}")
    }
  }

  static getStateIsOn(): boolean {
    try {
      return access.BluetoothState.STATE_ON === access.getState();
    } catch (err) {
      PPLogger.e("获取蓝牙状态失败:${err}")
      return false;
    }
  }
}