/**
 * 蓝牙DFU错误码枚举
 */
export class PPBleFFF2ErrorCode {
  // 枚举值定义
  public static readonly Unknown = new PPBleFFF2ErrorCode(0x00, '未识别错误码');
  public static readonly Ok = new PPBleFFF2ErrorCode(0x01, '成功');
  public static readonly InvalidParameter = new PPBleFFF2ErrorCode(0x02, '无效参数');
  public static readonly FileSizeExceedsLimit = new PPBleFFF2ErrorCode(0x03, '文件大小超过限制');
  public static readonly PacketLost = new PPBleFFF2ErrorCode(0x04, '丢包');
  public static readonly FileFrameOrderWrong = new PPBleFFF2ErrorCode(0x05, '文件升级帧顺序错误');
  public static readonly Timeout = new PPBleFFF2ErrorCode(0x06, '超时');
  public static readonly InvalidState = new PPBleFFF2ErrorCode(0x07, '状态机错误');
  public static readonly Disconnected = new PPBleFFF2ErrorCode(0x08, '断连');
  public static readonly LowBattery = new PPBleFFF2ErrorCode(0x09, '低电');
  public static readonly FirmwareUpgrading = new PPBleFFF2ErrorCode(0x0a, '固件升级中');
  public static readonly SignatureHeadMiss = new PPBleFFF2ErrorCode(0x0b, '签名固件无头错误');
  public static readonly SignatureHeadFormatWrong = new PPBleFFF2ErrorCode(0x0c, '签名固件头格式错误');
  public static readonly SignaturePnpMismatch = new PPBleFFF2ErrorCode(0x0d, '签名固件PNP不匹配');
  public static readonly SignatureFirmwareTypeError = new PPBleFFF2ErrorCode(0x0e, '签名固件类型错误');
  public static readonly SignatureVerifyFailed = new PPBleFFF2ErrorCode(0x0f, '签名校验失败');
  public static readonly FirmwareInternalError = new PPBleFFF2ErrorCode(0x10, '固件内部错误');
  public static readonly FirmwareContinueDfuTypeIsError = new PPBleFFF2ErrorCode(0x11, '断点续传类型不对');
  public static readonly FirmwareContinueDfuVerIsError = new PPBleFFF2ErrorCode(0x12, '断点续传版本不对');
  public static readonly FirmwareContinueDfuFileSizeIsError = new PPBleFFF2ErrorCode(0x13, '断点续传文件偏移大于文件大小');
  public static readonly FirmwareChunkSizeIsError = new PPBleFFF2ErrorCode(0x14, '数据块大小错误');
  public static readonly FlashOperateError = new PPBleFFF2ErrorCode(0x15, 'FLASH操作错误');

  // 枚举值列表
  public static readonly values: PPBleFFF2ErrorCode[] = [
    PPBleFFF2ErrorCode.Unknown,
    PPBleFFF2ErrorCode.Ok,
    PPBleFFF2ErrorCode.InvalidParameter,
    PPBleFFF2ErrorCode.FileSizeExceedsLimit,
    PPBleFFF2ErrorCode.PacketLost,
    PPBleFFF2ErrorCode.FileFrameOrderWrong,
    PPBleFFF2ErrorCode.Timeout,
    PPBleFFF2ErrorCode.InvalidState,
    PPBleFFF2ErrorCode.Disconnected,
    PPBleFFF2ErrorCode.LowBattery,
    PPBleFFF2ErrorCode.FirmwareUpgrading,
    PPBleFFF2ErrorCode.SignatureHeadMiss,
    PPBleFFF2ErrorCode.SignatureHeadFormatWrong,
    PPBleFFF2ErrorCode.SignaturePnpMismatch,
    PPBleFFF2ErrorCode.SignatureFirmwareTypeError,
    PPBleFFF2ErrorCode.SignatureVerifyFailed,
    PPBleFFF2ErrorCode.FirmwareInternalError,
    PPBleFFF2ErrorCode.FirmwareContinueDfuTypeIsError,
    PPBleFFF2ErrorCode.FirmwareContinueDfuVerIsError,
    PPBleFFF2ErrorCode.FirmwareContinueDfuFileSizeIsError,
    PPBleFFF2ErrorCode.FirmwareChunkSizeIsError,
    PPBleFFF2ErrorCode.FlashOperateError
  ];

  // 枚举属性
  private readonly _value: number;
  private readonly _description: string;

  private constructor(value: number, description: string) {
    this._value = value;
    this._description = description;
  }

  /**
   * 获取错误码值
   */
  public get value(): number {
    return this._value;
  }

  /**
   * 获取错误描述
   */
  public get description(): string {
    return this._description;
  }

  /**
   * 根据数值获取枚举实例
   * @param value 错误码值
   * @returns 对应的枚举实例
   * @throws 当找不到对应错误码时抛出错误
   */
  public static fromValue(value: number): PPBleFFF2ErrorCode {
    const found = PPBleFFF2ErrorCode.values.find(code => code.value === value);
    if (!found) {
      throw new Error(`No PPBleFFF2ErrorCode with value ${value} found.`);
    }
    return found;
  }

  /**
   * 转换为字符串
   */
  public toString(): string {
    return `${this._description} (0x${this._value.toString(16).padStart(2, '0')})`;
  }
}