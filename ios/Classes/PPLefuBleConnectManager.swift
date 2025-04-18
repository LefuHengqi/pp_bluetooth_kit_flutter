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

}

public class PPLefuBleConnectManager:NSObject {
    
    var scanResultStreamHandler:PPLefuStreamHandler?
    var loggerStreamHandler:PPLefuStreamHandler?
    var connectStateStreamHandler:PPLefuStreamHandler?
    var measureStreamHandler:PPLefuStreamHandler?
    var historyStreamHandler:PPLefuStreamHandler?
    var batteryStreamHandler:PPLefuStreamHandler?
    var blePermissionStreamHandler:PPLefuStreamHandler?
    var dfuStreamHandler:PPLefuStreamHandler?
    var deviceLogStreamHandler:PPLefuStreamHandler?
    var scanStateStreamHandler:PPLefuStreamHandler?
    
    lazy var scaleManager:PPBluetoothConnectManager = PPBluetoothConnectManager()
    
    private var bluetoothState:PPBluetoothState?
    private var needScan = false
    private var scanType:PPLefuScanType = .scan
    private var isScaning:Bool = false

    private var connectState:Int = 0
    private var tempScaleHistoryList : Array<PPBluetoothScaleBaseModel>?
    
    var currentDevice: PPBluetoothAdvDeviceModel?
    var appleControl : PPBluetoothPeripheralApple?
    var coconutControl : PPBluetoothPeripheralCoconut?
    var torreControl : PPBluetoothPeripheralTorre?
    var iceControl : PPBluetoothPeripheralIce?
    var bananaControl : PPBluetoothPeripheralBanana?
    var jambulControl : PPBluetoothPeripheralJambul?
    var borreControl : PPBluetoothPeripheralBorre?
    var forreControl : PPBluetoothPeripheralForre?
    
    var unzipFilePath : String?
    var dfuConfig : PPDfuPackageModel?
    var current180A:PPBluetooth180ADeviceModel?

    
    private var tempDeviceDict = [String:(PPBluetoothAdvDeviceModel,CBPeripheral)]()
    
    override init() {
        super.init()
        
        PPLog.setLogEnable(false)
        PPLog.sharedInstance().logBlock = {[weak self] logStr in
            guard let `self` = self else {
                return
            }
            
            self.loggerStreamHandler?.event?(logStr)
            
        }
    }
    
    func startScan() {
        
        self.stopScan()
        self.disconnect()
        
        self.tempDeviceDict.removeAll()
        
        scanDevice(type: .scan)
    }
    
    func scanDevice(type:PPLefuScanType) {
        
        self.scanType = type
        self.needScan = true
        
        self.scaleManager = PPBluetoothConnectManager()
        self.scaleManager.updateStateDelegate = self
        self.scaleManager.surroundDeviceDelegate = self
    }
    
    func connectDevice(deviceMac:String, deviceName:String) {
        
        if self.currentDevice?.deviceMac == deviceMac {
            self.loggerStreamHandler?.event?("\(deviceMac)-该设备已连接，继续使用")
            sendConnectState(1)
            
            return
        }

        self.stopScan()
        self.disconnect()

        
        if let model = self.tempDeviceDict[deviceMac] {
            
            let device = model.0
            let peripheral = model.1
            
            self.currentDevice = device
            self.scaleManager.connectDelegate = self
            
            self.loggerStreamHandler?.event?("开始连接设备:\(device.deviceName) mac:\(device.deviceMac) \(device.peripheralType)")
            
            if device.peripheralType == .peripheralApple {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.appleControl = PPBluetoothPeripheralApple(peripheral: peripheral, andDevice: device)
                self.appleControl?.serviceDelegate = self
                self.appleControl?.cmdDelegate = self
            } else if device.peripheralType == .peripheralCoconut {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.coconutControl = PPBluetoothPeripheralCoconut(peripheral: peripheral, andDevice: device)
                self.coconutControl?.serviceDelegate = self
                self.coconutControl?.cmdDelegate = self
            } else if device.peripheralType == .peripheralTorre {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.torreControl = PPBluetoothPeripheralTorre(peripheral: peripheral, andDevice: device)
                self.torreControl?.serviceDelegate = self

            } else if device.peripheralType == .peripheralIce {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.iceControl = PPBluetoothPeripheralIce(peripheral: peripheral, andDevice: device)
                self.iceControl?.serviceDelegate = self

            } else if device.peripheralType == .peripheralBorre {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.borreControl = PPBluetoothPeripheralBorre(peripheral: peripheral, andDevice: device)
                self.borreControl?.serviceDelegate = self

            } else if device.peripheralType == .peripheralForre {
                
                self.scaleManager.connect(peripheral, withDevice: device)
                
                self.forreControl = PPBluetoothPeripheralForre(peripheral: peripheral, andDevice: device)
                self.forreControl?.serviceDelegate = self
            } else {
                
                self.loggerStreamHandler?.event?("不支持的设备类型-peripheralType:\(device.peripheralType)-\(deviceMac)")
                sendConnectState(2)
            }
            
        } else {
            
            self.loggerStreamHandler?.event?("找不到设备-\(deviceMac)")
            sendConnectState(2)
            
        }
        
        
    }
    
    
    func stopScan() {
        
        self.needScan = false
        self.scaleManager.stopSearch()
        
        if self.isScaning {
            self.isScaning = false
            sendScanState(scaning: false)
        }
    }
    
