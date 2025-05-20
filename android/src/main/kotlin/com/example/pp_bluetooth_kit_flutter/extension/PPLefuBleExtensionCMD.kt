package com.example.pp_bluetooth_kit_flutter.extension

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.example.pp_bluetooth_kit_flutter.PPLefuBleConnectManager
import com.example.pp_bluetooth_kit_flutter.model.PPDfuPackageModel
import com.lefu.ppbase.*
import com.lefu.ppbase.PPScaleDefine.*
import com.lefu.ppbase.vo.PPUserModel
import com.peng.ppscale.business.ble.configWifi.PPConfigStateMenu
import com.peng.ppscale.business.ble.configWifi.PPConfigWifiInfoInterface
import com.peng.ppscale.business.ble.listener.PPBleSendResultCallBack
import com.peng.ppscale.business.ble.listener.PPDeviceInfoInterface
import com.peng.ppscale.business.ble.listener.PPDeviceLogInterface
import com.peng.ppscale.business.ble.listener.PPDeviceSetInfoInterface
import com.peng.ppscale.business.ble.listener.PPTorreDeviceModeChangeInterface
import com.peng.ppscale.business.ble.listener.PPUserInfoInterface
import com.peng.ppscale.business.ota.OnOTAStateListener
import com.peng.ppscale.business.torre.listener.OnDFUStateListener
import com.peng.ppscale.business.torre.listener.PPClearDataInterface
import com.peng.ppscale.business.torre.listener.PPTorreConfigWifiInterface
import com.peng.ppscale.device.PeripheralApple.PPBlutoothPeripheralAppleController
import com.peng.ppscale.device.PeripheralCoconut.PPBlutoothPeripheralCoconutController
import com.peng.ppscale.util.UnitUtil
import com.peng.ppscale.vo.PPScaleSendState
import com.peng.ppscale.vo.PPWifiModel
import io.flutter.plugin.common.MethodChannel.Result

/**
 * PPLefuBleConnectManager的命令处理扩展
 * Created by lefu on 2023/4/16
 */
