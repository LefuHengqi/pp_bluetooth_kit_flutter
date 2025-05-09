
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_banana.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_borre.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_coconut.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_fish.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_hamburger.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_ice.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_jambul.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_torre.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_last_7_data_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';
import 'package:pp_bluetooth_kit_flutter/pp_bluetooth_kit_flutter.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_apple.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pp_bluetooth_kit_flutter/utils/pp_bluetooth_kit_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    final path = 'config/Device.json';
    String jsonStr = await rootBundle.loadString(path);
    PPBluetoothKitManager.setDeviceSetting(jsonStr);

    PPBluetoothKitManager.addBlePermissionListener(callBack: (state) {
      print('蓝牙权限变化-$state');
    });

  } catch(e) {
    print('初始化SDK异常:$e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await PPBluetoothKitFlutter.getPlatformVersion() ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DynamicTextPage(),
    );
  }
}


class DynamicTextPage extends StatefulWidget {
  const DynamicTextPage({super.key});

  @override
  State<DynamicTextPage> createState() => _DynamicTextPageState();
}

class _DynamicTextPageState extends State<DynamicTextPage> {

  final ScrollController _gridController = ScrollController();

  // 动态文本内容（可外部修改）
  String _dynamicText = '初始化SDK';
  PPUnitType _unit = PPUnitType.Unit_KG;
  bool _impedanceOpen = true;
  bool _heartRateOpen = true;

  final _userID = "12345678";
  final _memberID = "999999";

  final List<GridItem> _gridItems = [
    GridItem('扫描设备'),    // 0
    GridItem('停止扫描'),    // 1
    GridItem('连接指定设备'), // 2
    GridItem('获取历史数据'), // 3
    GridItem('同步时间'),    // 4
    GridItem('配网'),        // 5
    GridItem('获取配网信息'), // 6
    GridItem('获取设备信息'), // 7
    GridItem('获取电量'),    // 8
    GridItem('恢复出厂设置'), // 9
    GridItem('获取已连接的设备'), // 10
    GridItem('同步单位'),       // 11
    GridItem('同步设备日志'),    // 12
    GridItem('开始测量'),       // 13
    GridItem('停止测量'),       // 14
    GridItem('同步用户列表'),    // 15
    GridItem('删除用户'),    // 16
    GridItem('获取用户列表'),    // 17
    GridItem('抱婴模式-step1'),    // 18
    GridItem('抱婴模式-step2'),    // 19
    GridItem('退出抱婴模式'),    // 20
    GridItem('wifi-OTA'),    // 21
    GridItem('设置绑定状态'),    // 22
    GridItem('获取绑定状态'),    // 23
    GridItem('阻抗开关'),    // 24
    GridItem('获取阻抗开关状态'),    // 25
    GridItem('心率开关'),    // 26
    GridItem('获取心率开关状态'),    // 27
    GridItem('保活指令'),    // 28
    GridItem('退出Wi-Fi配网'),    // 29
    GridItem('蓝牙-DFU'),    // 30
    GridItem('接收广播设备数据'),    // 31
    GridItem('发送广播数据'),    // 32
    GridItem('获取屏幕亮度'),    // 33
    GridItem('获取周围Wi-Fi'),    // 34
    GridItem('退出配网'),    // 35
    GridItem('获取配网信息'),    // 36
    GridItem('同步最近7天/7次数据'),    // 37
    GridItem('厨房秤-去皮/清零'),    // 38
  ];