    func disconnect() {
        
        if let apple = self.appleControl?.peripheral {
            self.scaleManager.disconnect(apple)
        }
        if let coconut = self.coconutControl?.peripheral {
            self.scaleManager.disconnect(coconut)
        }
        if let torreControl = self.torreControl?.peripheral {
            self.scaleManager.disconnect(torreControl)
        }
        if let iceControl = self.iceControl?.peripheral {
            self.scaleManager.disconnect(iceControl)
        }
        if let borreControl = self.borreControl?.peripheral {
            self.scaleManager.disconnect(borreControl)
        }
        if let forreControl = self.forreControl?.peripheral {
            self.scaleManager.disconnect(forreControl)
        }
        
        self.clearData()
    }
    
    func clearData() {
        
        self.appleControl = nil
        self.coconutControl = nil
        self.torreControl = nil
        self.iceControl = nil
        self.borreControl = nil
        self.forreControl = nil
        
        self.bananaControl?.scaleDataDelegate = nil;
        self.bananaControl?.updateStateDelegate = nil;
        self.bananaControl?.stopSearch()
        
        self.jambulControl?.scaleDataDelegate = nil;
        self.jambulControl?.updateStateDelegate = nil;
        self.jambulControl?.stopSearch()
        
        self.needScan = false
        self.currentDevice = nil
        self.current180A = nil

    }
    
    /// 连接状态 0:断开连接 1:连接成功 2:连接错误
    func sendConnectState(_ state:Int) {
        self.loggerStreamHandler?.event?("连接状态:\(state)")
        
        self.connectState = state
        
        let mac = self.currentDevice?.deviceMac ?? ""
        let params:[String:Any] = [
            "deviceMac":mac,
            "state":state
        ]

        self.connectStateStreamHandler?.event?(params)
        
    }
    
