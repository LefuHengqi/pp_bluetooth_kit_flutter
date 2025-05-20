package com.example.pp_bluetooth_kit_flutter

import android.content.Context
import com.example.pp_bluetooth_kit_flutter.extension.convertDeviceDict
import com.example.pp_bluetooth_kit_flutter.extension.convertMeasurementDict
import com.example.pp_bluetooth_kit_flutter.extension.sendBlePermissionState
import com.example.pp_bluetooth_kit_flutter.extension.sendCommonState
import com.example.pp_bluetooth_kit_flutter.extension.sendHistoryData
import com.example.pp_bluetooth_kit_flutter.extension.sendScanState
import com.example.pp_bluetooth_kit_flutter.model.PPDfuPackageModel
import com.example.pp_bluetooth_kit_flutter.util.PPBleHelper
import com.example.pp_bluetooth_kit_flutter.util.PPBluetoothState
import com.lefu.ppbase.*
import com.lefu.ppbase.PPScaleDefine.*
import com.lefu.ppbase.util.Logger
import com.lefu.ppbase.vo.PPUserModel
import com.peng.ppscale.*
import com.peng.ppscale.business.ble.PPScaleHelper
import com.peng.ppscale.business.ble.listener.PPBleSendResultCallBack
import com.peng.ppscale.business.ble.listener.PPBleStateInterface
import com.peng.ppscale.business.ble.listener.PPDeviceInfoInterface
import com.peng.ppscale.business.ble.listener.PPDeviceLogInterface
import com.peng.ppscale.business.ble.listener.PPDeviceSetInfoInterface
import com.peng.ppscale.business.ble.listener.PPHistoryDataInterface
import com.peng.ppscale.business.ble.listener.PPSearchDeviceInfoInterface
import com.peng.ppscale.business.ble.listener.PPTorreDeviceModeChangeInterface
import com.peng.ppscale.business.state.PPBleSwitchState
import com.peng.ppscale.business.state.PPBleWorkState
import com.peng.ppscale.business.torre.listener.OnDFUStateListener
import com.peng.ppscale.device.PPBlutoothPeripheralBaseController
import com.peng.ppscale.device.PeripheralApple.PPBlutoothPeripheralAppleController
import com.peng.ppscale.device.PeripheralBanana.PPBlutoothPeripheralBananaController
import com.peng.ppscale.device.PeripheralBorre.PPBlutoothPeripheralBorreController
import com.peng.ppscale.device.PeripheralCoconut.PPBlutoothPeripheralCoconutController
import com.peng.ppscale.device.PeripheralDorre.PPBlutoothPeripheralDorreController
import com.peng.ppscale.device.PeripheralDurian.PPBlutoothPeripheralDurianController
import com.peng.ppscale.device.PeripheralEgg.PPBlutoothPeripheralEggController
import com.peng.ppscale.device.PeripheralFish.PPBlutoothPeripheralFishController
import com.peng.ppscale.device.PeripheralForre.PPBlutoothPeripheralForreController
import com.peng.ppscale.device.PeripheralGrapes.PPBlutoothPeripheralGrapesController
import com.peng.ppscale.device.PeripheralHamburger.PPBlutoothPeripheralHamburgerController
import com.peng.ppscale.device.PeripheralIce.PPBlutoothPeripheralIceController
import com.peng.ppscale.device.PeripheralJambul.PPBlutoothPeripheralJambulController
import com.peng.ppscale.device.PeripheralTorre.PPBlutoothPeripheralTorreController
import com.peng.ppscale.search.PPSearchManager
import com.peng.ppscale.util.UnitUtil
import com.peng.ppscale.vo.PPScaleSendState
import io.flutter.plugin.common.MethodChannel.Result

/**
 * 蓝牙扫描类型枚举
 */
enum class PPLefuScanType(val value: Int) {
    SCAN(0)
}

/**
 * 蓝牙连接管理器
 * 负责处理蓝牙设备的扫描、连接和数据交互
 */
