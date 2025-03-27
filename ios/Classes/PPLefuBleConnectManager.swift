//
//  LefuBleConnectManager.swift
//  Pods
//
//  Created by lefu on 2025/3/25
//  


import Foundation
import PPBaseKit
import PPBluetoothKit
import Flutter

enum PPLefuScanType:Int {
    case scan = 0
    case connect
}

class PPLefuBleConnectManager:NSObject {
    
    var scanResultStreamHandler:PPLefuStreamHandler?
    var loggerStreamHandler:PPLefuStreamHandler?
    var connectStateStreamHandler:PPLefuStreamHandler?
    var measureStreamHandler:PPLefuStreamHandler?
    var historyStreamHandler:PPLefuStreamHandler?
    var batteryStreamHandler:PPLefuStreamHandler?
    
    lazy var scaleManager:PPBluetoothConnectManager = PPBluetoothConnectManager()
    
    private var bluetoothState:PPBluetoothState?
    private var needScan = false
    private var scanType:PPLefuScanType = .scan
    private var needConnectMac = ""
    private var currentDevice: PPBluetoothAdvDeviceModel?
    private var current180A:PPBluetooth180ADeviceModel?
    private var connectState:Int = 0
    private var tempScaleHistoryList : Array<PPBluetoothScaleBaseModel>?
    
    private var appleControl : PPBluetoothPeripheralApple?
    
    func startScan() {
        
        scan(type: .scan);
    }
    
    func scan(type:PPLefuScanType) {
        
        self.scanType = type
        self.needScan = true
        
        self.scaleManager = PPBluetoothConnectManager()
        self.scaleManager.updateStateDelegate = self
        self.scaleManager.surroundDeviceDelegate = self
    }
    
    func connectDevice(deviceMac:String, deviceName:String) {
        self.stopScan()
        self.disconnect()
        
        self.needConnectMac = deviceMac
        scan(type: .connect);
    }
    
    
    func stopScan() {
        
        self.scaleManager.stopSearch()
        
    }
    
    func disconnect() {
        
        if let apple = self.appleControl?.peripheral {
            self.scaleManager.disconnect(apple)
        }
        self.appleControl = nil
        
        self.needScan = false
        self.needConnectMac = ""
        self.currentDevice = nil
        self.current180A = nil
    }
    
    func sendConnectState(_ state:Int) {
        self.loggerStreamHandler?.event?("连接状态:\(state)")
        
        self.connectState = state
        
        let mac = self.currentDevice?.deviceMac ?? ""
        let params:[String:Any] = [
            "deviceMac":mac,
            "state":1
        ]

        self.connectStateStreamHandler?.event?(params)
        
    }
    
