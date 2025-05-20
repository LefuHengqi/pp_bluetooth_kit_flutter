import { PPLogger } from "../../log/PPLogger";

import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import { FirmwareConfig, FirmwareConfigParser, PackageInfo, PPDfuPackagesVo, PPSendPackageVo } from "./PPBleOtaVo";
import { FileFinder } from "./FileFinder";

export enum PPBleDfuFileType {
  ble = 0x01,
  mcu = 0x02,
  wifi = 0x03,
  res = 0x04
}

// 保持原始VO类结构
export class PPFirmwareVersionVo {
  ble: string;
  mcu: string;
  wifi: string;
  res: string;

  constructor(
    ble: string,
    mcu: string,
    wifi: string,
    res: string
  ) {
    this.ble = ble;
    this.mcu = mcu;
    this.wifi = wifi;
    this.res = res;
  }
}

export class PPBleOtaTool {
  private otaFilePath: string;
  private currentVersion: PPFirmwareVersionVo;

  constructor(otaFilePath: string, currentVersion: PPFirmwareVersionVo) {
    this.otaFilePath = otaFilePath;
    this.currentVersion = currentVersion;
  }

  async parsePackageJson(): Promise<FirmwareConfig | null> {
    try {
      PPLogger.d("-----------从路径中寻找package.json----------");
      // 1. 查找 package.json 文件
      const packageJsonPath = await this.findPackageJson();
      if (!packageJsonPath) {
        PPLogger.w('package.json not found in ' + this.otaFilePath);
        return null;
      }

      // 2. 读取文件内容
      PPLogger.d(`-----------读取文件内容----------packageJsonPath:${packageJsonPath}`)
      const config = await FirmwareConfigParser.parseConfig(packageJsonPath);
      // 3. 解析JSON

      return config;
    } catch (error) {
      PPLogger.e('parsePackageJson error: ' + JSON.stringify(error));
      return null;
    }
  }

  private async findPackageJson(): Promise<string | null> {
    try {
      // 使用 fs.access 检查目录是否存在
      await fs.access(this.otaFilePath);

      // 列出目录文件
      const files = await fs.listFile(this.otaFilePath);

      // 查找 package.json
      if (files.includes('package.json')) {
        return `${this.otaFilePath}/package.json`;
      }

      // 可选：递归查找子目录
      for (const file of files) {
        const fullPath = `${this.otaFilePath}/${file}`;
        const stat = await fs.stat(fullPath);
        if (stat.isDirectory()) {
          const found = this.findFileByName(fullPath, 'package.json');
          if (found) {
            return found;
          }
        }
      }
      return null;
    } catch (error) {
      PPLogger.e('findPackageJson error: ' + (error as BusinessError).message);
      return null;
    }
  }

  findFileByName(dirPath: string, fileName: string): string | null {
    try {
      // 1. 列出当前目录所有文件和子目录
      const files: string[] = fs.listFileSync(dirPath);

      // 2. 遍历检查每个条目
      for (const file of files) {
        const fullPath: string = `${dirPath}/${file}`;
        const stat = fs.statSync(fullPath); // 获取文件信息

        // 3. 如果是文件且名称匹配，直接返回
        if (stat.isFile() && file === fileName) {
          return fullPath;
        }
        // 4. 如果是目录，递归查找
        else if (stat.isDirectory()) {
          const found = this.findFileByName(fullPath, fileName);
          if (found) {
            return found;
          }
        }
      }
      return null; // 未找到
    } catch (error) {
      console.error(`[ERROR] findFileByName: ${(error as BusinessError).message}`);
      return null;
    }
  }

  async compareVersions(jsonPackages?: PPDfuPackagesVo): Promise<PPSendPackageVo[]> {
    const result: PPSendPackageVo[] = [];

    // MCU文件比对
    if (this.shouldUpgrade(
      jsonPackages?.mcu?.version,
      this.currentVersion.mcu
    )) {
      await this.addPackageToResult(
        result,
        jsonPackages?.ble,
        PPBleDfuFileType.mcu
      );
    }

    // BLE文件比对
    if (this.shouldUpgrade(
      jsonPackages?.ble?.version,
      this.currentVersion.ble
    )) {
      await this.addPackageToResult(
        result,
        jsonPackages?.ble,
        PPBleDfuFileType.ble
      );
    }

    // WIFI文件比对
    if (this.shouldUpgrade(
      jsonPackages?.wifi?.version,
      this.currentVersion.wifi
    )) {
      await this.addPackageToResult(
        result,
        jsonPackages?.wifi,
        PPBleDfuFileType.wifi
      );
    }

    // RES文件比对
    if (this.shouldUpgrade(
      jsonPackages?.res?.version,
      this.currentVersion.res
    )) {
      await this.addPackageToResult(
        result,
        jsonPackages?.res,
        PPBleDfuFileType.res
      );
    }

    return result;
  }

  private shouldUpgrade(newVersion?: string, currentVersion?: string): boolean {
    if (!newVersion || !currentVersion) {
      return false;
    }
    return parseInt(newVersion) > parseInt(currentVersion);
  }

  private async addPackageToResult(
    result: PPSendPackageVo[],
    pkg?: PackageInfo,
    fileType?: PPBleDfuFileType
  ): Promise<void> {
    if (!pkg?.filename) {
      return;
    }

    PPLogger.d(`${fileType} version is different. Filename: ${pkg.filename}`);
    const filePath = await FileFinder.findFile(this.otaFilePath, pkg.filename);

    if (filePath) {
      try {
        const data = await FileFinder.readFileContent(filePath);
        PPLogger.d(`Read ${data?.length} bytes from file.`);

        if (data) {
          const packageVo = new PPSendPackageVo({
            fileVersion: pkg.version,
            fileType: fileType,
            data: new Uint8Array(data.buffer)
          });
          result.push(packageVo);
        }
      } catch (e) {
        PPLogger.e('Error reading file: ' + JSON.stringify(e));
      }
    }
  }
}