  void _updateText(String newText) {
    setState(() {
      final text = newText.isNotEmpty ? newText : "内容已清空";
      _dynamicText = '$text\n';

    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    PPBluetoothKitLogger.addListener(isDebug: false, callBack: (text) {
      print('SDK的日志:$text');
    });

    PPBluetoothKitManager.addScanStateListener(callBack: (isScanning) {
      print('扫描状态:$isScanning');
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo部分功能演示')),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: MediaQuery.of(context).size.width - 16,
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Text(
                    _dynamicText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),


          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(8),
              child: Scrollbar(
                controller: _gridController,
                child: GridView.builder(
                  controller: _gridController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _gridItems.length,
                  itemBuilder: (context, index) {
                    return GridActionItem(
                      item: _gridItems[index],
                      onTap: () async {
                        if (index == 0) {
                          PPBluetoothKitManager.startScan((device) {
                            print('业务扫描回调:${device.toString()}');
                            _updateText('扫到设备:${device.deviceName} ${device.deviceMac}');
                          });
                        } else if (index == 1) {
                          PPBluetoothKitManager.stopScan();
                        } else if (index == 2) {

                          final device = PPDeviceModel("CF577","CF:E7:05:0A:00:49");
                          // final device = PPDeviceModel("Health Scale c24","08:3A:8D:4E:3F:56");
                          // final device = PPDeviceModel("LFSmart Scale","CF:E6:10:17:00:6A");
                          // final device = PPDeviceModel("Health Scale c24","08:3A:8D:58:0D:32");
                          // final device  = PPDeviceModel("CF597_GNLine", "08:A6:F7:C1:A5:62");
                          // final device  = PPDeviceModel("CF568_BG", "CF:E7:55:27:B0:04"); //可用于DFU
                          // final device = PPDeviceModel("CF597_GNLine","08:A6:F7:C1:A5:62");
                          // final device = PPDeviceModel("CF632","CF:E9:02:11:C0:12");
                          // final device = PPDeviceModel("LEFU-CF621-X06","CF:E9:02:27:00:03");
                          // final device  = PPDeviceModel("LFSmart Scale", "CA:E6:08:24:04:A7");

                          // 人体秤
                          PPBluetoothKitManager.addMeasurementListener(callBack: (state, model, device){
                            print('测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                            _updateText('测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                          });

                          // 厨房秤
                          PPBluetoothKitManager.addKitchenMeasurementListener(callBack: (state, model, device){
                            print('厨房秤-测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                            _updateText('厨房秤-测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                          });

                          PPBluetoothKitManager.startScan((ppDevice){
                            print('业务层搜到设备:${ppDevice.deviceName} mac:${ppDevice.deviceMac}');
                            if (ppDevice.deviceMac == device.deviceMac) {
                              PPBluetoothKitManager.connectDevice(ppDevice, callBack: (state){
                                _updateText('连接状态:$state ${device.deviceMac}');
                              });
                            }
                          });


                        } else if (index == 3) {
                          PPPeripheralApple.fetchHistoryData(callBack: (dataList, bool isSuccess){
                            print('历史数据-数量:${dataList.length}');
                            _updateText('历史数据-数量:${dataList.length}');

                            //删除历史数据
                            PPPeripheralApple.deleteHistoryData();
                          });
                        } else if (index == 4) {
                          final result = await PPPeripheralApple.syncTime();
                          print("业务-同步时间结果-$result");
                          _updateText("业务-同步时间结果-$result");
                        } else if (index == 5) {
                          PPWifiResult ret = await PPPeripheralApple.configWifi(domain: "http://120.79.144.170:6032", ssId: "IT52", password: "12345678");
                          final str = "业务-配网-success:${ret.success} sn:${ret.sn}  errorCode:${ret.errorCode}";
                          print(str);
                          _updateText(str);
                        } else if (index == 6) {
                          final ssId = await PPPeripheralApple.fetchWifiInfo();
                          final str = "业务-获取配网信息-ssId:$ssId";
                          print(str);
                          _updateText(str);
                        } else if (index == 7) {
                          final model = await PPPeripheralApple.fetchDeviceInfo();
                          final str = "业务-获取设备信息-firmwareRevision:${model?.firmwareRevision} modelNumber:${model?.modelNumber} hardwareRevision:${model?.hardwareRevision}";
                          print(str);
                          _updateText(str);
                        } else if (index == 8) {
                          PPPeripheralApple.fetchBatteryInfo(continuity: true, callBack: (power){
                            final str = "业务-获取电量:$power 时间:${DateTime.now().millisecondsSinceEpoch}";
                            print(str);
                            _updateText(str);
                          });

                        } else if (index == 9) {

                          PPPeripheralApple.resetDevice();
                          final str = "业务-恢复出厂设置";
                          print(str);
                          _updateText(str);
                        } else if (index == 10) {

                          final device = await PPBluetoothKitManager.fetchConnectedDevice();
                          final str = "已连接设备-mac:${device?.deviceMac}";
                          print(str);
                          _updateText(str);
                        } else if (index == 11) {
                          _unit = _unit == PPUnitType.Unit_KG ? PPUnitType.UnitJin : PPUnitType.Unit_KG;
                          final deviceUser = PPDeviceUser(unitType: _unit,age: 20, userHeight: 170, sex: PPUserGender.female);
                          final ret = await PPPeripheralApple.syncUnit(deviceUser);
                          _updateText('同步单位-结果:$ret');

                        } else if (index == 12) {
                          String zrPath = '';
                          try {
                            final PathProviderPlatform provider = PathProviderPlatform.instance;
                            final documentPath = await provider.getApplicationDocumentsPath();
                            zrPath = '$documentPath/DeviceLog';

                            PPPeripheralTorre.syncDeviceLog(zrPath, callBack: (progress, isFailed, filePath) {
                              _updateText('进度:$progress 是否失败：$isFailed 日志路径:$filePath');
                              // print('进度:$progress 是否失败：$isFailed 日志路径:$filePath');
                            });
                          } catch (e) {
                            _updateText('获取路径失败:$e');
                          }

                        } else if (index == 13) {
                          PPPeripheralTorre.startMeasure();
                          final ret = PPPeripheralTorre.selectDeviceUser(_userID, _memberID);
                          print('选中用户:$ret');

                        } else if (index == 14) {
                          PPPeripheralTorre.stopMeasure();

                        } else if (index == 15) {

                          final user = PPTorreUserModel(
                              userName: 'sdk',
                              userHeight: 170,
                              age: 20,
                              sex: PPUserGender.female,
                              unitType: PPUnitType.Unit_KG,
                              userID: _userID,
                              memberID: _memberID,
                              pIndex: 2,
                              currentWeight: 45);

                          final ret = await PPPeripheralTorre.syncUserList([user]);
                          _updateText('同步用户列表结果-$ret');

                        } else if (index == 16) {

                          final ret = await PPPeripheralTorre.deleteDeviceUser(_userID,_memberID);
                          _updateText('删除用户结果-$ret');

                        } else if (index == 17) {
                          final array = await PPPeripheralTorre.fetchUserIDList();
                          var text = "";
                          for (var userID in array) {
                            text += '$userID\n';
                          }
                          _updateText('获取用户列表-$text');

                        } else if (index == 18) {
                          final ret = await PPPeripheralTorre.enterBabyModel(PPBabyModelStep.one, 0);
                          final ret1 = await PPPeripheralTorre.startMeasure();
                          _updateText('抱婴模式-1-结果$ret $ret1');

                        } else if (index == 19) {
                          final ret = await PPPeripheralTorre.enterBabyModel(PPBabyModelStep.two, 50);
                          _updateText('抱婴模式-2-结果$ret');

                        } else if (index == 20) {
                          final ret = await PPPeripheralTorre.stopMeasure();
                          final ret1 = await PPPeripheralTorre.exitBabyModel();
                          _updateText('退出抱婴模式-结果$ret $ret1');

                        } else if (index == 21) {
                          final ret = await PPPeripheralTorre.wifiOTA();
                          _updateText('wifi-OTA-结果$ret');

                        } else if (index == 22) {
                          final ret = await PPPeripheralTorre.setBindingState(true);
                          _updateText('设置绑定状态-结果$ret');

                        } else if (index == 23) {
                          final ret = await PPPeripheralTorre.fetchBindingState();
                          _updateText('获取绑定状态-结果$ret');

                        } else if (index == 24) {
                          _impedanceOpen = !_impedanceOpen;
                          final ret = await PPPeripheralTorre.impedanceSwitchControl(_impedanceOpen);
                          _updateText('阻抗开关设置-结果$ret');

                        } else if (index == 25) {
                          final ret = await PPPeripheralTorre.fetchImpedanceSwitch();
                          _updateText('获取阻抗开关-结果$ret');

                        } else if (index == 26) {
                          _heartRateOpen = !_heartRateOpen;

                          final ret = await PPPeripheralTorre.heartRateSwitchControl(_heartRateOpen);
                          _updateText('设置心率开关-结果$ret');

                        } else if (index == 27) {
                          final ret = await PPPeripheralTorre.fetchHeartRateSwitch();
                          _updateText('获取心率开关-结果$ret');

                        } else if (index == 28) {
                          PPPeripheralTorre.keepAlive();
                        } else if (index == 29) {
                          final ret = PPPeripheralTorre.exitNetworkConfig();

                          _updateText('退出Wi-Fi配网结果:$ret');
                        } else if (index == 30) {

                          try {

                            final PathProviderPlatform provider = PathProviderPlatform.instance;
                            final documentPath = await provider.getApplicationDocumentsPath();
                            if (documentPath == null) {
                              _updateText('获取沙盒路径为空');
                              return;
                            }

                            final targetPath = '$documentPath/CF568_BGeneric_ALL_OTA_V109.331.40_20230721.zip';
                            final targetFile = File(targetPath);
                            final byteData = await rootBundle.load('config/CF568_BGeneric_ALL_OTA_V109.331.40_20230721.zip');
                            await targetFile.writeAsBytes(byteData.buffer.asUint8List());

                            print('文件已成功拷贝到: $targetPath');

                            PPPeripheralTorre.startDFU(targetPath, '000.000.000', true, callBack: (progress, isSuccess) {

                              _updateText('DFU进度:$progress 是否成功:$isSuccess');
                            });

                          } catch (e) {
                            print('拷贝文件失败: $e');

                          }
                        } else if (index == 31) {

                          // final device  = PPDeviceModel("FDScale", "ED:68:00:31:48:F2");
                          // final device  = PPDeviceModel("OVRM", "CF:E7:12:02:00:02");
                          final device  = PPDeviceModel("LFSc", "ED:68:00:27:61:49");

                          // 人体秤
                          PPBluetoothKitManager.addMeasurementListener(callBack: (state, model, device){
                            print('测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                            _updateText('测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                          });

                          // 厨房秤
                          PPBluetoothKitManager.addKitchenMeasurementListener(callBack: (state, model, device){
                            print('厨房秤-测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                            _updateText('厨房秤-测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                          });

                          PPBluetoothKitManager.startScan((ppDevice) async {
                            if (ppDevice.deviceMac == device.deviceMac) {
                              PPBluetoothKitManager.stopScan();

                              // final ret = await PPPeripheralBanana.receiveDeviceData(ppDevice);
                              final ret = await PPPeripheralHamburger.receiveDeviceData(ppDevice);
                              _updateText('接收广播设备数据-结果:$ret');
                            }
                          });
                        } else if (index == 32) {
                          _unit = _unit == PPUnitType.Unit_KG ? PPUnitType.Unit_LB : PPUnitType.Unit_KG;
                          PPPeripheralJambul.sendBroadcastData(_unit, PPBroadcastCommand.exitSafeMode);
                        } else if (index == 33) {
                          final ret = await PPPeripheralTorre.fetchScreenBrightness();
                          _updateText('屏幕亮度-$ret');
                        } else if (index == 34) {
                          final ret = await PPPeripheralTorre.scanWifiNetworks();
                          _updateText('周边Wi-Fi-$ret');
                        } else if (index == 35) {
                          final ret = await PPPeripheralTorre.exitNetworkConfig();
                          _updateText('退出配网Wi-Fi-$ret');
                        } else if (index == 36) {
                          final ret = await PPPeripheralTorre.fetchWifiInfo();
                          _updateText('获取ssid-$ret');
                        } else if (index == 37) {
                          final model = PPLast7DataModel();
                          model.userID = _userID;
                          model.memberID = _memberID;
                          model.lastBMI = 2111;
                          model.lastBodyFat = 2500;
                          model.lastBone = 250;
                          model.lastBoneRate = 3810;
                          model.lastMuscle = 4220;
                          model.lastMuscleRate = 7080;
                          model.lastWaterRate = 5150;
                          model.lastHeartRate = 690;
                          model.targetWeight = 68.90;
                          model.idealWeight = 62.0;

                          final r1 = PPRecentData(timeStamp: 1746702227500, value: 5670);
                          final r2 = PPRecentData(timeStamp: 1746702227600, value: 6000);
                          final r3 = PPRecentData(timeStamp: 1746702228500, value: 7680);
                          final r4 = PPRecentData(timeStamp: 1746702229500, value: 6789);
                          final r5 = PPRecentData(timeStamp: 1746702237500, value: 3456);
                          final r6 = PPRecentData(timeStamp: 1746702247500, value: 3245);
                          final r7 = PPRecentData(timeStamp: 1746702257500, value: 1098);
                          final list = [r1,r2,r3,r4,r5,r6,r7];

                          model.weightList = list;

                          final ret = await PPPeripheralBorre.syncLast7Data(model);
                          _updateText('去皮/清零-$ret');
                        } else if (index == 38) {
                          final ret = await PPPeripheralFish.toZero();
                          _updateText('去皮/清零-$ret');
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridItem {
  final String title;

  GridItem(this.title);
}


class GridActionItem extends StatelessWidget {
  final GridItem item;
  final VoidCallback onTap;

  const GridActionItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
