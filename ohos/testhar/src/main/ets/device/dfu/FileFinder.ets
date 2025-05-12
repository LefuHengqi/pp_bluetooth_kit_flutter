// FileFinder.ets
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import { PPLogger } from '../../log/PPLogger';

export class FileFinder {
  /**
   * 查找文件（递归）
   * @param dirPath 搜索目录路径
   * @param fileName 目标文件名
   * @returns 文件完整路径或null
   */
  static async findFile(dirPath?: string, fileName?: string): Promise<string | null> {
    if (!dirPath || !fileName) {
      console.error('[FileFinder] 无效参数');
      return null;
    }

    try {
      // 1. 检查目录可访问
      await fs.access(dirPath);

      // 2. 列出目录内容
      const files = await fs.listFile(dirPath);

      // 3. 遍历查找
      for (const file of files) {
        const fullPath = `${dirPath}/${file}`;
        const stat = await fs.stat(fullPath);

        // 4. 精确匹配文件名
        if (stat.isFile() && file === fileName) {
          console.log(`[FileFinder] 找到文件: ${fullPath}`);
          return fullPath;
        }

        // 5. 递归搜索子目录
        if (stat.isDirectory()) {
          const found = await FileFinder.findFile(fullPath, fileName);
          if (found) {
            return found;
          }
        }
      }
    } catch (error) {
      console.error(`[FileFinder] 错误: ${(error as BusinessError).message}`);
    }

    return null;
  }

  /**
   * 安全读取文件内容
   * @param filePath 文件路径
   * @returns Uint8Array或null
   */
  static async readFileContent(filePath?: string): Promise<Uint8Array | null> {
    if (filePath) {
      let file: fs.File | null = null;
      try {
        // 1. 打开文件（返回File对象）
        file = await fs.open(filePath, fs.OpenMode.READ_ONLY);

        // 2. 获取文件信息
        const stat = await fs.stat(filePath);

        // 3. 读取内容
        const buffer = new ArrayBuffer(stat.size);
        const bytesRead = await fs.read(file.fd, buffer);

        // 4. 返回有效数据
        return new Uint8Array(buffer, 0, bytesRead);
      } catch (e) {
        PPLogger.e('Error reading file: ' + JSON.stringify(e));
        return null;
      } finally {
        // 5. 确保关闭文件
        if (file !== null) {
          await fs.close(file.fd);
        }
      }
    }
    return null;
  }
}

