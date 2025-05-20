// pp_ble_dfu_cmd.ets
import util from "@ohos.util";
import { PPBleFFF2ErrorCode } from "../../enums/PPBleFFF2ErrorCode";
import { PPLogger } from "../../log/PPLogger";
import { ByteUtil } from "../../utils/ByteUtil";

// 枚举定义（需根据实际协议调整）
enum PPBleDfuPlatform {
  IOS = 0x01,
  ANDROID = 0x00,
  HARMONY = 0x02
}

enum PPBleDfuFileType {
  BLE = 0x01,
  FIRMWARE = 0x02
}

interface PPSendPackageVo {
  fileType: PPBleDfuFileType;
  fileVersion: string;
  data: Uint8Array;
}

export class PPBleDfuCmd {
  private packageVos: PPSendPackageVo[];
  private platform: PPBleDfuPlatform;
  private mtu: number;
  // 静态成员变量
  private static chunkeSize: number = 0;
  private static protocolVersion: number = 0;
  private static transferContinueStatus: number = 0;
  private static lastBreakpointFileType: PPBleDfuFileType = PPBleDfuFileType.BLE;
  private static lastBreakpointFileVersion: string = "";
  private static lastBreakpointOffset: number = 0;

  constructor(packageVos: PPSendPackageVo[], platform: PPBleDfuPlatform, mtu: number) {
    this.packageVos = packageVos;
    this.platform = platform;
    this.mtu = mtu;
  }

  queryDfuProtocolVersion(): number[] {
    return [
      0x0b,
      0x02,
      0x01,
      this.platform === PPBleDfuPlatform.IOS ? 0x01 : 0x00
    ];
  }

  static queryDfuProtocolVersionBack(data: Uint8Array): PPBleFFF2ErrorCode {
    const errorType = PPBleFFF2ErrorCode.fromValue(data[3]);
    PPBleDfuCmd.protocolVersion = data[4];
    PPBleDfuCmd.chunkeSize = (data[8] << 24) | (data[7] << 16) | (data[6] << 8) | data[5];
    PPLogger.i("PPBleDfuCmd _chunkeSize:" + PPBleDfuCmd.chunkeSize);
    return errorType;
  }

  queryDFUState(): number[] {
    return [0x0b, 0x01, 0x02];
  }

  static queryDfuStateBack(data: Uint8Array): PPBleFFF2ErrorCode {
    const errorType = PPBleFFF2ErrorCode.fromValue(data[3]);
    PPBleDfuCmd.transferContinueStatus = data[4];
    PPBleDfuCmd.lastBreakpointFileType = data[5];

    const textDecoder = new util.TextDecoder('ascii');
    PPBleDfuCmd.lastBreakpointFileVersion = textDecoder.decode(new Uint8Array(data.slice(6, 9)));

    PPBleDfuCmd.lastBreakpointOffset = (data[12] << 24) | (data[11] << 16) | (data[10] << 8) | data[9];
    return errorType;
  }

  startDfuDataTransfer(vo: PPSendPackageVo): number[] {
    let cmd: number[] = [0x0b];
    let content: number[] = [0x03];

    // 最大传输块大小
    const mtuByte = ByteUtil.decimalToByteList(PPBleDfuCmd.chunkeSize, 3);
    content.push(...mtuByte);

    // 断点续传状态（暂固定为从头开始）
    content.push(0x01);

    // 文件类型
    content.push(vo.fileType);

    // 文件大小
    const currentFileLength = ByteUtil.decimalToByteList(vo.data.length, 4);
    content.push(...currentFileLength);

    // 文件版本号
    const textEncoder = new util.TextEncoder();
    const fileVersion = textEncoder.encode(vo.fileVersion);
    content.push(...fileVersion);

    // 计算总文件数和总大小
    let allFileLength = 0;
    this.packageVos.forEach(vo => {
      allFileLength += vo.data.length;
    });

    // 文件个数
    content.push(this.packageVos.length);

    // 总文件大小
    const allFileLengthByte = ByteUtil.decimalToByteList(allFileLength, 4);
    content.push(...allFileLengthByte);

    // 组装完整命令
    cmd.push(content.length);
    cmd.push(...content);

    return cmd;
  }

  static startDfuDataTransferBack(data: Uint8Array): PPBleFFF2ErrorCode {
    return PPBleFFF2ErrorCode.fromValue(data[3]);
  }

  dfuDataDeliver(vo: PPSendPackageVo, index: number): Map<String, Object> {

    const slicesPerBlock = Math.ceil(PPBleDfuCmd.chunkeSize / this.mtu);
    const chunkIndex = Math.floor(index / slicesPerBlock);
    const sliceIndexInBlock = index % slicesPerBlock;

    let start = chunkIndex * PPBleDfuCmd.chunkeSize + sliceIndexInBlock * this.mtu;
    let end = start + this.mtu;

    let chunkEnd = false;
    if (end > (chunkIndex * PPBleDfuCmd.chunkeSize + PPBleDfuCmd.chunkeSize)) {
      end = chunkIndex * PPBleDfuCmd.chunkeSize + PPBleDfuCmd.chunkeSize;
      chunkEnd = true;
    }

    let packageEnd = false;
    if (end > vo.data.length) {
      end = vo.data.length;
      packageEnd = true;
      chunkEnd = true;
    }

    const sliceData = vo.data.slice(start, end);
    const indexByte = ByteUtil.decimalToByteList(sliceIndexInBlock, 1);
    const cmd = [0x00, ...indexByte, ...sliceData];

    const progress = Math.ceil((end / vo.data.length) * 100);

    return new Map<String, Object>([
      ["cmd", cmd],
      ["chunkEnd", chunkEnd],
      ["packageEnd", packageEnd],
      ["progress", progress]
    ]);
  }

  static dfuDataSliceTransferBack(data: Uint8Array): PPBleFFF2ErrorCode {
    return PPBleFFF2ErrorCode.fromValue(data[3]);
  }

  currentFileDfuEnd(): number[] {
    return [0x0b, 0x01, 0x05];
  }

  static currentFileDfuEndBack(data: Uint8Array): PPBleFFF2ErrorCode {
    return PPBleFFF2ErrorCode.fromValue(data[3]);
  }

  dfuEnd(): number[] {
    return [0x0b, 0x01, 0x06];
  }

  static dfuEndBack(data: Uint8Array): PPBleFFF2ErrorCode {
    return PPBleFFF2ErrorCode.fromValue(data[3]);
  }
}

