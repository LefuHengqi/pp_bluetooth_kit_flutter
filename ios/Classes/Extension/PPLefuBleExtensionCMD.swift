//
//  PPLefuBleExtensionCMD.swift
//  Pods
//
//  Created by lefu on 2025/4/16
//  


import Foundation
import PPBaseKit
import PPBluetoothKit
import Flutter

extension PPLefuBleConnectManager {

    func syncUnit(model:PPBluetoothDeviceSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.sendCommonState(false, callBack: callBack)
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.syncDeviceSetting(model)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sendCommonState(true, callBack: callBack)
            }
        case .peripheralCoconut:
            self.coconutControl?.syncDeviceSetting(model)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sendCommonState(true, callBack: callBack)
            }
        case .peripheralTorre:
            let unit = model.unit
            self.torreControl?.codeChange(unit, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralIce:
            let unit = model.unit
            self.iceControl?.change(unit, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralBorre:
            let unit = model.unit
            self.borreControl?.codeChange(unit, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralForre:
            let unit = model.unit
            self.forreControl?.codeChange(unit, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralFish:
            let unit = model.unit
            self.fishControl?.change(unit)
            self.sendCommonState(true, callBack: callBack)
            
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            sendCommonState(false, callBack: callBack)
        }

    }
    
    func syncTime(is24Hour:Bool, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.sendCommonState(false, callBack: callBack)
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.syncDeviceTime(handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralCoconut:
            self.coconutControl?.syncDeviceTime()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sendCommonState(true, callBack: callBack)
            }
        case .peripheralTorre:
            let code:Int = is24Hour ? 0 : 1;
            let format = PPTimeFormat(rawValue: code) ?? .format24HourClock
            self.torreControl?.codeSyncTime(with: format, handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralIce:
            self.iceControl?.syncTime({[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralBorre:
            let code:Int = is24Hour ? 0 : 1;
            let format = PPTimeFormat(rawValue: code) ?? .format24HourClock
            self.borreControl?.codeSyncTime(with: format, handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralForre:
            let code:Int = is24Hour ? 0 : 1;
            let format = PPTimeFormat(rawValue: code) ?? .format24HourClock
            self.forreControl?.codeSyncTime(with: format, handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralFish:
            let date = Date()
            self.fishControl?.syncTime(date)
            self.sendCommonState(true, callBack: callBack)
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            sendCommonState(false, callBack: callBack)
        }
        
    }
    
    func configWifi(domain:String, ssId:String, password:String, callBack: @escaping FlutterResult) {

        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack(["success":false,"errorCode":-1])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
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
        case .peripheralTorre:
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
        case .peripheralIce:
            self.iceControl?.changeDNS(domain, withReciveDataHandler: { [weak self] isSuccess in
                guard let `self` = self else {
                    return
                }
                
                if !isSuccess {
                    self.loggerStreamHandler?.event?("配置域名失败-ICE")
                    self.sendWIFIResult(isSuccess: false, sn: nil, errorCode: -1, callBack: callBack);
                    
                    return
                }
                
                let wifi = PPWifiInfoModel()
                wifi.ssid = ssId
                wifi.password = password
                
                self.iceControl?.dataConfigNetWork(wifi, withHandler: {[weak self] (isSuccess, sn) in
                    guard let `self` = self else {
                        return
                    }
                    
                    let isSuccess = isSuccess
 
                    self.sendWIFIResult(isSuccess: isSuccess, sn: sn, errorCode: nil, callBack: callBack);
                })
                
            })
        case .peripheralBorre:
            let wifi = PPWifiInfoModel()
            wifi.ssid = ssId
            wifi.password = password
            self.borreControl?.dataConfigNetWork(wifi, domain: domain, withHandler: {[weak self] state, data in
                guard let `self` = self else {
                    return
                }
                
                let isSuccess = state == .registSuccess
                let errorCode = state.rawValue
                self.sendWIFIResult(isSuccess: isSuccess, sn: nil, errorCode: Int(errorCode), callBack: callBack);
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack(["success":false,"errorCode":-1])
        }
        
    }
    
    func fetchWifiInfo(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.queryWifiConfig(handler: {[weak self] model in
                guard let `self` = self else {
                    return
                }
                
                let ssId = model?.ssid
                let connected = (ssId?.count ?? 0) > 0
                
                self.sendWIFISSID(ssId, isConnectWIFI: connected, callBack: callBack)
            })
        case .peripheralTorre:
            self.torreControl?.dataFetchConfigNetworkSSID({ ssID in
                if ssID == nil || ssID.isEmpty {
                    self.sendWIFISSID(nil, isConnectWIFI: false, callBack: callBack)
                    return
                }
                
                self.sendWIFISSID(ssID, isConnectWIFI: true, callBack: callBack)
                
            })
            
        case .peripheralBorre:
            self.borreControl?.dataFetchConfigNetworkSSID({ ssID in
                if ssID == nil || ssID.isEmpty {
                    self.sendWIFISSID(nil, isConnectWIFI: false, callBack: callBack)
                    return
                }
                
                self.sendWIFISSID(ssID, isConnectWIFI: true, callBack: callBack)
                
            })

        case .peripheralIce:
            self.iceControl?.queryWifiConfig(handler: {[weak self] wifiInfo in
                guard let `self` = self else {
                    return
                }
                
                let ssId = wifiInfo?.ssid
                let connected = (ssId?.count ?? 0) > 0
                
                self.sendWIFISSID(ssId, isConnectWIFI: connected, callBack: callBack)
            })
        case .peripheralBorre:
            self.borreControl?.codeFetchWifiConfig({[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let connected = state == 1
                
                self.sendWIFISSID("", isConnectWIFI: connected, callBack: callBack)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }

    }
    
    func fetchWifiMac(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeFetchWifiMac({ wifiMac in
                
                let dict:[String:Any?] = ["wifiMac":wifiMac]
                let filtedDict:[String:Any] = dict.compactMapValues { $0 }
                
                callBack(filtedDict);
                
            })
        case .peripheralBorre:
            self.borreControl?.codeFetchWifiMac({ wifiMac in
                
                let dict:[String:Any?] = ["wifiMac":wifiMac]
                let filtedDict:[String:Any] = dict.compactMapValues { $0 }
                
                callBack(filtedDict);
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }

    }
    
    func scanWifiNetworks(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataFindSurroundDevice({[weak self] wifiList in
                guard let `self` = self else {
                    return
                }
                
                self.sendWifiList(wifiList, callBack: callBack)
                
            })
        case .peripheralIce:
            self.iceControl?.dataFindSurroundDevice({[weak self] (wifiList, status) in
                guard let `self` = self else {
                    return
                }
                
                self.sendWifiList(wifiList, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.dataFindSurroundDevice({[weak self] wifiList in
                guard let `self` = self else {
                    return
                }
                
                self.sendWifiList(wifiList, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func wifiOTA(_ callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeOtaUpdate(handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendWifiOTA(isSuccess: success, errorCode: state, callBack: callBack)
                
            })
        case .peripheralIce:
            self.iceControl?.otaAction(reciveHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendWifiOTA(isSuccess: success, errorCode: Int(state), callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.codeOtaUpdate(handler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendWifiOTA(isSuccess: success, errorCode: state, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func heartRateSwitchControl(open:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
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
        case .peripheralIce:
            if open {
                
                self.iceControl?.openHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.iceControl?.closeHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        case .peripheralBorre:
            if open {
                
                self.borreControl?.codeOpenHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.borreControl?.codeCloseHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        case .peripheralForre:
            if open {
                
                self.forreControl?.codeOpenHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.forreControl?.codeCloseHeartRateSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func fetchHeartRateSwitch(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeFetchHeartRateSwitch({ state in
                
                let success = state == 0
                callBack(["open":success])
            })
        case .peripheralIce:
            self.iceControl?.fetchHeartRateSwitchAndImpedanceSwitchState({[weak self] (heartRateStatus, impedanceStatus) in
                guard self != nil else {
                    return
                }
                
                let open = heartRateStatus == 0
                callBack(["open":open])
            })
        case .peripheralBorre:
            self.borreControl?.codeFetchHeartRateSwitch({ state in
                
                let success = state == 0
                callBack(["open":success])
            })
        case .peripheralForre:
            self.forreControl?.codeFetchHeartRateSwitch({ state in
                
                let success = state == 0
                callBack(["open":success])
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func impedanceSwitchControl(open:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
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
        case .peripheralIce:
            if open {
                
                self.iceControl?.openImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.iceControl?.closeImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        case .peripheralBorre:
            if open {
                
                self.borreControl?.codeOpenImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.borreControl?.codeCloseImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        case .peripheralForre:
            if open {
                
                self.forreControl?.codeOpenImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else  {
                
                self.forreControl?.codeCloseImpedanceSwitch({[weak self] state in
                    guard let `self` = self else {
                        return
                    }
                    let success = state == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func fetchImpedanceSwitch(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeFetchImpedanceSwitch({ open in
                
                let open = open == 0
                callBack(["open":open])
            })
        case .peripheralIce:
            self.iceControl?.fetchHeartRateSwitchAndImpedanceSwitchState({[weak self] (heartRateStatus, impedanceStatus) in
                guard self != nil else {
                    return
                }
                
                let open = impedanceStatus == 0
                callBack(["open":open])
            })
        case .peripheralBorre:
            self.borreControl?.codeFetchImpedanceSwitch({ open in
                
                let open = open == 0
                callBack(["open":open])
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func setBindingState(binding:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
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
        case .peripheralBorre:
            if binding {
                
                self.borreControl?.codeSetBindingState({[weak self] status in
                    guard let `self` = self else {
                        return
                    }
                    
                    let success = status == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            } else {
                
                self.borreControl?.codeSetUnbindingState({[weak self] status in
                    guard let `self` = self else {
                        return
                    }
                    
                    let success = status == 0
                    self.sendCommonState(success, callBack: callBack)
                })
            }
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func fetchBindingState(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeFetchBindingState({ status in
                
                let binding = status == 1
                callBack(["binding":binding])
            })
        case .peripheralBorre:
            self.borreControl?.codeFetchBindingState({ status in
                
                let binding = status == 1
                callBack(["binding":binding])
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func setScreenBrightness(_ brightness:Int, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeSetScreenLuminance(brightness, handler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralBorre:
            self.borreControl?.codeSetScreenLuminance(brightness, handler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func getScreenBrightness(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeFetchScreenLuminance({ brightness in
                let dict = [
                    "brightness":brightness
                ]
                callBack(dict)
            })
        case .peripheralBorre:
            self.borreControl?.codeFetchScreenLuminance({ brightness in
                let dict = [
                    "brightness":brightness
                ]
                callBack(dict)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func syncUserInfo(_ info:PPTorreSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataSyncUserInfo(info, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let successs = state == 0
                self.sendCommonState(successs, callBack: callBack)
            })
        case .peripheralBorre:
            self.borreControl?.dataSyncUserInfo(info, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let successs = state == 0
                self.sendCommonState(successs, callBack: callBack)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }

    func syncUserList(_ userList:[PPTorreSettingModel], callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataSyncUserList(userList, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let successs = state == 0
                self.sendCommonState(successs, callBack: callBack)
            })
        case .peripheralBorre:
            self.borreControl?.dataSyncUserList(userList, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let successs = state == 0
                self.sendCommonState(successs, callBack: callBack)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }

    func fetchUserIDList(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataFetchUserID({[weak self] IDS in
                guard self != nil else {
                    return
                }
                
                let retDict = [
                    "userIDList":IDS
                ]
                
                callBack(retDict)
            })
        case .peripheralBorre:
            self.borreControl?.dataFetchUserID({[weak self] IDS in
                guard self != nil else {
                    return
                }
                
                let retDict = [
                    "userIDList":IDS
                ]
                
                callBack(retDict)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func selectUser(user:PPTorreSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataSelectUser(user, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.dataSelectUser(user, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func deleteUser(user:PPTorreSettingModel, callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataDeleteUser(user, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.dataDeleteUser(user, withHandler: {[weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func startMeasure(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeStartMeasure({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.codeStartMeasure({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func stopMeasure(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeStopMeasure({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.codeStopMeasure({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }

    }
    
    
    func startBabyModel(step:Int, weight:Int, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeEnableBabyModel(step, weight: weight, withHandler: { [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralIce:
            self.iceControl?.enterBabyMode(handler: { [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.codeEnableBabyModel(step, weight: weight, withHandler: { [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    
    func exitBabyModel(_ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeExitBabyModel({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralIce:
            self.iceControl?.exitBabyMode(handler: { [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        case .peripheralBorre:
            self.borreControl?.codeExitBabyModel({ [weak self] status in
                guard let `self` = self else {
                    return
                }
                
                let success = status == 0
                self.sendCommonState(success, callBack: callBack)
                
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    func startDFU(filePath:String, deviceFirmwareVersion:String, isForceCompleteUpdate:Bool, _ callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        
        var deviceVersion = deviceFirmwareVersion
        if isForceCompleteUpdate {
            deviceVersion = "0.0.0"
        }
        
        let dotCount = deviceVersion.filter { $0 == "." }.count
        if dotCount < 3 {
            for _ in 0..<(3 - dotCount) {
                deviceVersion = deviceVersion + ".001"
            }
            
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
                
                switch currentDevice.peripheralType {
                case .peripheralTorre:
                    self.startDFUTorre(package: package, deviceVersion: deviceVersion, callBack)
                case .peripheralForre:
                    self.startDFUForre(package: package, deviceVersion: deviceVersion, callBack)
                case .peripheralBorre:
                    self.startDFUBorre(package: package, deviceVersion: deviceVersion, callBack)
                default:
                    self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
                    callBack([:])
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

    func syncDeviceLog(logFolder:String) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            self.deviceLogStreamHandler?.event?(["isSuccess":false])
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataSyncLog(withLogFolder: logFolder, handler: {[weak self] progress, filePath, isFailed in
                guard let `self` = self else {
                    return
                }
                
                let dict:[String:Any?] = [
                    "isFailed":isFailed,
                    "progress":progress,
                    "filePath":filePath
                ]
                
                let filtedDict = dict.compactMapValues { $0 }
                self.deviceLogStreamHandler?.event?(filtedDict)
            })
        case .peripheralIce:
            self.iceControl?.dataSyncLog(withLogFolder: logFolder, handler: {[weak self] progress, filePath, isFailed in
                guard let `self` = self else {
                    return
                }
                
                let dict:[String:Any?] = [
                    "isFailed":isFailed,
                    "progress":progress,
                    "filePath":filePath
                ]
                
                let filtedDict = dict.compactMapValues { $0 }
                self.deviceLogStreamHandler?.event?(filtedDict)
            })
        case .peripheralBorre:
            self.borreControl?.dataSyncLog(withLogFolder: logFolder, handler: {[weak self] progress, filePath, isFailed in
                guard let `self` = self else {
                    return
                }
                
                let dict:[String:Any?] = [
                    "isFailed":isFailed,
                    "progress":progress,
                    "filePath":filePath
                ]
                
                let filtedDict = dict.compactMapValues { $0 }
                self.deviceLogStreamHandler?.event?(filtedDict)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            self.deviceLogStreamHandler?.event?(["isSuccess":false])
        }
    }
    
    func keepAlive() {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.sendKeepAliveCode()
        case .peripheralIce:
            self.iceControl?.sendKeepAliveCode()
        case .peripheralBorre:
            self.borreControl?.sendKeepAliveCode()
        case .peripheralForre:
            self.forreControl?.sendKeepAliveCode()
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    func clearDeviceData(type:Int, callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.codeClearDeviceData(type, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralBorre:
            self.borreControl?.codeClearDeviceData(type, withHandler: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    func setDeviceLanguage(type:Int, callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            let lan = PPTorreLanguage(rawValue: UInt(type)) ?? .simplifiedChinese
            self.torreControl?.setLanguage(lan, completion: {[weak self] state in
                guard let `self` = self else {
                    return
                }
                
                let success = state == 0
                self.sendCommonState(success, callBack: callBack)
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    func fetchDeviceLanguage(callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.getLanguageWithCompletion({ [weak self] (status, lang) in
                guard self != nil else {
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
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
 
    }
    
    func setDisplayBodyFat(_ bodyFat:Int, callBack: @escaping FlutterResult) {
        
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            
            return
        }
        
        switch currentDevice.peripheralType {
        case .peripheralIce:
            self.iceControl?.writeBodyFat(Int32(bodyFat))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sendCommonState(true, callBack: callBack)
            }
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    func exitScanWifiNetworks(callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralIce:
            self.iceControl?.exitWifiQuery()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.sendCommonState(true, callBack: callBack)
            }
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
        }
    }
    
    
    func exitNetworkConfig(callBack: @escaping FlutterResult) {
        guard let currentDevice = self.currentDevice else {
            self.loggerStreamHandler?.event?("当前无连接设备")
            callBack([:])
            
            return
        }
        switch currentDevice.peripheralType {
        case .peripheralTorre:
            self.torreControl?.dataExitWifiConfig({[weak self] stauts in
                guard let `self` = self else {
                    return
                }
                
                let success = stauts == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralBorre:
            self.borreControl?.dataExitWifiConfig({[weak self] stauts in
                guard let `self` = self else {
                    return
                }
                
                let success = stauts == 0
                self.sendCommonState(success, callBack: callBack)
            })
        case .peripheralIce:
            self.iceControl?.exitWifiConfig();
            self.sendCommonState(true, callBack: callBack)
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
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
        
        switch currentDevice.peripheralType {
        case .peripheralApple:
            self.appleControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        case .peripheralCoconut:
            self.coconutControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        case .peripheralTorre:
            self.torreControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        case .peripheralIce:
            self.iceControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        case .peripheralBorre:
            self.borreControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        case .peripheralForre:
            self.forreControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        case .peripheralFish:
            self.fishControl?.discoverDeviceInfoService({[weak self] model180A in
                guard let `self` = self else {
                    return
                }
                
                let dict = self.convert180A(model: model180A)
                
                callBack(dict);
            })
        default:
            self.loggerStreamHandler?.event?("不支持的设备类型-\(currentDevice.peripheralType)")
            callBack([:])
        }
    }
    
    private func traverseDirectory(_ path: String) throws {
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
    
    private func startDFUTorre(package:PPTorreDFUPackageModel, deviceVersion:String, _ callBack: @escaping FlutterResult) {
        
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
    }
    
    
    private func startDFUBorre(package:PPTorreDFUPackageModel, deviceVersion:String, _ callBack: @escaping FlutterResult) {
        
        self.borreControl?.dataDFUStart { [weak self]  size in
            
            guard let `self` = self else {return}
            let tSize = size
            
            self.borreControl?.dataDFUCheck({[weak self] status, fileType, version, offset in
                guard let `self` = self else { return }
                
                let status = 1
                
                
                let XM_Versions = deviceVersion.components(separatedBy: ".")
                var XM_mcuVersion = ""
                var XM_bleVersion = ""
                var XM_resVersion = ""
                let XM_wifiVersion = ""
                if XM_Versions.count > 0 {
                    XM_mcuVersion = XM_Versions[0]
                }
                if XM_Versions.count > 1 {
                    XM_bleVersion = XM_Versions[1]
                }
                if XM_Versions.count > 2 {
                    XM_resVersion = XM_Versions[2]
                }
                
                
                self.borreControl?.dataDFUSend(package, maxPacketSize: tSize, transferContinueStatus: status, mcuVersion: XM_mcuVersion, bleVersion: XM_bleVersion, wifiVersion: XM_wifiVersion, resVersion: XM_resVersion, handler: {[weak self] (progress, isSuccess) in
                    
                    guard let `self` = self else { return }
                    
                    self.sendDfuResult(progress: Float(progress), isSuccess: isSuccess)
                    
                })
                
            })
        }
    }
    
    private func startDFUForre(package:PPTorreDFUPackageModel, deviceVersion:String, _ callBack: @escaping FlutterResult) {
        
        self.forreControl?.dataDFUStart { [weak self]  size in
            
            guard let `self` = self else {return}
            let tSize = size
            
            self.forreControl?.dataDFUCheck({[weak self] status, fileType, version, offset in
                guard let `self` = self else { return }
                
                let status = 1
                
                self.forreControl?.dataDFUSend(package, maxPacketSize: tSize, transferContinueStatus: status, deviceVersion: deviceVersion,handler: {[weak self] (progress, isSuccess) in
                    
                    guard let `self` = self else { return }
                    
                    self.sendDfuResult(progress: Float(progress), isSuccess: isSuccess)
                    
                })
                
            })
        }
    }
    
}
