// FirmwareConfigParser.ets
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import util from '@ohos.util';
import { PPBleDfuFileType } from './PPBleOtaTool';

export { FirmwareConfig, PackageInfo, FirmwareConfigParser };

// 类型定义（全部字段可选）
interface PackageInfo {
  filename?: string;
  version?: string;
}

export interface PPDfuPackagesVo {
  mcu?: PackageInfo;
  ble?: PackageInfo;
  res?: PackageInfo;
  wifi?: PackageInfo;
}

interface FirmwareConfig {
  buildTime?: string;
  deviceSource?: string;
  packageVersion?: string;
  packages?: PPDfuPackagesVo;
}


interface GeneratedTypeLiteralInterface_1 {
  fileVersion?: string;
  fileType?: PPBleDfuFileType;
  filePath?: string;
  data?: Uint8Array;
}

export class PPSendPackageVo {
  // 成员变量（ArkTS要求必须在类顶层声明）
  readonly fileType?: PPBleDfuFileType;
  readonly fileVersion?: string;
  readonly filePath?: string; // OpenHarmony使用文件路径替代File对象
  readonly data?: Uint8Array;

  // 构造函数
  constructor(params: GeneratedTypeLiteralInterface_1) {
    this.fileVersion = params.fileVersion;
    this.fileType = params.fileType;
    this.filePath = params.filePath;
    this.data = params.data;
  }
}

class FirmwareConfigParser {
  // 静态方法读取文件内容
  private static async readFileContent(filePath: string): Promise<string> {
    let file: fs.File | null = null;
    try {
      // 1. 打开文件（返回File对象）
      file = await fs.open(filePath, fs.OpenMode.READ_ONLY);

      // 2. 获取文件信息
      const stat: fs.Stat = await fs.stat(filePath);

      // 3. 读取内容
      const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
      const readLen: number = await fs.read(file.fd, buffer);

      // 4. 转换为字符串
      return util.TextDecoder.create('utf-8').decodeWithStream(
        new Uint8Array(buffer, 0, readLen)
      );
    } catch (error) {
      throw new Error(`File read error: ${(error as BusinessError).message}`);
    } finally {
      // 5. 确保关闭文件
      if (file !== null) {
        await fs.close(file.fd);
      }
    }
  }

  // 静态解析方法
  static async parseConfig(filePath: string): Promise<FirmwareConfig | null> {
    try {
      const jsonStr: string = await FirmwareConfigParser.readFileContent(filePath);
      return JSON.parse(jsonStr) as FirmwareConfig;
    } catch (error) {
      console.error(`Config parse failed: ${(error as BusinessError).message}`);
      return null;
    }
  }
}



