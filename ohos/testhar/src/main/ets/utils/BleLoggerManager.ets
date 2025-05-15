// utils/BleLogger.ets
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';

// 类型定义
interface LogFileStat {
  size: number;
}

interface BleLogOptions {
  bufferSize?: number; // 缓存条数阈值，默认20
  flushInterval?: number; // 刷新间隔(ms)，默认500
}

/**
 * 蓝牙日志记录工具
 */
export class BleLoggerManager {
  private logDir: string; // 日志目录路径
  private deviceName: string; // 设备名称
  private deviceMac: string; // 设备Mac地址
  private buffer: string[] = []; // 日志缓存
  private flushTimer: number = 0; // 定时器ID
  private isWriting: boolean = false;
  private readonly bufferSize: number;
  private readonly flushInterval: number;
  private filePath = "";

  /**
   * 构造函数
   * @param logDir 日志存储目录路径
   * @param options 配置选项
   */
  constructor(logFolder: string, deviceName: string, deviceMac: string, options?: BleLogOptions) {
    this.logDir = logFolder;
    this.bufferSize = options?.bufferSize ?? 20;
    this.flushInterval = options?.flushInterval ?? 500;
    this.deviceName = deviceName;
    this.deviceMac = deviceMac;
    this.filePath = "";
    this.filePath = this.getLogFilePath();

    // 初始化目录
    this.ensureDir();
  }

  /**
   * 确保日志目录存在
   */
  private async ensureDir(): Promise<void> {
    try {
      await fs.access(this.logDir);
    } catch (err) {
      await fs.mkdir(this.logDir);
      console.info('[BleLogger] Created log directory:', this.logDir);
    }
  }

  /**
   * 接收蓝牙日志数据
   * @param data 日志内容
   */
  public receive(data: string): void {
    // const timestamp: string = new Date().toISOString();
    this.buffer.push(data);

    // 达到阈值立即写入
    if (this.buffer.length >= this.bufferSize) {
      this.flush();
    }
    // 否则启动定时器
    else if (this.flushTimer === 0) {
      this.flushTimer = setTimeout(() => this.flush(), this.flushInterval);
    }
  }

  public getLogFilePath(): string {
    if (this.filePath) {
      return this.filePath;
    } else {
      return `${this.logDir}/${this.getFileName()}`;
    }
  }

  /**
   * 强制刷新缓存
   */
  public async forceFlush(): Promise<void> {
    if (this.flushTimer !== 0) {
      clearTimeout(this.flushTimer);
      this.flushTimer = 0;
    }
    await this.flush();
  }

  /**
   * 执行写入操作
   */
  private async flush(): Promise<void> {
    if (this.isWriting || this.buffer.length === 0) {
      return;
    }

    this.isWriting = true;
    const logsToWrite: string[] = [...this.buffer];
    this.buffer = [];

    try {
      const logFile: string = this.getLogFilePath();

      // 获取文件当前大小（新文件返回0）
      const stat: LogFileStat = await this.getFileStat(logFile);

      // 追加写入
      const file = await fs.open(logFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.lseek(file.fd, stat.size, fs.WhenceType.SEEK_SET);
      await fs.write(file.fd, logsToWrite.join(''));
      await fs.close(file.fd);

      console.debug('[BleLogger] Wrote', logsToWrite.length, 'logs');
    } catch (err) {
      // 写入失败恢复缓存
      this.buffer.unshift(...logsToWrite);
      console.error('[BleLogger] Write failed:', JSON.stringify(err));
    } finally {
      this.isWriting = false;
    }
  }

  getFileName(): string {
    // 输出示例: "2023_11_15_14_30_45
    const now = new Date();
    const pad = (num: number, length = 2) => num.toString().padStart(length, '0');

    return `${this.deviceName}_${this.deviceMac}_${now.getFullYear()}_${pad(now.getMonth() +
      1)}_${pad(now.getDate())}_` +
      `${pad(now.getHours())}_${pad(now.getMinutes())}_${pad(now.getSeconds())}.txt`;
  }

  /**
   * 获取文件状态（兼容文件不存在的情况）
   */
  private async getFileStat(path: string): Promise<LogFileStat> {
    try {
      const stat = await fs.stat(path);
      return { size: stat.size };
    } catch (err) {
      return { size: 0 };
    }
  }

  /**
   * 销毁资源
   */
  public async destroy(): Promise<void> {
    await this.forceFlush();
    if (this.flushTimer !== 0) {
      clearTimeout(this.flushTimer);
    }
  }
}