class PPLefuBleConnectManager private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var instance: PPLefuBleConnectManager? = null

        fun getInstance(context: Context): PPLefuBleConnectManager {
            return instance ?: synchronized(this) {
                instance ?: PPLefuBleConnectManager(context).also { instance = it }
            }
        }
    }

    // Stream handlers for Flutter event channels
    var scanResultStreamHandler: PPLefuStreamHandler? = null
    var loggerStreamHandler: PPLefuStreamHandler? = null
    var connectStateStreamHandler: PPLefuStreamHandler? = null
    var measureStreamHandler: PPLefuStreamHandler? = null
    var historyStreamHandler: PPLefuStreamHandler? = null
    var batteryStreamHandler: PPLefuStreamHandler? = null
    var blePermissionStreamHandler: PPLefuStreamHandler? = null
    var dfuStreamHandler: PPLefuStreamHandler? = null
    var deviceLogStreamHandler: PPLefuStreamHandler? = null
    var scanStateStreamHandler: PPLefuStreamHandler? = null
    var kitchenStreamHandler: PPLefuStreamHandler? = null

    var ppScale: PPSearchManager? = PPSearchManager.getInstance()


    // 蓝牙状态相关
    private var needScan = false
    private var scanType: PPLefuScanType = PPLefuScanType.SCAN
    private var isScaning: Boolean = false

    // 连接状态和历史数据
    private var connectState: Int = 0
    private var tempScaleHistoryList: MutableList<PPBodyBaseModel>? = null

    // 设备控制器
    var currentDevice: PPDeviceModel? = null

    //当前的Controller
    var deviceControl: PPBlutoothPeripheralBaseController? = null

    var appleControl: PPBlutoothPeripheralAppleController? = null
    var coconutControl: PPBlutoothPeripheralCoconutController? = null
    var torreControl: PPBlutoothPeripheralTorreController? = null
    var iceControl: PPBlutoothPeripheralIceController? = null
    var bananaControl: PPBlutoothPeripheralBananaController? = null
    var jambulControl: PPBlutoothPeripheralJambulController? = null
    var borreControl: PPBlutoothPeripheralBorreController? = null
    var dorreControl: PPBlutoothPeripheralDorreController? = null
    var forreControl: PPBlutoothPeripheralForreController? = null
    var fishControl: PPBlutoothPeripheralFishController? = null
    var eggControl: PPBlutoothPeripheralEggController? = null
    var hamburgerControl: PPBlutoothPeripheralHamburgerController? = null
    var grapesControl: PPBlutoothPeripheralGrapesController? = null
    var durianControl: PPBlutoothPeripheralDurianController? = null

    // DFU相关
    var unzipFilePath: String? = null
    var dfuConfig: PPDfuPackageModel? = null

    // 临时设备字典
    private val tempDeviceDict = mutableMapOf<String, PPDeviceModel>()




    /**
     * 开始扫描设备
     */
    fun startScan(callBack: Result) {
//        stopScan()
//        disconnect()

        tempDeviceDict.clear()

        scanDevice(PPLefuScanType.SCAN, callBack)
    }

    /**
     * 扫描设备
     */
    fun scanDevice(type: PPLefuScanType, callBack: Result) {
        scanType = type
        needScan = true

        sendCommonState(true, callBack)
        tempDeviceDict.clear()

        ppScale?.registerBluetoothStateListener(bleStateInterface)

        ppScale?.startSearchDeviceList(300000, searchDeviceInfoInterface, bleStateInterface)

    }

    /**
     * 连接设备
     */
    fun connectDevice(deviceMac: String, deviceName: String) {

        if (deviceControl?.connectState() ?: false && deviceControl?.deviceModel?.deviceMac == deviceMac) {
            loggerStreamHandler?.eventSink?.success("$deviceMac-该设备已连接，继续使用")
            sendConnectState(1)
            return
        }

        stopScan()
        disconnect()

        if (tempDeviceDict.containsKey(deviceMac)) {
            val device = tempDeviceDict[deviceMac]

            if (device != null) {
                currentDevice = device

                loggerStreamHandler?.eventSink?.success("开始连接设备:${device.deviceName} mac:${device.deviceMac} ${device.getDevicePeripheralType()}")

                when (device.getDevicePeripheralType()) {
                    PPDevicePeripheralType.PeripheralApple -> {
                        appleControl = PPBlutoothPeripheralAppleController()
                        deviceControl = appleControl
                    }

                    PPDevicePeripheralType.PeripheralCoconut -> {

                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralBorre -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralIce -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralBorre -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralForre -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralFish -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralEgg -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    PPDevicePeripheralType.PeripheralDurian -> {
                        coconutControl = PPBlutoothPeripheralCoconutController()
                        deviceControl = coconutControl
                    }

                    else -> {
                        loggerStreamHandler?.eventSink?.success("不支持的设备类型-peripheralType:${device.getDevicePeripheralType()}-$deviceMac")
                        sendConnectState(2)
                    }
                }
                if (deviceControl != null && deviceControl?.deviceModel?.deviceConnectType == PPDeviceConnectType.PPDeviceConnectTypeDirect) {

                }
                deviceControl?.startConnect(device, bleStateInterface)

            }
        } else {
            loggerStreamHandler?.eventSink?.success("找不到设备-$deviceMac")
            sendConnectState(2)
        }
    }

    /**
     * 停止扫描
     */
    fun stopScan() {
        needScan = false
        ppScale?.stopSearch()

        if (isScaning) {
            isScaning = false
            sendScanState(false)
        }
    }

    /**
     * 断开连接
     */
    fun disconnect() {
        if (deviceControl?.connectState() == true) {
            deviceControl?.disConnect()
        }
        clearData()
    }

    /**
     * 清除数据
     */
    fun clearData() {
        deviceControl = null
        coconutControl = null
        torreControl = null
        iceControl = null
        borreControl = null
        forreControl = null
        fishControl = null
        eggControl = null
        durianControl = null
        needScan = false
        currentDevice = null
    }

    /**
     * 发送连接状态
     * 连接状态 0:断开连接 1:连接成功 2:连接错误
     */
    fun sendConnectState(state: Int) {
        loggerStreamHandler?.eventSink?.success("连接状态:$state")

        connectState = state

        val mac = deviceControl?.deviceModel?.deviceMac ?: ""
        val params = mapOf(
            "deviceMac" to mac,
            "state" to state
        )

        connectStateStreamHandler?.eventSink?.success(params)
    }

    /**
     * 获取历史数据
     */
    fun fetchHistory(model: PPUserModel, callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.eventSink?.success("当前无连接设备")
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (deviceControl?.deviceModel?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                tempScaleHistoryList = mutableListOf()
                appleControl?.getHistoryData(historyDataInterface)
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
                tempScaleHistoryList = mutableListOf()
                coconutControl?.getHistoryData(historyDataInterface)
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                tempScaleHistoryList = mutableListOf()
                if (model.userID.equals("30")) {
                    torreControl?.getTorreDeviceManager()?.syncTouristHistory(historyDataInterface)
                } else {
                    torreControl?.getTorreDeviceManager()?.syncUserHistory(model, historyDataInterface)
                }
            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.getHistory(historyDataInterface)
            }

            PPDevicePeripheralType.PeripheralBorre -> {
                if (model.userID.equals("30")) {
                    borreControl?.getTorreDeviceManager()?.syncTouristHistory(historyDataInterface)
                } else {
                    borreControl?.getTorreDeviceManager()?.syncUserHistory(model, historyDataInterface)
                }
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                if (model.userID.equals("30")) {
                    dorreControl?.getTorreDeviceManager()?.syncTouristHistory(historyDataInterface)
                } else {
                    dorreControl?.getTorreDeviceManager()?.syncUserHistory(model, historyDataInterface)
                }
            }

            else -> {
                loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 删除历史数据
     */
    fun deleteHistory(callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.eventSink?.success("当前无连接设备")
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                appleControl?.deleteHistoryData {
                    if (it == PPScaleSendState.PP_SEND_SUCCESS) {
                        sendCommonState(true, callBack)
                    } else {
                        sendCommonState(false, callBack)
                    }
                }
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
                coconutControl?.deleteHistoryData {
                    if (it == PPScaleSendState.PP_SEND_SUCCESS) {
                        sendCommonState(true, callBack)
                    } else {
                        sendCommonState(false, callBack)
                    }
                }
            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.deleteHistoryData {
                    if (it == PPScaleSendState.PP_SEND_SUCCESS) {
                        sendCommonState(true, callBack)
                    } else {
                        sendCommonState(false, callBack)
                    }
                }
            }

            else -> {
                loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 获取电池信息
     */
    fun fetchBatteryInfo(callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.eventSink?.success("当前无连接设备")
            batteryStreamHandler?.eventSink?.success(mapOf("power" to 0, "type" to -1))
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                appleControl?.readDeviceBattery(deviceInfoInterface)
                callBack?.let { sendCommonState(true, it) }
            }

            PPDevicePeripheralType.PeripheralCoconut -> {
//                coconutControl?.readDeviceBattery()
//                callBack?.let { sendCommonState(true, it) }
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                torreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.readDeviceBattery(deviceInfoInterface)
            }

            PPDevicePeripheralType.PeripheralBorre -> {
                borreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                dorreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            PPDevicePeripheralType.PeripheralForre -> {
                forreControl?.getTorreDeviceManager()?.readDeviceBattery(torreDeviceModeChangeInterface)
            }

            else -> {
                loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                batteryStreamHandler?.eventSink?.success(mapOf("power" to 0, "type" to -1))
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 重置设备
     */
    fun resetDevice(callBack: Result? = null) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.eventSink?.success("当前无连接设备")
            callBack?.let { sendCommonState(false, it) }
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralApple -> {
                appleControl?.sendResetDevice(deviceSetInfoInterface, {
                    if (it == PPScaleSendState.PP_SEND_SUCCESS) {
                        sendCommonState(true, callBack)
                    } else {
                        sendCommonState(false, callBack)
                    }
                })

            }

            PPDevicePeripheralType.PeripheralIce -> {
                iceControl?.sendResetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralTorre -> {
                torreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralBorre -> {
                borreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralDorre -> {
                dorreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            PPDevicePeripheralType.PeripheralForre -> {
                forreControl?.getTorreDeviceManager()?.resetDevice(deviceSetInfoInterface)
                sendCommonState(true, callBack)
            }

            else -> {
                loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                callBack?.let { sendCommonState(false, it) }
            }
        }
    }

    /**
     * 接收广播数据
     */
    fun receiveBroadcastData(deviceMac: String, callBack: Result) {
        val device = tempDeviceDict[deviceMac]

        if (device == null) {
            loggerStreamHandler?.eventSink?.success("找不到当前设备")
            sendCommonState(false, callBack)
            return
        }


        if (device.deviceConnectType != PPDeviceConnectType.PPDeviceConnectTypeBroadcast) {
            loggerStreamHandler?.eventSink?.success("${device.deviceName}-${device.deviceMac}不是广播秤")
            sendCommonState(false, callBack)
            return
        }

        if (PPBleHelper.isOpenBluetooth()) {
            loggerStreamHandler?.eventSink?.success("接收广播失败-蓝牙开关未打开")
            sendCommonState(false, callBack)
            return
        }

        disconnect()

        currentDevice = device

        when (device.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralBanana -> {
                bananaControl = PPBlutoothPeripheralBananaController()
                deviceControl = bananaControl
            }

            PPDevicePeripheralType.PeripheralJambul -> {
                jambulControl = PPBlutoothPeripheralJambulController()
                deviceControl = bananaControl
            }

            PPDevicePeripheralType.PeripheralHamburger -> {
                hamburgerControl = PPBlutoothPeripheralHamburgerController()
                deviceControl = hamburgerControl
            }

            PPDevicePeripheralType.PeripheralGrapes -> {
                grapesControl = PPBlutoothPeripheralGrapesController()
                deviceControl = grapesControl
            }

            else -> {
                currentDevice = null
            }
        }

        sendCommonState(true, callBack)
    }

    /**
     * 发送广播数据
     */
    fun sendBroadcastData(cmd: String, unitType: Int, callBack: Result) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.eventSink?.success("当前设备为空")
            sendCommonState(false, callBack)
            return
        }

        if (currentDevice?.getDevicePeripheralType() == PPDevicePeripheralType.PeripheralJambul && jambulControl != null
            && PPScaleHelper.isFuncTypeTwoBrocast(jambulControl?.deviceModel?.deviceFuncType)
        ) {
            val mode = if (cmd.equals("38")) 1 else 0
            jambulControl?.startBroadCast(UnitUtil.getUnitType(unitType), mode, jambulControl?.deviceModel?.deviceMac ?: "")
            sendCommonState(true, callBack)
        } else {
            loggerStreamHandler?.eventSink?.success("不支持的功能-jambul:${jambulControl}-peripheralType:${currentDevice?.getDevicePeripheralType()}")
            sendCommonState(false, callBack)
        }
    }

    /**
     * 获取已连接设备
     */
    fun fetchConnectedDevice(callBack: Result) {
        if (currentDevice != null) {
            val dict = convertDeviceDict(currentDevice!!)
            callBack.success(dict)
        } else {
            callBack.success(emptyMap<String, Any>())
        }
    }

    /**
     * 添加蓝牙权限监听
     */
    fun addBlePermissionListener() {
        try {
            if (PPBleHelper.isOpenBluetooth()) {
                sendBlePermissionState(PPBluetoothState.POWERED_ON)
            } else {
                sendBlePermissionState(PPBluetoothState.POWERED_OFF)
            }
        } catch (e: Exception) {
            sendBlePermissionState(PPBluetoothState.UNAUTHORIZED)
        }
    }

    /**
     * 归零操作
     */
    fun toZero(callBack: Result) {
        if (!(deviceControl?.connectState() ?: false)) {
            loggerStreamHandler?.eventSink?.success("当前无连接设备")
            sendCommonState(false, callBack)
            return
        }

        when (currentDevice?.getDevicePeripheralType()) {
            PPDevicePeripheralType.PeripheralFish -> {
                fishControl?.toZeroKitchenScale({
                    if (it == PPScaleSendState.PP_SEND_SUCCESS) {
                        sendCommonState(true, callBack)
                    } else {
                        sendCommonState(false, callBack)
                    }
                })
            }

            PPDevicePeripheralType.PeripheralEgg -> {
                eggControl?.toZeroKitchenScale({
                    if (it == PPScaleSendState.PP_SEND_SUCCESS) {
                        sendCommonState(true, callBack)
                    } else {
                        sendCommonState(false, callBack)
                    }
                })
            }

            else -> {
                loggerStreamHandler?.eventSink?.success("不支持的设备类型-${currentDevice?.getDevicePeripheralType()}")
                sendCommonState(false, callBack)
            }
        }
    }


    val bleStateInterface = object : PPBleStateInterface() {
        override fun monitorBluetoothWorkState(ppBleWorkState: PPBleWorkState?, deviceModel: PPDeviceModel?) {
            if (ppBleWorkState == PPBleWorkState.PPBleWorkStateConnected) {

            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateConnecting) {

            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateDisconnected) {
                val map = mutableMapOf<String, Any?>()
                map.put("deviceMac", deviceModel?.deviceMac)
                map.put("state", 0)
                connectStateStreamHandler?.sendEvent(map)
            } else if (ppBleWorkState == PPBleWorkState.PPBleStateSearchCanceled) {
                scanStateStreamHandler?.sendState(0)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkSearchTimeOut) {
                scanStateStreamHandler?.sendState(0)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateSearching) {
                scanStateStreamHandler?.sendState(1)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateWritable) {
                val map = mutableMapOf<String, Any?>()
                map.put("deviceMac", deviceModel?.deviceMac)
                map.put("state", 1)
                connectStateStreamHandler?.sendEvent(map)
            } else if (ppBleWorkState == PPBleWorkState.PPBleWorkStateConnectFailed) {
                val map = mutableMapOf<String, Any?>()
                map.put("deviceMac", deviceModel?.deviceMac)
                map.put("state", 2)
                connectStateStreamHandler?.sendEvent(map)
            }
        }

        override fun monitorBluetoothSwitchState(ppBleSwitchState: PPBleSwitchState?) {
            if (ppBleSwitchState == PPBleSwitchState.PPBleSwitchStateOff) {

            } else if (ppBleSwitchState == PPBleSwitchState.PPBleSwitchStateOn) {

            }
        }

        override fun monitorMtuChange(deviceModel: PPDeviceModel?) {
            val map = mutableMapOf<String, Any?>()
            map.put("deviceMac", deviceModel?.deviceMac)
            map.put("state", 0)
            connectStateStreamHandler?.sendEvent(map)
        }

    }

    fun addPrint(msg: String) {
        if (msg.isNotEmpty()) {
            Logger.d(msg)
        }
    }


    var searchDeviceInfoInterface = PPSearchDeviceInfoInterface { ppDeviceModel, data ->
        {
            tempDeviceDict.put(ppDeviceModel.deviceMac, ppDeviceModel)
            val deviceDict = convertDeviceDict(ppDeviceModel)
            scanResultStreamHandler?.sendEvent(deviceDict)
        }
    }


    var historyDataInterface = object : PPHistoryDataInterface() {
        override fun monitorHistoryData(bodyBaseModel: PPBodyBaseModel?, dateTime: String?) {
            addPrint("monitorHistoryData weight: ${bodyBaseModel?.weight}" + " dateTime:$dateTime")
        }

        override fun monitorHistoryEnd(deviceModel: PPDeviceModel?) {
            addPrint("monitorHistoryEnd")

        }

        override fun monitorHistoryFail() {
            addPrint("monitorHistoryFail")
        }
    }

    var deviceInfoInterface = object : PPDeviceInfoInterface() {

        override fun readDevicePower(power: Int, state: Int) {
            batteryStreamHandler?.sendEvent(mapOf("power" to power, "type" to state))
        }

    }

    var torreDeviceModeChangeInterface = object : PPTorreDeviceModeChangeInterface {


        override fun readDevicePower(power: Int) {
            batteryStreamHandler?.sendEvent(mapOf("power" to power, "type" to 0))
        }

    }

    var deviceSetInfoInterface = object : PPDeviceSetInfoInterface {

        override fun monitorResetStateFail() {

        }

        override fun monitorResetStateSuccess() {

        }

    }


    var onDFUStateListener: OnDFUStateListener = object : OnDFUStateListener {
            override fun onDfuProgress(progress: Int) {
                dfuStreamHandler?.sendEvent(mapOf("progress" to progress, "isSuccess" to false, "code" to 0))
            }

            override fun onDfuFail(errorType: String?) {
                dfuStreamHandler?.sendEvent(mapOf("progress" to -1, "isSuccess" to false, "code" to 2))
            }

            override fun onDfuStart() {
                dfuStreamHandler?.sendEvent(mapOf("progress" to 0, "isSuccess" to false, "code" to 0))
            }

            override fun onDfuSucess() {
                dfuStreamHandler?.sendEvent(mapOf("progress" to 100, "isSuccess" to true, "code" to 1))
            }

            override fun onStartSendDfuData() {

            }

        }


    var deviceLogInterface = object : PPDeviceLogInterface {

        override fun syncLogStart() {
            deviceLogStreamHandler?.sendEvent(mapOf("progress" to 0, "isFailed" to false))
        }

        override fun syncLoging(progress: Int) {
            deviceLogStreamHandler?.sendEvent(mapOf("progress" to progress, "isFailed" to false))
        }

        override fun syncLogEnd(filePath: String?) {
            deviceLogStreamHandler?.sendEvent(mapOf("progress" to 1, "filePath" to filePath, "isFailed" to false))
        }

    }


}