    func fetchHistory(model:PPTorreSettingModel) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.tempScaleHistoryList = []
            self.appleControl?.fetchDeviceHistoryData()
        case .peripheralCoconut:
            self.tempScaleHistoryList = []
            self.coconutControl?.fetchDeviceHistoryData()
        case .peripheralTorre:
            self.torreControl?.dataFetchHistoryData(model, withHandler: {[weak self] models in
                guard let `self` = self else {
                    return
                }
                
                self.sendHistoryData(models)
            })
        case .peripheralIce:
            self.iceControl?.dataFetchHistoryData(handler: {[weak self] (models, error) in
                guard let `self` = self else {
                    return
                }
                self.sendHistoryData(models)
            })
        case .peripheralBorre:
            self.borreControl?.dataFetchHistoryData(model, withHandler: {[weak self] models in
                guard let `self` = self else {
                    return
                }
                
                self.sendHistoryData(models)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    func deleteHistory() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.deleteDeviceHistoryData(handler: {[weak self] state in
                guard self != nil else {
                    return
                }

            })
        case .peripheralCoconut:
            self.coconutControl?.deleteDeviceHistoryData()
        case .peripheralIce:
            self.iceControl?.deleteDeviceHistoryData()

        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    
    
    func fetchBatteryInfo() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.batteryStreamHandler?.event?(["power":0])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.fetchDeviceBatteryInfo()
        case .peripheralCoconut:
            self.coconutControl?.fetchDeviceBatteryInfo()
        case .peripheralTorre:
            // 在代理方法中统一持续回调
            self.torreControl?.fetchDeviceBatteryInfo(completion: { power in
            })
        case .peripheralIce:
            // 在代理方法中统一持续回调
            self.iceControl?.fetchDeviceBatteryInfo(completion: { power in
                
            })
        case .peripheralBorre:
            // 在代理方法中统一持续回调
            self.borreControl?.fetchDeviceBatteryInfo(completion: { power in
            })
        case .peripheralForre:
            // 在代理方法中统一持续回调
            self.forreControl?.fetchDeviceBatteryInfo(completion: { power in
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            self.batteryStreamHandler?.event?(["power":0])
        }
    }
    
    func resetDevice() {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.restoreFactory(handler: {
            })
        case .peripheralIce:
            self.iceControl?.restoreFactory(handler: {
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
        
    }
    
    func receiveBroadcastData(deviceMac:String, callBack: @escaping FlutterResult) {
        
        guard let device = self.tempDeviceDict[deviceMac] else {
            
            self.loggerStreamHandler?.event?("找不到当前设备")
            self.sendCommonState(false, callBack: callBack)
            return
        }
        
        let advDevice = device.0
        
        if advDevice.peripheralType != .peripheralBanana && advDevice.peripheralType != .peripheralJambul {
            
            self.loggerStreamHandler?.event?("\(advDevice.deviceName)-\(advDevice.deviceMac)不是广播秤")
            self.sendCommonState(false, callBack: callBack)
            return
        }
        
        if self.bluetoothState == .poweredOff {
            
            self.loggerStreamHandler?.event?("接收广播失败-蓝牙权限未打开")
            self.sendCommonState(false, callBack: callBack)
            return
            
        }
        
        
        self.disconnect()
        
        self.currentDevice = advDevice
        
        if advDevice.peripheralType == .peripheralBanana {
            
            let banana = PPBluetoothPeripheralBanana.init(device: advDevice)
            banana.updateStateDelegate = self
            banana.scaleDataDelegate = self
            self.bananaControl = banana
        } else if advDevice.peripheralType == .peripheralJambul {
            
            let jambul = PPBluetoothPeripheralJambul.init(device: advDevice)
            jambul.updateStateDelegate = self
            jambul.scaleDataDelegate = self
            self.jambulControl = jambul
        } else {
            
            self.currentDevice = nil
        }
        
    }
    
    func sendBroadcastData(cmd:String, unitType:PPDeviceUnit, callBack: @escaping FlutterResult) {
        
        guard let device = self.currentDevice else {
            
            self.loggerStreamHandler?.event?("当前设备为空")
            self.sendCommonState(false, callBack: callBack)
            return
        }
        
        if device.peripheralType == .peripheralJambul, let jambul = self.jambulControl {
            
            jambul.sendCBPeripheralDataCurrentUnit(unitType, scaleType: cmd)
            self.sendCommonState(true, callBack: callBack)
            
        } else {
            
            self.loggerStreamHandler?.event?("发送广播失败-jambul:\(String(describing: self.jambulControl))-peripheralType:\(device.peripheralType)")
            self.sendCommonState(false, callBack: callBack)
        }
        
    }
    
    
    
    func fetchConnectedDevice(callBack: @escaping FlutterResult) {
        if let device = self.currentDevice {
            
            let dict:[String:Any] = self.convertDeviceDict(device)
            callBack(dict)
            
        } else {
            
            callBack([:]);
        }
    }
    
    func addBlePermissionListener() {
        if let state = self.bluetoothState {
            
            self.sendBlePermissionState(state: state)
        } else {
            
            self.scaleManager = PPBluetoothConnectManager()
            self.scaleManager.updateStateDelegate = self
        }
    }

}

extension PPLefuBleConnectManager:PPBluetoothUpdateStateDelegate,PPBluetoothSurroundDeviceDelegate{

    public func centralManagerDidUpdate(_ state: PPBluetoothState) {
        
        if self.bluetoothState != state {
            
            self.sendBlePermissionState(state: state)
            
        }
        
        self.bluetoothState = state
        
        self.loggerStreamHandler?.event?("蓝牙状态:\(state)")
        
        if (self.needScan && state == .poweredOn) {
            
            self.needScan = false
            self.scaleManager.searchSurroundDevice()
            self.isScaning = true
            sendScanState(scaning: true)
            
        } else if (state == .poweredOff) {
            self.needScan = false
            
            if self.isScaning {
                self.isScaning = false
                sendScanState(scaning: false)
            }
        } else if (self.currentDevice != nil && state == .poweredOn) {
            
            let peripheralType = self.currentDevice?.peripheralType
            if peripheralType == .peripheralBanana {
                
                self.bananaControl?.receivedDeviceData()
            } else if peripheralType == .peripheralJambul {
                
                self.jambulControl?.receivedDeviceData()
            }
            
        }
        
    }
    
    public func centralManagerDidFoundSurroundDevice(_ device: PPBluetoothAdvDeviceModel!, andPeripheral peripheral: CBPeripheral!) {
//        self.loggerStreamHandler?.event?("SDK中搜索到:\(device.deviceName) mac:\(device.deviceMac) \(device.peripheralType)")
        
        if self.scanType == .scan {
            
            self.tempDeviceDict[device.deviceMac] = (device,peripheral)

            let dict:[String:Any] = self.convertDeviceDict(device)
            
            self.scanResultStreamHandler?.event?(dict)
            
        }
        
    }

}


extension PPLefuBleConnectManager:PPBluetoothConnectDelegate{
    
    
    public func centralManagerDidConnect() {

        self.current180A = nil
        
        if self.currentDevice?.peripheralType == .peripheralApple {
            
            self.appleControl?.discoverDeviceInfoService({[weak self] model in
                guard let `self` = self else {
                    return
                }
                
                self.current180A = model
                
                self.appleControl?.discoverFFF0Service()

            })
        } else if self.currentDevice?.peripheralType == .peripheralCoconut {
            
            self.coconutControl?.discoverFFF0Service()
        } else if self.currentDevice?.peripheralType == .peripheralTorre {
            
            self.torreControl?.discoverFFF0Service()
        } else if self.currentDevice?.peripheralType == .peripheralIce {
            
            self.iceControl?.discoverFFF0Service()
        } else if self.currentDevice?.peripheralType == .peripheralBorre {
            
            self.borreControl?.discoverFFF0Service()
        } else if self.currentDevice?.peripheralType == .peripheralForre {
            
            self.forreControl?.discoverFFF0Service()
        }

    }
    
    public func centralManagerDidDisconnect() {
        self.sendConnectState(0)
        self.clearData()
    }
    
    public func centralManagerDidFail(toConnect error: (any Error)!) {
        self.sendConnectState(2)
        self.clearData()
    }
    
}

extension PPLefuBleConnectManager: PPBluetoothServiceDelegate{
    
    func discoverDeviceInfoServiceSuccess(_ device: PPBluetooth180ADeviceModel!) {

    }
    
    public func discoverFFF0ServiceSuccess() {
        
        self.loggerStreamHandler?.event?("发现FFF0成功")
        
        let peripheralType = self.currentDevice?.peripheralType
        switch peripheralType {
        case .peripheralApple:
            self.appleControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralCoconut:
            self.coconutControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralTorre:
            self.torreControl?.codeUpdateMTU({[weak self] mtu in
                guard let `self` = self else {
                    return
                }
                
                self.torreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        case .peripheralIce:
            self.iceControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        case .peripheralBorre:
            self.borreControl?.codeUpdateMTU({[weak self] mtu in
                guard let `self` = self else {
                    return
                }
                
                self.borreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        case .peripheralForre:
            self.forreControl?.codeUpdateMTU({[weak self] mtu in
                guard let `self` = self else {
                    return
                }
                
                self.forreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        default:
            self.loggerStreamHandler?.event?("未知类型:\(String(describing: peripheralType))")
        }
        
    }
    
}

extension PPLefuBleConnectManager: PPBluetoothCMDDataDelegate{
    
    public func syncDeviceHistorySuccess() { //同步历史数据成功
        
        if let models = self.tempScaleHistoryList {

            self.sendHistoryData(models)
        }
        
        self.tempScaleHistoryList = []
    }
    
    public func syncDeviceTimeSuccess() {

    }
    
    public func deleteDeviceHistoryDataSuccess() {

    }
    
    public func deviceWillDisconnect() {
        
    }
    
    public func monitorBatteryInfoChange(_ model: PPBatteryInfoModel!, advModel: PPBluetoothAdvDeviceModel!) {
        
        let dict:[String:Any?] = ["power":model.power]
        let filtedDict = dict.compactMapValues { $0 }
        
        self.batteryStreamHandler?.event?(filtedDict)
    }
}

extension PPLefuBleConnectManager:PPBluetoothScaleDataDelegate{
    
    public func monitorProcessData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        
        // 0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
        var measurementState = 0
        if model.isHeartRating {
            
            measurementState = 2
        } else if model.isFatting {
            
            measurementState = 1
        }
        
        self.sendMeasureData(model, advModel: advModel, measureState: measurementState)
    }
    
    public func monitorLockData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        
        //0:过程数据，1:体脂测量中（部分设备无此状态），2:心率测量中，10:测量完成（获取阻抗、心率等数据进行身体数据计算）
        let measurementState = 10
        
        self.sendMeasureData(model, advModel: advModel, measureState: measurementState)
    }
    
    
    public func monitorHistoryData(_ model: PPBluetoothScaleBaseModel!, advModel: PPBluetoothAdvDeviceModel!) {
        self.tempScaleHistoryList?.append(model)
    }
    
}
