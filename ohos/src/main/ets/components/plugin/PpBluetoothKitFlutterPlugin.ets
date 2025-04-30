import { FlutterPlugin, FlutterPluginBinding, MethodCall, MethodCallHandler,
  MethodChannel, MethodResult, EventChannel, AbilityPluginBinding, EventSink, Any} from '@ohos/flutter_ohos';
import { PPLogger } from 'ppsdkkit/src/main/ets/log/PPLogger';

import { PPBluetoothKit } from 'ppsdkkit/src/main/ets/PPBluetoothKit';
import { PPLefuBleConnectManager } from './PPLefuBleConnectManager';
import { PPLefuStreamHandler } from './PPLefuStreamHandler';

/** PpBluetoothKitFlutterPlugin **/
export default class PpBluetoothKitFlutterPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private bleChannel: MethodChannel | null = null;
  private bleManager: PPLefuBleConnectManager = new PPLefuBleConnectManager();
  // 这里需要引入鸿蒙对应的蓝牙管理类

  // 事件通道
  private measurementEventChannel: EventChannel | null = null;
  private loggerEventChannel: EventChannel | null = null;
  private connectStateEventChannel: EventChannel | null = null;
  private scanResultEventChannel: EventChannel | null = null;
  private historyEventChannel: EventChannel | null = null;
  private batteryEventChannel: EventChannel | null = null;
  private blePermissionEventChannel: EventChannel | null = null;
  private dfuEventChannel: EventChannel | null = null;
  private deviceLogEventChannel: EventChannel | null = null;
  private scanStateEventChannel: EventChannel | null = null;

  private context: Context = getContext(this);
  private pluginBinding: FlutterPluginBinding | null = null;
  private abilityPluginBinding: AbilityPluginBinding | null = null;

  constructor() {
    // 初始化蓝牙管理器
    // this.bleManager = new PPBluetoothKit(); // 这里需要实例化鸿蒙对应的蓝牙管理类
  }

  getUniqueClassName(): string {
    return "PpBluetoothKitFlutterPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {

    this.pluginBinding = binding;
    this.context = this.pluginBinding.getApplicationContext();

    // 主通道
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "pp_bluetooth_kit_flutter");
    this.channel.setMethodCallHandler(this);

    // 蓝牙通道
    this.bleChannel = new MethodChannel(binding.getBinaryMessenger(), "pp_ble_channel");
    this.bleChannel.setMethodCallHandler(this);

    // 测量数据事件通道
    let measureStreamHandler = new PPLefuStreamHandler();
    this.measurementEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_measurement_streams");
    this.measurementEventChannel.setStreamHandler({
      onListen: (args: Any, events: EventSink) => {
        this.bleManager.measureStreamHandler = measureStreamHandler;
      },
      onCancel: (event: Any) => {
        this.bleManager.measureStreamHandler = null;
      }
    });

    // 日志事件通道
    let loggerStreamHandler = new PPLefuStreamHandler()
    this.loggerEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_logger_streams");
    this.loggerEventChannel.setStreamHandler({
      onListen: (event: Any, events: EventSink) => {
        this.bleManager.loggerStreamHandler = loggerStreamHandler;
      },
      onCancel: (event: string) => {
        this.bleManager.loggerStreamHandler = null;
      }
    });

    // 连接状态事件通道
    let connectStateStreamHandler = new PPLefuStreamHandler();
    this.connectStateEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_connect_state_streams");
    this.connectStateEventChannel.setStreamHandler({
      onListen: (event: Any, events: EventSink) => {
        this.bleManager.connectStateStreamHandler = connectStateStreamHandler;
      },
      onCancel: (event: Any) => {
        this.bleManager.connectStateStreamHandler = null;
      }
    });

    // 扫描结果事件通道
    let scanResultStreamHandler = new PPLefuStreamHandler();
    this.scanResultEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_device_list_streams");
    this.scanResultEventChannel.setStreamHandler({
      onListen: (event: Any, events: EventSink) => {
        this.bleManager.scanResultStreamHandler = scanResultStreamHandler;
      },
      onCancel: (event: Any) => {
        this.bleManager.scanResultStreamHandler = null;
      }
    });

    // 历史数据事件通道
    let historyStreamHandler = new PPLefuStreamHandler()
    this.historyEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_history_data_streams");
    this.historyEventChannel.setStreamHandler({
      onListen: (event: Any, events: EventSink) => {
        this.bleManager.historyStreamHandler = historyStreamHandler;
      },
      onCancel: (event: Any) => {
        this.bleManager.historyStreamHandler = null;
      }
    });

    // 电池事件通道
    let batteryStreamHandler = new PPLefuStreamHandler()
    this.batteryEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_battery_streams");
    this.batteryEventChannel.setStreamHandler({
      onListen: (event: string, events: EventSink) => {
        this.bleManager.batteryStreamHandler =  batteryStreamHandler;
      },
      onCancel: (event: string) => {
        this.bleManager.batteryStreamHandler = null;
      }
    });

    // 蓝牙权限事件通道
    let blePermissionStreamHandler = new PPLefuStreamHandler()
    this.blePermissionEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_ble_permission_streams");
    this.blePermissionEventChannel.setStreamHandler({
      onListen: (event: string, events: EventSink) => {
        this.bleManager.blePermissionStreamHandler =  blePermissionStreamHandler;
      },
      onCancel: (event: string) => {
        this.bleManager.blePermissionStreamHandler = null;
      }
    });

    // DFU事件通道
    let dfuStreamHandler = new PPLefuStreamHandler()
    this.dfuEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_dfu_streams");
    this.dfuEventChannel.setStreamHandler({
      onListen: (event: string, events: EventSink) => {
        this.bleManager.dfuStreamHandler = dfuStreamHandler;
      },
      onCancel: (event: string) => {
        this.bleManager.dfuStreamHandler = null;
      }
    });

    // 设备日志事件通道
    let deviceLogStreamHandler = new PPLefuStreamHandler()
    this.deviceLogEventChannel = new EventChannel(binding.getBinaryMessenger(), "device_log_streams");
    this.deviceLogEventChannel.setStreamHandler({
      onListen: (event: string, events: EventSink) => {
        this.bleManager.deviceLogStreamHandler = deviceLogStreamHandler;
      },
      onCancel: (event: string) => {
        this.bleManager.deviceLogStreamHandler = null;
      }
    });

    // 扫描状态事件通道
    let scanStateStreamHandler = new PPLefuStreamHandler()
    this.scanStateEventChannel = new EventChannel(binding.getBinaryMessenger(), "pp_scan_state_streams");
    this.scanStateEventChannel.setStreamHandler({
      onListen: (event: string, events: EventSink) => {
        this.bleManager.scanStateStreamHandler = scanStateStreamHandler;
      },
      onCancel: (event: string) => {
        this.bleManager.scanStateStreamHandler = null;
      }
    });
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null);
    }
    if (this.bleChannel != null) {
      this.bleChannel.setMethodCallHandler(null);
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    const method = call.method;
    const params = (call).args as Record<string, Any>;

    if (method == "getPlatformVersion") {
      result.success("HarmonyOS 桥接返回结果");
    } else if (method == "initSDK") {
      const appKey = params["appKey"] as string;
      const appSecret = params["appSecret"] as string;
      const deviceContent = params["deviceContent"] as string;

      if (!appKey) {
        this.bleManager.loggerStreamHandler?.success("appKey为空");
        return;
      }
      if (!appSecret) {
        this.bleManager.loggerStreamHandler?.success("appSecret为空");
        return;
      }
      if (!deviceContent) {
        this.bleManager.loggerStreamHandler?.success("deviceContent为空");
        return;
      }

      // 调用鸿蒙蓝牙SDK初始化方法
      // this.bleManager.loadDevice(appKey, appSecret, deviceContent);
      result.success(true);
    } else if (method == "startScan") {
      // this.bleManager.startScan();
      result.success(true);
    } else if (method == "stopScan") {
      // this.bleManager.stopScan();
      result.success(true);
    } else if (method == "connectDevice") {
      const deviceMac = params["deviceMac"] as string;
      const deviceName = params["deviceName"] as string;

      if (!deviceMac) {
        this.bleManager.loggerStreamHandler?.success("deviceMac为空");
        return;
      }
      if (!deviceName) {
        this.bleManager.loggerStreamHandler?.success("deviceName为空");
        return;
      }

      // this.bleManager.connectDevice(deviceMac, deviceName);
      result.success(true);
    } else if (method == "disconnect") {
      // this.bleManager.disconnect();
      result.success({});
    }
    // ... 其他方法实现与iOS类似，需要调用对应的鸿蒙蓝牙SDK方法
    else {
      result.notImplemented();
    }
  }
}