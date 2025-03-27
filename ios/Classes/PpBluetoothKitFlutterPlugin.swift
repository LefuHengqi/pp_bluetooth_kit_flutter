import Flutter
import UIKit
import PPBaseKit
import PPBluetoothKit

public class PpBluetoothKitFlutterPlugin: NSObject, FlutterPlugin {
    
    var bleManager:PPLefuBleConnectManager = PPLefuBleConnectManager()
    
    
  public static func register(with registrar: FlutterPluginRegistrar) {
      
      let channel = FlutterMethodChannel(name: "pp_bluetooth_kit_flutter", binaryMessenger: registrar.messenger())
      let instance = PpBluetoothKitFlutterPlugin()
      registrar.addMethodCallDelegate(instance, channel: channel)

      let bleChannel = FlutterMethodChannel(name: "pp_ble_channel", binaryMessenger: registrar.messenger())
      registrar.addMethodCallDelegate(instance, channel: bleChannel)
      
      let measureStreamHandler = PPLefuStreamHandler()
      instance.bleManager.measureStreamHandler = measureStreamHandler
      let measureEventChannel = FlutterEventChannel(name: "pp_measurement_streams", binaryMessenger: registrar.messenger())
      measureEventChannel.setStreamHandler(measureStreamHandler)
      
      let loggerStreamHandler = PPLefuStreamHandler()
      instance.bleManager.loggerStreamHandler = loggerStreamHandler
      let loggerEventChannel = FlutterEventChannel(name: "pp_logger_streams", binaryMessenger: registrar.messenger())
      loggerEventChannel.setStreamHandler(loggerStreamHandler)
      
      let connectStateStreamHandler = PPLefuStreamHandler()
      instance.bleManager.connectStateStreamHandler = connectStateStreamHandler
      let connectStateEventChannel = FlutterEventChannel(name: "pp_connect_state_streams", binaryMessenger: registrar.messenger())
      connectStateEventChannel.setStreamHandler(connectStateStreamHandler)

      let scanResultStreamHandler = PPLefuStreamHandler()
      instance.bleManager.scanResultStreamHandler = scanResultStreamHandler
      let scanEventChannel = FlutterEventChannel(name: "pp_device_list_streams", binaryMessenger: registrar.messenger())
      scanEventChannel.setStreamHandler(scanResultStreamHandler)
      
      let historyStreamHandler = PPLefuStreamHandler()
      instance.bleManager.historyStreamHandler = historyStreamHandler
      let historyEventChannel = FlutterEventChannel(name: "pp_history_data_streams", binaryMessenger: registrar.messenger())
      historyEventChannel.setStreamHandler(historyStreamHandler)
      
      let batteryStreamHandler = PPLefuStreamHandler()
      instance.bleManager.batteryStreamHandler = batteryStreamHandler
      let batteryEventChannel = FlutterEventChannel(name: "pp_battery_streams", binaryMessenger: registrar.messenger())
      batteryEventChannel.setStreamHandler(batteryStreamHandler)

  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      let method = call.method;
      
      let params = call.arguments as? [String:Any];

      if method == "getPlatformVersion" {
          result("iOS 桥接返回结果:" + UIDevice.current.systemVersion)

      } else if method == "initSDK" {
          
          let appKey = params?["appKey"] as? String;
          let appSecret = params?["appSecret"] as? String;
          let filePath = params?["filePath"] as? String;
          
          guard let appKey = appKey else {
              self.bleManager.loggerStreamHandler?.event?("appKey为空");
              return;
          }
          guard let appSecret = appSecret else {
              self.bleManager.loggerStreamHandler?.event?("appSecret为空");
              return;
          }
          guard let filePath = filePath else {
              self.bleManager.loggerStreamHandler?.event?("filePath为空");
              return;
          }
          
          PPBluetoothManager.loadDevice(withAppKey: appKey, appSecrect: appSecret, filePath: filePath)

      } else if method == "setDeviceSetting" {

          let deviceContent = params?["deviceContent"] as? String;

          guard let deviceContent = deviceContent else {
              self.bleManager.loggerStreamHandler?.event?("deviceContent为空");
              return;
          }
          
          if let jsonData = deviceContent.data(using: .utf8) {
              do {
                  let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                  if let array = jsonObject as? [Any] {
                      
                      PPBluetoothManager.loadDevice(withJsonData: array)
                      
                  } else {
                      self.bleManager.loggerStreamHandler?.event?("设备列表-转JSON失败");
                  }
              } catch {
                  self.bleManager.loggerStreamHandler?.event?("转JSON异常: \(error)")
              }
          } else {
              self.bleManager.loggerStreamHandler?.event?("转JSON DATA失败")
          }

      } else if method == "startScan" {
          
          bleManager.startScan()
      } else if method == "stopScan" {
          
          bleManager.stopScan()
      } else if method == "connectDevice" {
          
          let deviceMac = params?["deviceMac"] as? String;
          let deviceName = params?["deviceName"] as? String;
          
          guard let deviceMac = deviceMac else {
              self.bleManager.loggerStreamHandler?.event?("deviceMac为空");
              return;
          }
          guard let deviceName = deviceName else {
              self.bleManager.loggerStreamHandler?.event?("deviceName为空");
              return;
          }
          
          self.bleManager.connectDevice(deviceMac: deviceMac, deviceName: deviceName)
          
      } else if method == "disconnect" {

          self.bleManager.stopScan()
          self.bleManager.disconnect()
          
      } else if method == "fetchHistory" {
          self.bleManager.fetchHistory()
      } else if method == "deleteHistory" {
          self.bleManager.deleteHistory()
      } else if method == "syncUnit" {
          
          let unit = params?["unit"] as? Int;
          let sex = params?["sex"] as? Int;
          let age = params?["age"] as? Int;
          let height = params?["height"] as? Int;
          let isPregnantMode = params?["isPregnantMode"] as? Bool;
          let isAthleteMode = params?["isAthleteMode"] as? Bool;
          
          self.bleManager.loggerStreamHandler?.event?("同步单位，参数：\(params ?? [:])")
          
          let model = PPBluetoothDeviceSettingModel()
          model.unit = PPDeviceUnit(rawValue: UInt(unit ?? 0)) ?? .unitKG
          model.gender = PPDeviceGenderType(rawValue: UInt(sex ?? 0)) ?? .female
          model.age = age ?? 0
          model.height = height ?? 0
          model.isPregnantMode = isPregnantMode ?? false
          model.isAthleteMode = isAthleteMode ?? false
          
          self.bleManager.syncUnit(model: model)
          
      } else if method == "syncTime" {
          
          let is24Hour = params?["sex"] as? Bool ?? true;
          self.bleManager.syncTime(is24Hour: is24Hour, callBack: result)
          
      } else if method == "configWifi" {
          let domain = params?["domain"] as? String;
          let ssId = params?["ssId"] as? String;
          let password = params?["password"] as? String;
          
          guard let domain = domain else {
              result(["success":false,"errorCode":-1]);
              return
          }
          
          guard let ssId = ssId else {
              result(["success":false,"errorCode":-1]);
              return
          }
          
          guard let password = password else {
              result(["success":false,"errorCode":-1]);
              return
          }
          
          self.bleManager.configWifi(domain: domain, ssId: ssId, password: password, callBack: result)
          
      } else if method == "fetchWifiInfo" {
          
          self.bleManager.fetchWifiInfo(result)
      } else if method == "fetchDeviceInfo" {
          
          self.bleManager.fetchDeviceInfo(result)
      } else if method == "fetchBatteryInfo" {
          
          self.bleManager.fetchBatteryInfo()
      } else if method == "resetDevice" {
          
          self.bleManager.resetDevice()
      }

  }
}
