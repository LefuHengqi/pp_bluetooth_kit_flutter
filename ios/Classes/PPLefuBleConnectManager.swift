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

class PPLefuBleConnectManager:NSObject {
    
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
    private var currentDevice: PPBluetoothAdvDeviceModel?
    private var current180A:PPBluetooth180ADeviceModel?
    private var connectState:Int = 0
    private var tempScaleHistoryList : Array<PPBluetoothScaleBaseModel>?
    
    private var appleControl : PPBluetoothPeripheralApple?
    private var coconutControl : PPBluetoothPeripheralCoconut?
    private var torreControl : PPBluetoothPeripheralTorre?
    
    private var unzipFilePath : String?
    private var dfuConfig : PPDfuPackageModel?
    private var isScaning:Bool = false
    
    private var tempDeviceDict = [String:(PPBluetoothAdvDeviceModel,CBPeripheral)]()
    
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

            }
            
        } else {
            
            self.loggerStreamHandler?.event?("找不到设备-\(deviceMac)")
            sendConnectState(2)
            
        }
        
        
    }
    
    
    func stopScan() {
        
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
        
        self.clearData()
    }
    
    func clearData() {
        
        self.appleControl = nil
        self.coconutControl = nil
        
        self.needScan = false
        self.currentDevice = nil
        self.current180A = nil
    }
    
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

        if currentDevice.peripheralType == .peripheralApple {
            self.tempScaleHistoryList = []
            self.appleControl?.fetchDeviceHistoryData()
        } else if currentDevice.peripheralType == .peripheralCoconut {
            self.tempScaleHistoryList = []
            self.coconutControl?.fetchDeviceHistoryData()
        } else if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.dataFetchHistoryData(model, withHandler: {[weak self] models in
                guard let `self` = self else {
                    return
                }
                
                self.sendHistoryData(models)
            })
        }
    }
    
    func deleteHistory() {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.deleteDeviceHistoryData(handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                self.loggerStreamHandler?.event?("删除历史数据-状态:\(state)")
            })
        } else if currentDevice.peripheralType == .peripheralCoconut {
            self.coconutControl?.deleteDeviceHistoryData()
            self.loggerStreamHandler?.event?("Coconut删除历史数据")
        }
    }
    
    func syncUnit(model:PPBluetoothDeviceSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            return
        }

        if currentDevice.peripheralType == .peripheralApple {
            
            self.appleControl?.syncDeviceSetting(model)
            self.sendCommonState(true, callBack: callBack)
        } else if currentDevice.peripheralType == .peripheralCoconut {
            
            self.coconutControl?.syncDeviceSetting(model)
            self.sendCommonState(true, callBack: callBack)
        } else if currentDevice.peripheralType == .peripheralTorre {
            let unit = model.unit
            self.torreControl?.codeChange(unit, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                self.loggerStreamHandler?.event?("Torre-同步单位状态:\(status)")
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        } else {
            
            sendCommonState(false, callBack: callBack)
            
        }
    }
    
    func syncTime(is24Hour:Bool, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack(["state":0])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralApple {
            self.appleControl?.syncDeviceTime(handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                
                self.sendCommonState(success, callBack: callBack)
            })
        } else if currentDevice.peripheralType == .peripheralCoconut {
            self.coconutControl?.syncDeviceTime()
            self.loggerStreamHandler?.event?("Coconut同步时间")
            let param = ["state":1]
            
            callBack(param)
        } else if currentDevice.peripheralType == .peripheralTorre {
            let code:Int = is24Hour ? 0 : 1;
            let format = PPTimeFormat(rawValue: code) ?? .format24HourClock
            self.torreControl?.codeSyncTime(with: format, handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
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
                
                
                self.appleControl?.configNetWork(withSSID: ssId, password: password, handler: {[weak self] sn, configState in
                    guard let `self` = self else {
                        return
                    }
                    let success:Bool = configState == .success

                    self.sendWIFIResult(isSuccess: success, sn: sn, errorCode: Int(configState.rawValue), callBack: callBack)
                    
                })
                
            })
            
        } else if currentDevice.peripheralType == .peripheralTorre {
            let wifi = PPWifiInfoModel()
            wifi.ssid = ssId
            wifi.password = password
            self.torreControl?.dataConfigNetWork(wifi, domain: domain, withHandler: {[weak self] state, data in
                guard let `self` = self else {
                    return
                }
                
                let isSuccess = state == .registSuccess
                let errorCode = state.rawValue
                self.sendWIFIResult(isSuccess: isSuccess, sn: nil, errorCode: Int(errorCode), callBack: callBack);
                
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
            self.appleControl?.queryWifiConfig(handler: {[weak self] model in
                guard let `self` = self else {
                    return
                }
                
                let ssId = model?.ssid
                let connected = (ssId?.count ?? 0) > 0
                
                self.sendWIFISSID(ssId, isConnectWIFI: connected, callBack: callBack)
            })
        } else if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.codeFetchWifiConfig({[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let connected = state == 1
                
                self.sendWIFISSID(nil, isConnectWIFI: connected, callBack: callBack)
            })
        }
    }
    
    func fetchWifiMac(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.codeFetchWifiMac({ wifiMac in
                
                let dict:[String:Any?] = ["wifiMac":wifiMac]
                let filtedDict:[String:Any] = dict.compactMapValues { $0 }
                
                callBack(filtedDict);
                
            })
        }
    }
    
    func scanWifiNetworks(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.dataFindSurroundDevice({[weak self] wifiList in
                guard let `self` = self else {
                    return
                }
                
                self.sendWifiList(wifiList, callBack: callBack)
                
            })
        }
    }
    
    func wifiOTA(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.codeOtaUpdate(handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendWifiOTA(isSuccess: success, errorCode: state, callBack: callBack)
                
            })
        }
    }
    
    func heartRateSwitchControl(open:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            if open {
                
                self.torreControl?.codeOpenHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.torreControl?.codeCloseHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        }
    }
    
    func fetchHeartRateSwitch(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeFetchHeartRateSwitch({ state in
                
                let success = state == 0
                callBack(["open":success])
            })
        }
    }
    
    func impedanceSwitchControl(open:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            if open {
                
                self.torreControl?.codeOpenImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.torreControl?.codeCloseImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        }
    }
    
    func fetchImpedanceSwitch(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.fetchImpedanceTestMode({ open in
                
                let open = open == 0
                callBack(["open":open])
            })
        }
    }
    
    func setBindingState(binding:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            if binding {
                
                self.torreControl?.codeSetBindingState({[weak self] status in
                    guard let `self` = self else {
                        return
                    }
                    
                    let success = status == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else {
                
                self.torreControl?.codeSetUnbindingState({[weak self] status in
                    guard let `self` = self else {
                        return
                    }
                    
                    let success = status == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        }
    }
    
    func fetchBindingState(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeFetchBindingState({ status in
                
                let binding = status == 1
                callBack(["binding":binding])
            })
        }
    }
    
    func setScreenBrightness(_ brightness:Int, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeSetScreenLuminance(brightness, handler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        }
    }
    
    func getScreenBrightness(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeFetchScreenLuminance({ brightness in
                let dict = [
                    "brightness":brightness
                ]
                callBack(dict)
            })
        }
    }
    
    func syncUserInfo(_ info:PPTorreSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.dataSyncUserInfo(info, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let successs = state == 0
                self.sendCommonState(successs, callBack: callBack)
            })
        }
    }
    
    
    func syncUserList(_ userList:[PPTorreSettingModel], callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.dataSyncUserList(userList, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let successs = state == 0
                self.sendCommonState(successs, callBack: callBack)
            })
        }
    }

    func fetchUserIDList(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.dataFetchUserID({[weak self] IDS in
                guard let `self` = self else {
                    return
                }
                
                let retDict = [
                    "userIDList":IDS
                ]
                
                callBack(retDict)
            })
        }
    }
    
    func selectUser(user:PPTorreSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.dataSelectUser(user, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        }
    }
    
    func deleteUser(user:PPTorreSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.dataDeleteUser(user, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        }
    }
    
    func startMeasure(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeStartMeasure({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        }
    }
    
    func stopMeasure(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeStopMeasure({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        }
    }
    
    
    func startBabyModel(step:Int, weight:Int, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeEnableBabyModel(step, weight: weight, withHandler: { [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        }
    }
    
    
    func exitBabyModel(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeExitBabyModel({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        }
    }
    
    func dfuStart(filePath:String, deviceFirmwareVersion:String, isForceCompleteUpdate:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            var deviceVersion = deviceFirmwareVersion
            if isForceCompleteUpdate {
                deviceVersion = "0.0.0"
            }
            
            if let desPath = PPLefuScaleTools.loadDFUZipFile(path: filePath){

                do {
                    
                    try traverseDirectory(desPath)
                } catch {
                    self.loggerStreamHandler?.event?("遍历压缩包异常: \(error)")
                    self.sendDfuResult(progress: 0, isSuccess: false)
                    
                    return
                }
                
                if let config = self.dfuConfig, let unzipPath = self.unzipFilePath {
                   
                    let mcuPath = "\(unzipPath)/\(config.packages.mcu?.filename ?? "")"
                    let blePath = "\(unzipPath)/\(config.packages.ble?.filename ?? "")"
                    let resPath = "\(unzipPath)/\(config.packages.res?.filename ?? "")"

                    let package = PPTorreDFUPackageModel()
                    package.mcuVersion = "000"
                    package.bleVersion = "000"
                    package.resVersion = "000"

                    package.mcuPath = mcuPath
                    package.blePath = blePath
                    package.resPath = resPath
                    
                    if (config.packages.mcu?.version.count ?? 0) > 0 {
                        package.mcuVersion = config.packages.mcu?.version ?? ""
                    }
                    
                    if (config.packages.ble?.version.count ?? 0) > 0 {
                        package.bleVersion = config.packages.ble?.version ?? ""
                    }

                    if (config.packages.res?.version.count ?? 0) > 0 {
                        package.resVersion = config.packages.res?.version ?? ""
                    }
                    
                    self.torreControl?.dataDFUStart { [weak self]  size in
                        
                        guard let `self` = self else {return}
                        let tSize = size
                        
                        self.torreControl?.dataDFUCheck({[weak self] status, fileType, version, offset in
                            guard let `self` = self else { return }
                            
                            let status = 1
                            
                            self.torreControl?.dataDFUSend(package, maxPacketSize: tSize, transferContinueStatus: status, deviceVersion: deviceVersion,handler: {[weak self] (progress, isSuccess) in
                                
                                guard let `self` = self else { return }
                                
                                self.sendDfuResult(progress: Float(progress), isSuccess: isSuccess)
                                
                            })
                            
                        })
                    }
                   
                } else {
                    
                    self.loggerStreamHandler?.event?("dfu失败-config或unzipPath为空")
                    self.sendDfuResult(progress: 0, isSuccess: false)
                }

            } else {
                
                self.loggerStreamHandler?.event?("解压路径为空")
                self.sendDfuResult(progress: 0, isSuccess: false)
            }
        }
    }
    
    func syncDeviceLog(logFolder:String) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.deviceLogStreamHandler?.event?(["isSuccess":false])
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.dataSyncLog(withLogFolder: logFolder, handler: {[weak self] progress, filePath, isFailed in
                guard let `self` = self else {
                    return
                }
                
                let dict:[String:Any?] = [
                    "isSuccess":!isFailed,
                    "progress":progress,
                    "filePath":filePath
                ]
                
                let filtedDict = dict.compactMapValues { $0 }
                self.deviceLogStreamHandler?.event?(filtedDict)
            })
            
        }
        
    }
    
    func keepAlive() {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.sendKeepAliveCode()
            
        }
        
    }
    
    func clearDeviceData(type:Int, callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeClearDeviceData(type, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
            
        }
        
    }
    
    func setDeviceLanguage(type:Int, callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            let lan = PPTorreLanguage(rawValue: UInt(type)) ?? .simplifiedChinese
            self.torreControl?.setLanguage(lan, completion: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
            
        }
        
    }
    
    func fetchDeviceLanguage(callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        if currentDevice.peripheralType == .peripheralTorre {
            
            self.torreControl?.getLanguageWithCompletion({ [weak self] (status, lang) in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                
                let dict:[String:Any?] = [
                    "type":lang.rawValue,
                    "state":success
                ]
                let filtedDict = dict.compactMapValues { $0 }
                
                callBack(filtedDict)
                
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
        } else if currentDevice.peripheralType == .peripheralCoconut {
            self.coconutControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
            
            return
        } else if currentDevice.peripheralType == .peripheralTorre {
            self.torreControl?.discoverDeviceInfoService({[weak self] model180A in
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
        } else if currentDevice.peripheralType == .peripheralCoconut {
            self.coconutControl?.fetchDeviceBatteryInfo()
        } else if currentDevice.peripheralType == .peripheralTorre {
            // 在代理方法中统一持续回调
            self.torreControl?.fetchDeviceBatteryInfo(completion: { power in
            })
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
    
    func traverseDirectory(_ path: String) throws {
        let fileManager = FileManager.default
        
        let files = try fileManager.contentsOfDirectory(atPath: path)
        for file in files {
            let fullPath = "\(path)/\(file)"
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // 如果是目录，则递归遍历
                    self.unzipFilePath = path + "/" + file
                    try traverseDirectory(fullPath)
                } else {
                    // 如果是文件，则输出文件名

                    if file == "package.json"{
                        let fileURL = URL(fileURLWithPath: fullPath)

                        // 读取 JSON 文件数据
                        let jsonData = try! Data(contentsOf: fileURL)

                        let decoder = JSONDecoder()
                        let config = try! decoder.decode(PPDfuPackageModel.self, from: jsonData)
                        self.dfuConfig = config
                        
                    }
                    
                }
            }
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
        let memberId = model.memberId
        
        let dict:[String:Any?] = [
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
        
        let filtedDict = dict.compactMapValues { $0 }
        
        return filtedDict
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
    
    func sendHistoryData(_ models:[PPBluetoothScaleBaseModel]) {
        
        var array:[[String:Any]] = []
        
        for model in models {
            let dict = self.convertMeasurementDict(model)
            array.append(dict)
        }

        let dataList = array
        
        
        self.loggerStreamHandler?.event?("历史数据-数量:\(dataList.count)")
        let dict = [
            "dataList":dataList
        ]
        self.historyStreamHandler?.event?(dict)
    }
    
    func sendBlePermissionState(state:PPBluetoothState) {
        
        var stateValue:Int = 0
        if state == .unauthorized {
            stateValue = 1
        } else if state == .poweredOn {
            stateValue = 2
        } else if state == .poweredOff {
            stateValue = 3
        }
        
        let dict:[String:Any] = [
            "state":stateValue
        ]
        
        self.blePermissionStreamHandler?.event?(dict)
    }
    
    func sendWIFIResult(isSuccess:Bool, sn:String?, errorCode:Int?, callBack: @escaping FlutterResult) {
        
        let dict:[String:Any?] = [
            "success":isSuccess,
            "errorCode":errorCode,
            "sn":sn
        ]
        
        let filtedDict = dict.compactMapValues { $0 }
        
        callBack(filtedDict)
    }
    
    func sendWIFISSID(_ ssId:String?, isConnectWIFI:Bool, callBack: @escaping FlutterResult) {
        
        let dict:[String:Any?] = ["ssId": ssId, "isConnectWIFI":isConnectWIFI]
        let filtedDict = dict.compactMapValues { $0 }
        
        callBack(filtedDict)
    }
    
    func sendWifiList(_ wifiList:[PPWifiInfoModel], callBack: @escaping FlutterResult) {
        
        var array = [String]()
        for model in wifiList {
            array.append(model.ssid)
        }
        let dict:[String:Any] = ["wifiList":array]
        callBack(dict)
    }
    
    func sendWifiOTA(isSuccess:Bool, errorCode:Int, callBack: @escaping FlutterResult) {

        let dict:[String:Any] = [
            "isSuccess":isSuccess,
            "errorCode":errorCode
        ]
        
        callBack(dict)
    }
    
    func sendCommonState(_ state:Bool, callBack: @escaping FlutterResult) {
        
        let dict:[String:Any] = [
            "state":state
        ]
        
        callBack(dict)
    }
    
    func sendDfuResult(progress:Float, isSuccess:Bool) {
        
        let dict:[String:Any] = [
            "progress":progress,
            "isSuccess":isSuccess,
        ]
        
        self.dfuStreamHandler?.event?(dict)
    }
    
    func sendScanState(scaning:Bool) {
        let code:Int = scaning ? 1 : 0
        self.scanStateStreamHandler?.event?(["state":code])
    }

}

extension PPLefuBleConnectManager:PPBluetoothUpdateStateDelegate,PPBluetoothSurroundDeviceDelegate{

    func centralManagerDidUpdate(_ state: PPBluetoothState) {
        
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
        }
        
    }
    
    func centralManagerDidFoundSurroundDevice(_ device: PPBluetoothAdvDeviceModel!, andPeripheral peripheral: CBPeripheral!) {
//        self.loggerStreamHandler?.event?("SDK中搜索到:\(device.deviceName) mac:\(device.deviceMac) \(device.peripheralType)")
        
        if self.scanType == .scan {
            
            self.tempDeviceDict[device.deviceMac] = (device,peripheral)

            let dict:[String:Any] = self.convertDeviceDict(device)
            
            self.scanResultStreamHandler?.event?(dict)
            
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
        } else if self.currentDevice?.peripheralType == .peripheralCoconut {
            
            self.coconutControl?.discoverFFF0Service()
        } else if self.currentDevice?.peripheralType == .peripheralTorre {
            
            self.torreControl?.discoverFFF0Service()
        }

    }
    
    func centralManagerDidDisconnect() {
        self.sendConnectState(0)
        self.clearData()
    }
    
    func centralManagerDidFail(toConnect error: (any Error)!) {
        self.sendConnectState(2)
        self.clearData()
    }
    
}

extension PPLefuBleConnectManager: PPBluetoothServiceDelegate{
    
    func discoverDeviceInfoServiceSuccess(_ device: PPBluetooth180ADeviceModel!) {

    }
    
    func discoverFFF0ServiceSuccess() {
        
        self.loggerStreamHandler?.event?("发现FFF0成功")
        
        if self.currentDevice?.peripheralType == .peripheralApple {
            
            self.appleControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        } else if self.currentDevice?.peripheralType == .peripheralCoconut {
            
            self.coconutControl?.scaleDataDelegate = self
            self.sendConnectState(1)
        } else if self.currentDevice?.peripheralType == .peripheralTorre {
            
            self.torreControl?.codeUpdateMTU({[weak self] mtu in
                guard let `self` = self else {
                    return
                }
                
                self.torreControl?.scaleDataDelegate = self
                self.sendConnectState(1)
            })
        }
    }
    
}

extension PPLefuBleConnectManager: PPBluetoothCMDDataDelegate{
    
    func syncDeviceHistorySuccess() { //同步历史数据成功
        
        if let models = self.tempScaleHistoryList {

            self.sendHistoryData(models)
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