    func fetchHistory() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }

        if currentDevice.peripheralType == .peripheralApple {
            self.tempScaleHistoryList = []
            self.appleControl?.fetchDeviceHistoryData()
        }
    }
    
    func deleteHistory() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.deleteDeviceHistoryData(handler: { state in
                self.loggerStreamHandler?.event?("删除历史数据-状态:\(state)")
            })
        }
    }
    
    func syncUnit(model:PPBluetoothDeviceSettingModel) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }

        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.syncDeviceSetting(model)
        }
    }
    
    func syncTime(is24Hour:Bool, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack(["state":0])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.syncDeviceTime(handler: { state in
                let ret = state == 0 ? 1 : 0
                self.loggerStreamHandler?.event?("同步时间-状态:\(ret)")
                let param = ["state":ret]
                
                callBack(param)
            })
        }
    }
    
    func configWifi(domain:String, ssId:String, password:String, callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack(["success":false,"errorCode":-1])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            
            self.appleControl?.changeDNS(domain, withHandler: {[weak self] domainState in
                guard let `self` = self else {
                    return
                }
                
                if domainState != 0 {
                    self.loggerStreamHandler?.event?("配域名失败")
                    callBack(["success":false,"errorCode":-1])
                    return
                }
                
                
                self.appleControl?.configNetWork(withSSID: ssId, password: password, handler: { sn, configState in
                    let success:Bool = configState == .success

                    let dict:[String:Any?] = [
                        "success":success,
                        "errorCode":configState.rawValue,
                        "sn":sn
                    ]
                    
                    let filtedDict = dict.compactMapValues { $0 }
                    
                    callBack(filtedDict);
                    
                })
                
            })
            
        }

    }
    
    func fetchWifiInfo(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.queryWifiConfig(handler: { model in
                let ssId = model?.ssid
                
                let retDict = ssId == nil ? [:] : ["ssId": ssId]
                
                callBack(retDict)
            })
        }
    }
    
    func fetchDeviceInfo(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if let current180A = self.current180A {
            
            let dict = self.convert180A(model: current180A)
            
            callBack(dict);
            
            return ;
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
            
            return
        }
        
        
    }
    
    func fetchBatteryInfo() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.batteryStreamHandler?.event?(["power":0])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.fetchDeviceBatteryInfo()
        }
    }
    
    func resetDevice() {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.restoreFactory(handler: {
            })
        }
        
    }
    
    func convert180A(model:PPBluetooth180ADeviceModel)->[String:Any] {
        let dict:[String:Any?] = [
            "modelNumber":model.modelNumber,
            "firmwareRevision":model.firmwareRevision,
            "softwareRevision":model.softwareRevision,
            "hardwareRevision":model.hardwareRevision,
            "serialNumber":model.serialNumber,
            "manufacturerName":model.manufacturerName
        ]
        
        
        let filtedDict = dict.compactMapValues { $0 }
        
        return filtedDict
    }
    
    func convertDeviceDict(_ device:PPBluetoothAdvDeviceModel)->[String:Any] {
        let dict:[String:Any] = [
            "deviceSettingId":device.deviceSettingId,
            "deviceMac":device.deviceMac,
            "deviceName":device.deviceName,
            "devicePower":device.devicePower,
            "rssi":device.rssi,
            "deviceType":device.deviceType.rawValue,
            "deviceProtocolType":device.deviceProtocolType.rawValue,
            "deviceCalculateType":device.deviceCalcuteType.rawValue,
            "deviceAccuracyType":device.deviceAccuracyType.rawValue,
            "devicePowerType":device.devicePowerType.rawValue,
            "deviceConnectType":device.deviceConnectType.rawValue,
            "deviceFuncType":device.deviceFuncType.rawValue,
            "deviceUnitType":device.deviceUnitList,
            "peripheralType":device.peripheralType.rawValue,
            "sign":device.sign,
            "advLength":device.advLength,
            "macAddressStart":device.macAddressStart,
            "standardType":device.standardType.rawValue
        ]
        
        return dict
    }
    
    func convertMeasurementDict(_ model:PPBluetoothScaleBaseModel)->[String:Any] {
        
        let dateTimeInterval = Int(model.dateTimeInterval * 1000)
        var memberId = model.memberId
        if memberId == nil {
            memberId = ""
        }
        
        let dict:[String:Any] = [
            "weight":model.weight,
            "impedance":model.impedance,
            "impedance100EnCode":model.impedance100EnCode,
            "isHeartRating":model.isHeartRating,
            "heartRate":model.heartRate,
            "isOverload":model.isOverload,
            "isPlus":model.isPlus,
            "measureTime":dateTimeInterval,
            "memberId":memberId,
            "footLen":model.footLen,
            "unit":model.unit.rawValue,
            "z100KhzLeftArmEnCode":model.z100KhzLeftArmEnCode,
            "z100KhzLeftLegEnCode":model.z100KhzLeftLegEnCode,
            "z100KhzRightArmEnCode":model.z100KhzRightArmEnCode,
            "z100KhzRightLegEnCode":model.z100KhzRightLegEnCode,
            "z100KhzTrunkEnCode":model.z100KhzTrunkEnCode,
            "z20KhzLeftArmEnCode":model.z20KhzLeftArmEnCode,
            "z20KhzLeftLegEnCode":model.z20KhzLeftLegEnCode,
            "z20KhzRightArmEnCode":model.z20KhzRightArmEnCode,
            "z20KhzRightLegEnCode":model.z20KhzRightLegEnCode,
            "z20KhzTrunkEnCode":model.z20KhzTrunkEnCode,
                
        ]
        
        return dict
    }
    
    func sendMeasureData(_ model:PPBluetoothScaleBaseModel, advModel: PPBluetoothAdvDeviceModel, measureState:Int) {
        
        let deviceDict:[String:Any] = self.convertDeviceDict(advModel)
        let dataDict:[String:Any] = self.convertMeasurementDict(model)
        
        self.loggerStreamHandler?.event?("测量状态:\(measureState)")
        
        let dict:[String:Any] = [
            "measurementState":measureState,
            "device":deviceDict,
            "data":dataDict
        ]
        
        self.measureStreamHandler?.event?(dict)
    }
    
    func sendHistoryData(dataList:[Any]) {
        self.loggerStreamHandler?.event?("历史数据-数量:\(dataList.count)")
        let dict = [
            "dataList":dataList
        ]
        self.historyStreamHandler?.event?(dict)
    }

}

