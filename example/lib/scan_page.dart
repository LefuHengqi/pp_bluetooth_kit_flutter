import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:pp_bluetooth_kit_flutter/ble/pp_bluetooth_kit_manager.dart';
import 'package:pp_bluetooth_kit_flutter/enums/pp_scale_enums.dart';
import 'package:pp_bluetooth_kit_flutter/model/pp_device_model.dart';

import 'Device/device_apple.dart';
import 'Device/device_banana.dart';
import 'Device/device_borre.dart';
import 'Device/device_coconut.dart';
import 'Device/device_egg.dart';
import 'Device/device_fish.dart';
import 'Device/device_grapes.dart';
import 'Device/device_hamburger.dart';
import 'Device/device_ice.dart';
import 'Device/device_jambul.dart';
import 'Device/device_torre.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key, required this.title});

  final String title;

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = false;
  List<PPDeviceModel> _scanResults = [];

  @override
  void initState() {
    //Monitor Bluetooth permission changes
    PPBluetoothKitManager.addBlePermissionListener(callBack: (permission) {
      print('Bluetooth permission state changed:$permission');
    });

    // Monitor scan status
    PPBluetoothKitManager.addScanStateListener(callBack: (scanning) {
      _isScanning = scanning;
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  Future _onScanPressed() async {
    _scanResults = [];
    requestBluetoothPermissions();

    PPBluetoothKitManager.startScan((device) {
      print('Scan result:${device.toJson()}');

      _scanResults.add(device);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future _onStopPressed() async {
    PPBluetoothKitManager.stopScan();
  }

  Widget _buildScanButton(BuildContext context) {
    if (_isScanning) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: _onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(
          child: const Text("SCAN"), onPressed: _onScanPressed);
    }
  }

  String _wifiProtocolType(PPDeviceModel device) {
    switch (device.getDevicePeripheralType()) {
      case PPDevicePeripheralType.apple:
      case PPDevicePeripheralType.coconut:
        return 'V2.0/V3.0 Protocol';
      case PPDevicePeripheralType.ice:
      case PPDevicePeripheralType.torre:
      case PPDevicePeripheralType.borre:
      case PPDevicePeripheralType.dorre:
        return 'Torre/V4.0 Protocol';
      default:
        return 'Unknown';
    }
  }

  String _calculateApi(PPDeviceModel device) {
    switch (device.deviceCalculateType) {
      case PPDeviceCalculateType.direct:
        return 'DC Four-Electrode Algorithm v2.0';
      case PPDeviceCalculateType.alternate:
      case PPDeviceCalculateType.normal:
      case PPDeviceCalculateType.alternate4_0:
        return 'AC Four-Electrode Algorithm';
      case PPDeviceCalculateType.alternate4_1:
        return 'Dual-Frequency AC Four-Electrode Algorithm';
      case PPDeviceCalculateType.alternate8:
      case PPDeviceCalculateType.alternate8_0:
      case PPDeviceCalculateType.alternate8_1:
      case PPDeviceCalculateType.alternate8_2:
      case PPDeviceCalculateType.alternate8_3:
      case PPDeviceCalculateType.alternate8_4:
        return 'AC Eight-Electrode Algorithm';
      case PPDeviceCalculateType.alternate8_5:
        return 'AC Eight-Electrode Algorithm Smooth';
      default:
        return 'AC Four-Electrode Algorithm';
    }
  }

  int _product(PPDeviceModel device) {
    switch (device.deviceCalculateType) {
      case PPDeviceCalculateType.alternate8:
        return 1;
      case PPDeviceCalculateType.alternate8_0:
        return 4;
      case PPDeviceCalculateType.alternate8_1:
        return 3;
      case PPDeviceCalculateType.alternate8_2:
        return 7;
      case PPDeviceCalculateType.alternate8_3:
        return 5;
      case PPDeviceCalculateType.alternate8_4:
      case PPDeviceCalculateType.alternate8_5:
        return 6;
      default:
        return -1;
    }
  }

  bool _isWifi(PPDeviceModel device) {
    return ((device.deviceFuncType ?? 0) & PPDeviceFuncType.Wifi.getType()) != 0;
  }

  Widget _infoPanel(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF999999),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _infoText(String text, {bool right = false}) {
    return Expanded(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: right ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _leftRow(String text) => Row(children: [_infoText(text)]);

  Widget _buildDeviceCard(PPDeviceModel device) {
    final product = _product(device);
    return InkWell(
      onTap: () => _handleDeviceTap(device, _scanResults.indexOf(device)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Devices To The Platform', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _infoPanel([
              _leftRow('DeviceName: ${device.deviceName ?? '--'}'),
              const SizedBox(height: 4),
              Row(children: [
                _infoText('AdvLength: ${device.advLength ?? 0}'),
                _infoText('Sign: ${device.sign?.isNotEmpty == true ? device.sign : '--'}', right: true),
              ]),
            ]),
            const SizedBox(height: 4),
            const Text('Basic Attributes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _infoPanel([
              Row(children: [
                _infoText('MAC: ${device.deviceMac ?? '--'}'),
                _infoText('RSSI: ${device.rssi ?? 0}db', right: true),
              ]),
              const SizedBox(height: 4),
              _leftRow('PeripheralType: ${device.getDevicePeripheralType().name}'),
              const SizedBox(height: 4),
              _leftRow('NeedAuth: ${device.needAuth == true ? 'Need' : 'No Need'}'),
            ]),
            if (_isWifi(device)) ...[
              const SizedBox(height: 4),
              const Text('Distribution Networks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _infoPanel([
                _leftRow('WifiProtocolType: ${_wifiProtocolType(device)}'),
                const SizedBox(height: 4),
                _leftRow('HttpScheme: ${device.httpType == 1 ? 'https' : 'http'}'),
                const SizedBox(height: 4),
                _leftRow('SupportADN: ${device.isSupportADN == true ? 'Yes' : 'No'}'),
              ]),
            ],
            if (device.deviceCalculateType != PPDeviceCalculateType.needNot) ...[
              const SizedBox(height: 4),
              const Text('Computing Library', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              _infoPanel([
                _leftRow('CalculateType: ${device.deviceCalculateType?.name ?? 'Unknown'}'),
                const SizedBox(height: 4),
                _leftRow('CalculateAPI: ${_calculateApi(device)}'),
                if (product >= 0) ...[
                  const SizedBox(height: 4),
                  _leftRow('Product: $product'),
                ],
              ]),
            ],
          ],
        ),
      ),
    );
  }

  /// 统一请求蓝牙相关权限
  Future<bool> requestBluetoothPermissions() async {
    // 存储权限申请结果
    Map<Permission, PermissionStatus> statuses;

    // 区分平台申请对应权限
    if (Theme.of(context).platform == TargetPlatform.android) {
      // Android 12+ 需要同时申请 扫描、连接、位置
      statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    } else {
      // iOS 仅需蓝牙 + 位置
      statuses = await [
        Permission.bluetooth,
        Permission.locationWhenInUse,
      ].request();
    }

    // 判断所有权限是否全部通过
    bool allGranted = statuses.values.every((status) => status.isGranted);
    return allGranted;
  }

  void _handleDeviceTap(PPDeviceModel device, int index) {
    switch (device.getDevicePeripheralType()) {
      case PPDevicePeripheralType.apple:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceApple(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.coconut:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceCoconut(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.banana:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceBanana(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.ice:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceIce(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.jambul:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceJambul(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.torre:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceTorre(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.borre:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceBorre(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.fish:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceFish(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.hamburger:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceHamburger(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.egg:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceEgg(device: device),
          ),
        );
        break;
      case PPDevicePeripheralType.grapes:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceGrapes(device: device),
          ),
        );
        break;
      default:
        print('undefined-${device.getDevicePeripheralType()}');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: _scanResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildDeviceCard(_scanResults[index]);
        },
      ),
      floatingActionButton: _buildScanButton(
          context), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