fun PPLefuBleConnectManager.syncUnit(unit: Int, model: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }
    val unit = UnitUtil.getUnitType(unit, currentDevice.deviceName);
    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.syncUnit(unit, model, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralCoconut -> {
            this.coconutControl?.sendSyncUserAndUnitData(unit, model, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }


        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.syncUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.syncUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralFish -> {
            this.fishControl?.changeKitchenScaleUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralEgg -> {
            this.eggControl?.changeKitchenScaleUnit(unit, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralDurian -> {
            this.durianControl?.syncUnit(unit, model, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.syncTime(is24Hour: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.syncTime({
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralCoconut -> {
            this.coconutControl?.sendSyncTime({
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncTime {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            val code = if (is24Hour) 0 else 1
            this.torreControl?.getTorreDeviceManager()?.syncTime24(code, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            val code = if (is24Hour) 0 else 1
            this.borreControl?.getTorreDeviceManager()?.syncTime24(code, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            val code = if (is24Hour) 0 else 1
            this.dorreControl?.getTorreDeviceManager()?.syncTime24(code, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            val code = if (is24Hour) 0 else 1
            this.forreControl?.getTorreDeviceManager()?.syncTime24(code, {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            })
        }

        PPDevicePeripheralType.PeripheralFish -> {
            this.fishControl?.sendSyncTime {
                val success = it == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            }
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.configWifi(domain: String, ssId: String, password: String, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf("success" to false, "errorCode" to -1))
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.sendModifyServerDomain(domain, object : PPConfigWifiInfoInterface {
                override fun monitorModifyServerDomainSuccess() {
                    appleControl?.configWifiData(ssId, password, this)
                }

                override fun monitorConfigSn(sn: String?, deviceModel: PPDeviceModel?) {
                    val success = sn.isNullOrEmpty().not()
                    if (!success) {
                        sendWIFIResult(success, sn, 0, callBack)
                    } else {
                        sendWIFIResult(success, sn, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.configWifi(domain, ssId, password, object : PPTorreConfigWifiInterface() {
                override fun configResult(stateMenu: PPConfigStateMenu?, errorCodeStr: String?) {
                    if (stateMenu == PPConfigStateMenu.CONFIG_STATE_SUCCESS) {
                        sendWIFIResult(true, "", 0, callBack)
                    } else if (stateMenu == PPConfigStateMenu.CONFIG_STATE_EXIT) {

                    } else {
                        sendWIFIResult(false, errorCodeStr, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.sendModifyServerDomain(domain, object : PPConfigWifiInfoInterface {
                override fun monitorModifyServerDomainSuccess() {
                    iceControl?.configWifiData(ssId, password, this)
                }

                override fun monitorConfigSn(sn: String?, deviceModel: PPDeviceModel?) {
                    val success = sn.isNullOrEmpty().not()
                    if (!success) {
                        sendWIFIResult(success, sn, 0, callBack)
                    } else {
                        sendWIFIResult(success, sn, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.configWifi(domain, ssId, password, object : PPTorreConfigWifiInterface() {
                override fun configResult(stateMenu: PPConfigStateMenu?, errorCodeStr: String?) {
                    if (stateMenu == PPConfigStateMenu.CONFIG_STATE_SUCCESS) {
                        sendWIFIResult(true, "", 0, callBack)
                    } else if (stateMenu == PPConfigStateMenu.CONFIG_STATE_EXIT) {

                    } else {
                        sendWIFIResult(false, errorCodeStr, -1, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.configWifi(domain, ssId, password, object : PPTorreConfigWifiInterface() {
                override fun configResult(stateMenu: PPConfigStateMenu?, errorCodeStr: String?) {
                    if (stateMenu == PPConfigStateMenu.CONFIG_STATE_SUCCESS) {
                        sendWIFIResult(true, "", 0, callBack)
                    } else if (stateMenu == PPConfigStateMenu.CONFIG_STATE_EXIT) {

                    } else {
                        sendWIFIResult(false, errorCodeStr, -1, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf("success" to false, "errorCode" to -1))
        }
    }
}

fun PPLefuBleConnectManager.syncLast7Data(lastBodyData: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserSevenWeighInfo(lastBodyData, object : PPUserInfoInterface {
                override fun syncUserSevenWeightInfoFail() {
                    sendCommonState(false, callBack)
                }

                override fun syncUserSevenWeightInfoSuccess() {
                    sendCommonState(true, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserSevenWeighInfo(lastBodyData, object : PPUserInfoInterface {
                override fun syncUserSevenWeightInfoFail() {
                    sendCommonState(false, callBack)
                }

                override fun syncUserSevenWeightInfoSuccess() {
                    sendCommonState(true, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.heartRateSwitchControl(open: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            //心率0打开 1关闭
            torreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            //心率0打开 1关闭
            iceControl?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            //心率0打开 1关闭
            borreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            //心率0打开 1关闭
            dorreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开 1关闭
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            //心率0打开 1关闭
            forreControl?.getTorreDeviceManager()?.controlHeartRate(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                /**
                 * 心率开关状态
                 *
                 * @param type  1设置开关 2获取开关
                 * @param state 0打开/成功 1关闭/失败
                 */
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchWifiInfo(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.getWiFiParmameters(object : PPConfigWifiInfoInterface {
                override fun monitorConfigSsid(ssid: String?, deviceModel: PPDeviceModel?) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            torreControl?.getTorreDeviceManager()?.getWifiSSID(object : PPTorreConfigWifiInterface() {
                /**
                 * 读取设备的SSID
                 *
                 * @param ssid
                 * @param state 0 成功 1失败
                 */
                override fun readDeviceSsidCallBack(ssid: String?, state: Int) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            borreControl?.getTorreDeviceManager()?.getWifiSSID(object : PPTorreConfigWifiInterface() {
                /**
                 * 读取设备的SSID
                 *
                 * @param ssid
                 * @param state 0 成功 1失败
                 */
                override fun readDeviceSsidCallBack(ssid: String?, state: Int) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            dorreControl?.getTorreDeviceManager()?.getWifiSSID(object : PPTorreConfigWifiInterface() {
                /**
                 * 读取设备的SSID
                 *
                 * @param ssid
                 * @param state 0 成功 1失败
                 */
                override fun readDeviceSsidCallBack(ssid: String?, state: Int) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getWifiInfo(object : PPConfigWifiInfoInterface {
                override fun monitorConfigSsid(ssid: String?, deviceModel: PPDeviceModel?) {
                    sendWIFISSID(ssid, ssid.isNullOrEmpty().not(), callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchDeviceInfo(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralApple -> {
            this.appleControl?.readDeviceInfo(object : PPDeviceInfoInterface() {
                override fun readDeviceInfoComplete(deviceModel: PPDeviceModel) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.readDeviceInfo(object : PPDeviceInfoInterface() {
                override fun readDeviceInfoComplete(deviceModel: PPDeviceModel) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.torreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.torreControl?.getTorreDeviceManager()?.readDeviceInfoFromCharacter(object : PPTorreDeviceModeChangeInterface {
                override fun onReadDeviceInfo(deviceModel: PPDeviceModel?) {
                    val deviceInfo = convert180A(deviceModel)
                    callBack.success(deviceInfo)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchWifiMac(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            torreControl?.getTorreDeviceManager()?.getWifiMac(object : PPTorreConfigWifiInterface() {
                override fun readDeviceWifiMacCallBack(wifiMac: String?) {
                    val dict = mapOf("wifiMac" to wifiMac)
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            torreControl?.getTorreDeviceManager()?.getWifiMac(object : PPTorreConfigWifiInterface() {
                override fun readDeviceWifiMacCallBack(wifiMac: String?) {
                    val dict = mapOf("wifiMac" to wifiMac)
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            dorreControl?.getTorreDeviceManager()?.getWifiMac(object : PPTorreConfigWifiInterface() {
                override fun readDeviceWifiMacCallBack(wifiMac: String?) {
                    val dict = mapOf("wifiMac" to wifiMac)
                    callBack.success(dict)
                }
            })
        }


        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.scanWifiNetworks(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getWifiList(object : PPTorreConfigWifiInterface() {
                override fun monitorWiFiListSuccess(wifoModels: List<PPWifiModel?>?) {
                    sendWifiList(wifoModels, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getWifiList(object : PPConfigWifiInfoInterface {

                override fun monitorWiFiListSuccess(wifiModels: MutableList<PPWifiModel>?) {
                    sendWifiList(wifiModels, callBack)
                }

                override fun monitorWiFiListFail(state: Int?) {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getWifiList(object : PPTorreConfigWifiInterface() {
                override fun monitorWiFiListSuccess(wifoModels: List<PPWifiModel?>?) {
                    sendWifiList(wifoModels, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getWifiList(object : PPTorreConfigWifiInterface() {
                override fun monitorWiFiListSuccess(wifoModels: List<PPWifiModel?>?) {
                    sendWifiList(wifoModels, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.wifiOTA(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.startUserOTA(object : OnOTAStateListener() {
                override fun onStartUpdate() {
                    sendWifiOTA(true, 0, callBack)
                }

                /**
                 * @param state 0普通的失败 1设备已在升级中不能再次启动升级 2设备低电量无法启动升级 3未配网 4 充电中
                 */
                override fun onUpdateFail(state: Int) {
                    if (state == 0) {
                        sendWifiOTA(true, -1, callBack)
                    } else {
                        sendWifiOTA(true, state, callBack)
                    }
                }

            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchHeartRateSwitch(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            //心率0打开 1关闭
            this.torreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getHeartRateState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.impedanceSwitchControl(open: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            //阻抗0打开可以测脂 1关闭不测脂
            torreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            iceControl?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            borreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            dorreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            forreControl?.getTorreDeviceManager()?.controlImpendance(if (open) 0 else 1, object : PPTorreDeviceModeChangeInterface {
                override fun controlImpendanceCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchImpedanceSwitch(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getImpendanceState(object : PPTorreDeviceModeChangeInterface {
                override fun readHeartRateStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("open" to (state == 0)))
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.setBindingState(binding: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    /**
     * 设备绑定状态
     *
     * @param type  1设置  2获取
     * @param state 0设备未绑定 1已绑定
     */
    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.deviceBindStatus(1, if (binding) 1 else 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 1) {
                        val success = state == 0
                        sendCommonState(success, callBack)
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.fetchBindingState(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 0)))
                    }
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.deviceBindStatus(2, 0, object : PPTorreDeviceModeChangeInterface {
                override fun bindStateCallBack(type: Int, state: Int) {
                    if (type == 2) {
                        callBack.success(mapOf("binding" to (state == 0)))
                    }
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.setScreenBrightness(brightness: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.setLight(brightness, object : PPDeviceSetInfoInterface {
                override fun monitorLightReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLightReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

// 辅助方法
private fun PPLefuBleConnectManager.sendWifiList(wifiList: List<PPWifiModel?>?, callBack: Result) {
    if (wifiList == null) {
        callBack.success(mapOf("wifiList" to emptyList<Map<String, Any>>()))
        return
    }
    val list = wifiList.map { wifi ->
        wifi?.ssid ?: ""
    }
    callBack.success(mapOf("wifiList" to list))
}

fun PPLefuBleConnectManager.fetchUserIDList(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getUserList(object : PPUserInfoInterface {
                override fun getUserListSuccess(memberIDs: List<String?>?) {
                    callBack.success(mapOf("userIDList" to memberIDs))
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getUserList(object : PPUserInfoInterface {
                override fun getUserListSuccess(memberIDs: List<String?>?) {
                    callBack.success(mapOf("userIDList" to memberIDs))
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getUserList(object : PPUserInfoInterface {
                override fun getUserListSuccess(memberIDs: List<String?>?) {
                    callBack.success(mapOf("userIDList" to memberIDs))
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.selectUser(user: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.confirmCurrentUser(user, object : PPUserInfoInterface {
                override fun confirmCurrentUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun confirmCurrentUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.torreControl?.getTorreDeviceManager()?.confirmCurrentUser(user, object : PPUserInfoInterface {
                override fun confirmCurrentUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun confirmCurrentUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.confirmCurrentUser(user, object : PPUserInfoInterface {
                override fun confirmCurrentUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun confirmCurrentUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.deleteUser(user: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.deleteUserInfo(user, object : PPUserInfoInterface {
                override fun deleteUserInfoSuccess(userModel: PPUserModel?) {
                    sendCommonState(true, callBack)
                }

                override fun deleteUserInfoFail(userModel: PPUserModel?) {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.deleteUserInfo(user, object : PPUserInfoInterface {
                override fun deleteUserInfoSuccess(userModel: PPUserModel?) {
                    sendCommonState(true, callBack)
                }

                override fun deleteUserInfoFail(userModel: PPUserModel?) {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.deleteUserInfo(user, object : PPUserInfoInterface {
                override fun deleteUserInfoSuccess(userModel: PPUserModel?) {
                    sendCommonState(true, callBack)
                }

                override fun deleteUserInfoFail(userModel: PPUserModel?) {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.startMeasure(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.startMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.torreControl?.getTorreDeviceManager()?.startMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.startMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.torreControl?.getTorreDeviceManager()?.startMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.stopMeasure(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.stopMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.stopMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.stopMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.stopMeasure {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.startBabyModel(step: Int, weight: Double, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            /**
             * 切换婴儿模式
             *
             * @param mode   00使能抱婴模式 01退出抱婴模式
             * @param step   0x00：第一步  0x01：第二步
             * @param weight 重量[单位10g]：当步骤为0x01[第一步]时重量发0 当步骤为0x02[第二步]时重量发第一步测得的重量
             */
            this.torreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.startBaby()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.switchBaby(0, step, weight) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.exitBabyModel(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.exitBaby()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.switchBaby(1, 0, 0.0) {
                this.sendCommonState(it == PPScaleSendState.PP_SEND_SUCCESS, callBack)
            }
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.startDFU(filePath: String, deviceFirmwareVersion: String, isForceCompleteUpdate: Boolean, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            if (isForceCompleteUpdate) {
                this.torreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
            } else {
                this.torreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            if (isForceCompleteUpdate) {
                this.borreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
            } else {
                this.borreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            if (isForceCompleteUpdate) {
                this.dorreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
            } else {
                this.dorreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        PPDevicePeripheralType.PeripheralForre -> {
            if (isForceCompleteUpdate) {
                this.forreControl?.getTorreDeviceManager()?.startDFU(filePath, onDFUStateListener)
            } else {
                this.forreControl?.getTorreDeviceManager()?.startSmartDFU(filePath, deviceFirmwareVersion, onDFUStateListener)
            }
        }

        else -> {
            this.loggerStreamHandler?.sendEvent("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.syncDeviceLog(logFolder: String, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.syncLog(logFolder, deviceLogInterface)
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.keepAlive() {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.startKeepAlive()
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
        }
    }
}

fun PPLefuBleConnectManager.clearDeviceData(type: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.clearSettingInfo(object : PPClearDataInterface {
                override fun onClearSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun onClearFail() {
                    sendCommonState(false, callBack)
                }

            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.setDeviceLanguage(type: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.setLanguage(type, object : PPDeviceSetInfoInterface {
                override fun monitorLanguageReviseSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun monitorLanguageReviseFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.fetchDeviceLanguage(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getLanguage(object : PPDeviceSetInfoInterface {
                override fun monitorLanguageValueChange(language: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "languageType" to language
                    )
                    callBack.success(dict)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.setDisplayBodyFat(bodyFat: Int, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.syncFat(bodyFat) { state ->
                val success = state == PPScaleSendState.PP_SEND_SUCCESS
                this.sendCommonState(success, callBack)
            }
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.exitScanWifiNetworks(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.exitWifiList()
            this.sendCommonState(true, callBack)
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.exitNetworkConfig(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        this.sendCommonState(false, callBack)
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralIce -> {
            this.iceControl?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.exitConfigWifi()
            this.sendCommonState(true, callBack)
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            this.sendCommonState(false, callBack)
        }
    }
}

fun PPLefuBleConnectManager.getScreenBrightness(callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.borreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        PPDevicePeripheralType.PeripheralForre -> {
            this.forreControl?.getTorreDeviceManager()?.getLight(object : PPDeviceSetInfoInterface {
                override fun monitorLightValueChange(light: Int) {
                    val dict = mapOf(
                        "success" to true,
                        "light" to light
                    )
                    callBack.success(dict)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.syncUserInfo(model: PPUserModel, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.torreControl?.getTorreDeviceManager()?.syncUserInfo(model, object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserInfo(model, object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUserInfo(model, object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }
}

fun PPLefuBleConnectManager.syncUserList(userList: List<PPUserModel>, callBack: Result) {
    val currentDevice = deviceControl?.deviceModel
    if (!(deviceControl?.connectState() ?: false) || currentDevice == null) {
        this.loggerStreamHandler?.eventSink?.success("当前无连接设备")
        callBack.success(mapOf<String, Any>())
        return
    }

    when (currentDevice.getDevicePeripheralType()) {
        PPDevicePeripheralType.PeripheralTorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUserInfo(userList[0], object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralBorre -> {
            this.borreControl?.getTorreDeviceManager()?.syncUserInfo(userList[0], object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        PPDevicePeripheralType.PeripheralDorre -> {
            this.dorreControl?.getTorreDeviceManager()?.syncUserInfo(userList[0], object : PPUserInfoInterface {
                override fun syncUserInfoSuccess() {
                    sendCommonState(true, callBack)
                }

                override fun syncUserInfoFail() {
                    sendCommonState(false, callBack)
                }
            })
        }

        else -> {
            this.loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice.getDevicePeripheralType()}")
            callBack.success(mapOf<String, Any>())
        }
    }


}

