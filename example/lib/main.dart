
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_coconut.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_torre.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_user.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_torre_user_model.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_wifi_result.dart';
import 'package:pp_bluetooth_kit_flutter/pp_bluetooth_kit_flutter.dart';
import 'package:pp_bluetooth_kit_flutter/ble/pp_peripheral_apple.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {

    PPBluetoothKitManager.setLoggerEnable(true);

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
  // 动态文本内容（可外部修改）
  String _dynamicText = '初始化SDK';
  PPUnitType _unit = PPUnitType.Unit_KG;

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

    PPBluetoothKitManager.addLoggerListener(callBack: (content) {
      print('SDK的日志:$content');
    });

    PPBluetoothKitManager.addScanStateListener(callBack: (isScanning) {
      print('扫描状态:$isScanning');
    });
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
                child: GridView.builder(
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

                          PPBluetoothKitManager.addMeasurementListener(callBack: (state, model, device){
                            print('测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                            _updateText('测量-状态:$state data:${model.toJson()} device:${device.toJson()}');
                          });

                          PPBluetoothKitManager.startScan((ppDevice){
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

                            PPPeripheralTorre.syncDeviceLog(zrPath, callBack: (progress, isSuccess, filePath) {
                              _updateText('进度:$progress 是否成功：$isSuccess 日志路径:$filePath');
                              print('进度:$progress 是否成功：$isSuccess 日志路径:$filePath');
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