extension PPLefuBleConnectManager:PPBluetoothUpdateStateDelegate,PPBluetoothSurroundDeviceDelegate{

    func centralManagerDidUpdate(_ state: PPBluetoothState) {
        self.bluetoothState = state
        
        self.loggerStreamHandler?.event?("蓝牙状态:\(state)")
        
        if (self.needScan && state == .poweredOn) {
            
            self.needScan = false
            self.scaleManager.searchSurroundDevice()
            
        } else if (state == .poweredOff) {
            self.needScan = false
        }
        
    }
    
    func centralManagerDidFoundSurroundDevice(_ device: PPBluetoothAdvDeviceModel!, andPeripheral peripheral: CBPeripheral!) {
        
        if self.scanType == .scan {

            let dict:[String:Any] = self.convertDeviceDict(device)
            
            self.scanResultStreamHandler?.event?(dict)
            
        } else if self.scanType == .connect, self.needConnectMac == device.deviceMac {
            
            self.stopScan()
            
            self.currentDevice = device
            self.scaleManager.connectDelegate = self
            
            self.loggerStreamHandler?.event?("开始连接设备:\(device.deviceName) mac:\(device.deviceMac) \(device.peripheralType)")
            
            if device.peripheralType == .peripheralApple {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.appleControl = PPBluetoothPeripheralApple(peripheral: peripheral, andDevice: device)
                self.appleControl?.serviceDelegate = self
                self.appleControl?.cmdDelegate = self
            }
            
            
        }
        
    }

}


extension PPLefuBleConnectManager:PPBluetoothConnectDelegate{
    
    
    func centralManagerDidConnect() {

        self.current180A = nil
        
        if self.currentDevice?.peripheralType == .peripheralApple {
            
            self.appleControl?.discoverDeviceInfoService({[weak self] model in
                guard let `self` = self else {
                    return
                }
                
                self.current180A = model
                
                self.appleControl?.discoverFFF0Service()

            })
        }

    }
    
    func centralManagerDidDisconnect() {
        self.sendConnectState(0)
    }
    
    func centralManagerDidFail(toConnect error: (any Error)!) {
        self.sendConnectState(2)
    }
    
}

extension PPLefuBleConnectManager: PPBluetoothServiceDelegate{
    
    func discoverDeviceInfoServiceSuccess(_ device: PPBluetooth180ADeviceModel!) {

    }
    
    func discoverFFF0ServiceSuccess() {
        self.sendConnectState(1)
        
        self.loggerStreamHandler?.event?("发现FFF0成功")
        
        if self.currentDevice?.peripheralType == .peripheralApple {
            
            self.appleControl?.scaleDataDelegate = self
        }
    }
    
}

extension PPLefuBleConnectManager: PPBluetoothCMDDataDelegate{
    
    func syncDeviceHistorySuccess() { //同步历史数据成功
        
        if let models = self.tempScaleHistoryList {
            var array:[[String:Any]] = []
            
            for model in models {
                let dict = self.convertMeasurementDict(model)
                array.append(dict)
            }

            self.sendHistoryData(dataList: array)
        }
        
        self.tempScaleHistoryList = []
    }
    
    func syncDeviceTimeSuccess() {

    }
    
    func deleteDeviceHistoryDataSuccess() {

    }
    
    func deviceWillDisconnect() {
        
    }
    
    func monitorBatteryInfoChange(_ model: PPBatteryInfoModel!, advModel: PPBluetoothAdvDeviceModel!) {
        
        let dict:[String:Any?] = ["power":model.power]
        let filtedDict = dict.compactMapValues { $0 }
        
        self.batteryStreamHandler?.event?(filtedDict)
    }
}

extension PPLefuBleConnectManager:PPBluetoothScaleDataDelegate{
    
    func monitorProcessData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        
        // 0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
        var measurementState = 0
        if model.isHeartRating {
            
            measurementState = 2
        } else if model.isFatting {
            
            measurementState = 1
        }
        
        self.sendMeasureData(model, advModel: advModel, measureState: measurementState)
    }
    
    func monitorLockData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        
        //0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
        let measurementState = 10
        
        self.sendMeasureData(model, advModel: advModel, measureState: measurementState)
    }
    
    
    func monitorHistoryData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        self.tempScaleHistoryList?.append(model)
    }
    
}
