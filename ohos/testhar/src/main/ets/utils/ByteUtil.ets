import util from "@ohos.util";

export class ByteUtil {

  // 定义函数将十进制数转换为指定长度字节的 number[]
  static decimalToByteList(decimalNumber: number, byteLength: number): number[] {
    const list: number[] = [];

    // 小端模式：低位字节在前，高位字节在后
    for (let i = 0; i < byteLength; i++) {
      list.push((decimalNumber >> (i * 8)) & 0xFF);
    }

    return list;
  }

  static byteToString(bytes: number[]): string {
    let sb = "";
    if (bytes && bytes.length > 0) {
      for (const byte of bytes) {
        sb += byte.toString(16).padStart(2, '0').toUpperCase();
      }
    }
    return sb;
  }

  // ArrayBuffer/Uint8Array → ASCII
  static bufferToAscii(buffer: ArrayBuffer | Uint8Array | null | undefined): string {
    if (!buffer) {
      return '';
    }
    const bytes = buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer);
    // 3. 使用 TextDecoder 优先处理
    try {
      return new util.TextDecoder('ascii', { fatal: true }).decode(bytes);
    } catch (e) {
      // 4. 回退方案：手动过滤非ASCII字符
      let result = '';
      for (let i = 0; i < bytes.length; i++) {
        const byte = bytes[i];
        result += byte > 0 && byte <= 127 ? String.fromCharCode(byte) : '?';
      }
      return result;
    }
  }

  /**
   * 将 Uint8Array 转 UTF-8 字符串
   * @param data 蓝牙数据 (Uint8Array)
   */
  static uint8ArrayToString(data: Uint8Array): string {
    let length = data.length;
    const decoder = new util.TextDecoder('utf-8');
    return decoder.decode(data.subarray(0, length));
  }

  static hexToTen(hex: string): number {
    if (!hex) {
      return 0;
    }
    return parseInt(hex, 16);
  }

  /**
   * 大端转成小端，或小端转大端
   */
  static hexToLittleEndianMode(uidHex: string | null): string {
    if (!uidHex) {
      return "";
    }

    const arrayList: string[] = [];
    for (let i = 0; i < Math.floor(uidHex.length / 2); i++) {
      arrayList.push(uidHex.substring(i * 2, i * 2 + 2));
    }

    arrayList.reverse(); // 反转列表
    return arrayList.join("");
  }

  /**
   * 字节序转换（大端 ↔ 小端）
   * @param bytes 输入的字节数组
   * @returns 转换后的字节数组（新实例）
   */
  static swapEndian(bytes: Uint8Array): Uint8Array {
    if (!bytes || bytes.length === 0) {
      return new Uint8Array(0);
    }

    // 创建新数组存储反转结果
    const reversed = new Uint8Array(bytes.length);

    // 反转字节顺序
    for (let i = 0; i < bytes.length; i++) {
      reversed[i] = bytes[bytes.length - 1 - i];
    }

    return reversed;
  }

  /**
   * long转16进制字符串并且指定长度，长度不够默认补0
   */
  static longToHexAndSpecLen(memberId: number, length: number): string {
    let buffer = "";
    const memberHex = ByteUtil.decimalToHex(memberId);

    if (memberHex.length < length) {
      buffer += "0".repeat(length - memberHex.length);
    }

    buffer += memberHex;
    return buffer;
  }

  /**
   * 自动在前面补0
   * @param hex 原始16进制字符串
   * @param maxLen 目标长度
   * @returns 补0后的字符串
   */
   static autoLeftPadZero(hex: string, maxLen: number): string {
    let result: string = '';

    // 处理超长情况
    if (hex.length > maxLen) {
      return hex.substring(0, maxLen);
    }

    // 补0处理
    const zeroCount = maxLen - hex.length;
    if (zeroCount > 0) {
      result = '0'.repeat(zeroCount) + hex;
    } else {
      result = hex;
    }

    return result;
  }

  static autoPadZeroStr(hex: string, maxLen: number): string {
    let stringBuffer = "";

    if (hex.length < maxLen) {
      stringBuffer += hex;
      stringBuffer += "0".repeat(maxLen - hex.length);
    } else if (hex.length >= maxLen) {
      return hex.substring(0, maxLen);
    }

    return stringBuffer;
  }

  /**
   * 检测并补全Uint8Array长度
   * @param data 原始数据
   * @param length 目标长度
   * @returns 补全后的新Uint8Array
   */
  static autoPadZero(data: Uint8Array, length: number): Uint8Array {
    // 参数校验
    if (length <= 0) {
      throw new Error("Length must be positive");
    }

    // 如果数据已足够长，直接返回副本
    if (data.length >= length) {
      return new Uint8Array(data);
    }

    // 创建新数组并填充0x00
    const padded = new Uint8Array(length);
    padded.set(data); // 拷贝原始数据
    padded.fill(0x00, data.length); // 剩余部分填0

    return padded;
  }

  /**
   * 将数字转换为指定长度的 Uint8Array，不足时前面补 0x00
   * @param num 输入数字（整数）
   * @param length 目标 Uint8Array 的长度
   * @returns 转换后的 Uint8Array
   */
  static numberToUint8Array = (num: number, length: number): Uint8Array => {
    // 验证输入是否为整数
    if (!Number.isInteger(num)) {
      throw new Error("Input must be an integer");
    }

    // 创建一个指定长度的 Uint8Array，默认填充 0x00
    const result = new Uint8Array(length);

    // 将数字转换为字节数组（大端序）
    for (let i = length - 1; i >= 0; i--) {
      result[i] = num & 0xff; // 取最低 8 位
      num = num >>> 8; // 右移 8 位

      // 如果数字已经为 0，提前结束
      if (num === 0) {
        break;
      }
    }

    return result;
  };

  // 将十进制转换为十六进制
  static decimalToHex(decimal: number): string {
    // 将十进制数转换为十六进制字符串
    let hex = decimal.toString(16).toUpperCase();

    // 如果十六进制字符串的长度是奇数，则在前面补零
    if (hex.length % 2 !== 0) {
      hex = '0' + hex;
    }
    return hex;
  }

  /**
   * 将十进制数转为Uint8Array（自动处理大端序）
   * @param value 要转换的数字
   * @param byteLength 字节长度（1-4）
   */
  static decimalToBytes(value: number, byteLength: number = 1): Uint8Array {
    if (byteLength < 1 || byteLength > 4) {
      throw new Error('Byte length must be between 1 and 4');
    }

    const buffer = new ArrayBuffer(4);
    const view = new DataView(buffer);
    view.setUint32(0, value, false); // 大端序写入

    return new Uint8Array(buffer).slice(4 - byteLength);
  }

  /**
   * 合并多个Uint8Array
   */
  static concatArrays(arrays: Uint8Array[]): Uint8Array {
    const totalLength = arrays.reduce((sum, arr) => sum + arr.length, 0);
    const result = new Uint8Array(totalLength);
    let offset = 0;

    arrays.forEach(arr => {
      result.set(arr, offset);
      offset += arr.length;
    });

    return result;
  }

  static hexToBytes(hex: string): Uint8Array {
    hex = hex.replace(/\s+/g, '');
    if (hex.length % 2 !== 0) {
      throw new Error("Hex string must have an even length");
    }
    const bytes: Uint8Array = new Uint8Array();
    for (let i = 0; i < hex.length; i += 2) {
      // 将每两个字符转换为一个字节
      const byteString = hex.substring(i, i + 2);
      const byteValue = parseInt(byteString, 16);
      bytes[i] = byteValue;
    }
    return bytes;
  }

  /// 将字符串转换为十六进制字符串
  static stringToHexString(input: string): string {
    return Array.from(input)
      .map(c => c.charCodeAt(0).toString(16).padStart(2, '0'))
      .join('');
  }

  /**
   * 计算字节数组的异或校验值并返回新数组（包含原始数据和校验位）
   * @param data 原始字节数组
   * @returns 包含校验位的新字节数组
   */
  static getXor(data: Uint8Array): Uint8Array {
    // 创建新数组（长度+1用于存放校验位）
    const result = new Uint8Array(data.length + 1);

    // 校验位初始化为第一个字节
    let xorValue = data[0];
    result[0] = data[0];

    // 计算异或校验
    for (let i = 1; i < data.length; i++) {
      result[i] = data[i];
      xorValue ^= data[i]; // 按位异或
    }

    // 存入校验位
    result[data.length] = xorValue;

    return result;
  }

  static hexStringToString(hexString: string): string {
    // 将十六进制字符串拆分为每两个字符一组
    const hexPairs: string[] = [];
    for (let i = 0; i < hexString.length; i += 2) {
      hexPairs.push(hexString.substring(i, i + 2));
    }

    // 将每对十六进制字符转换为整数，然后转换为对应的字符
    let result = '';
    for (const pair of hexPairs) {
      const charCode = parseInt(pair, 16); // 将十六进制转换为整数
      result += String.fromCharCode(charCode); // 将整数转换为字符
    }

    return result;
  }

  /// 计算 XOR 值
  static getXorValue(bytes: Uint8Array): number {
    let xor = 0;
    for (const byte of bytes) {
      xor ^= byte;
    }
    return xor;
  }

  // 将字符串按指定长度分割，并转换为字节数组列表
  static getSendByteList(byteStr: string, length: number): Uint8Array[] {
    let size = Math.floor(byteStr.length / length); // 计算完整的分段数量
    if (byteStr.length % length !== 0) {
      size += 1;
    } // 如果有剩余部分，增加一个分段

    const result: Uint8Array[] = []; // 存储结果的列表

    for (let i = 0; i < size; i++) {
      const start = i * length; // 当前分段的起始位置
      let end = (i + 1) * length; // 当前分段的结束位置
      // 确保结束位置不超过字符串长度
      if (end > byteStr.length) {
        end = byteStr.length;
      }

      const childStr = byteStr.substring(start, end); // 截取子字符串
      if (childStr) {
        // 检查子字符串是否为空
        const subByte = new Uint8Array(ByteUtil.hexToBytes(childStr)); // 将字符串转换为字节数组
        result.push(subByte); // 添加到结果列表
      }
    }

    return result;
  }

  static getBinaryStrByHexStr(hex: string): string {
    // 将十六进制字符串转换为整数
    const decimal = parseInt(hex, 16);

    // 将整数转换为二进制字符串
    let binaryStr = decimal.toString(2);

    // 如果二进制字符串长度小于8，前面补零
    while (binaryStr.length < 8) {
      binaryStr = '0' + binaryStr;
    }

    return binaryStr;
  }

  static getHexByBinary(binary: string): string {
    // 将二进制字符串转换为整数
    const decimal = parseInt(binary, 2);

    // 将整数转换为十六进制字符串
    return decimal.toString(16);
  }

  static getHexByDecimal(decimal: number): string {
    // 将十进制数转换为十六进制字符串
    return decimal.toString(16);
  }

  static weightKgToHex(weight: number): string {
    const iWeight = Math.round((weight + 0.005) * 100);
    const hex = ByteUtil.hexToLittleEndianMode(
      ByteUtil.longToHexAndSpecLen(iWeight, 4));
    return hex;
  }

  static hexToRgb(hexColor: string): number[] | null {
    // 去除颜色值中的 "#" 符号
    hexColor = hexColor.replace(/#/g, '');

    if (hexColor.length === 8) {
      // 如果颜色值是8位（带透明度），则去除透明度部分
      hexColor = hexColor.substring(2); // 去除透明度部分，只保留RGB部分
    }

    if (hexColor.length === 6) {
      const red = parseInt(hexColor.substring(0, 2), 16);
      const green = parseInt(hexColor.substring(2, 4), 16);
      const blue = parseInt(hexColor.substring(4, 6), 16);

      // 返回包含红、绿、蓝三个值的列表
      return [red, green, blue];
    } else {
      return null;
    }
  }

  static typedArrayToBuffer(array: Uint8Array): ArrayBuffer {
    return array.buffer.slice(array.byteOffset, array.byteLength + array.byteOffset)
  }

  static uint8ArrayToHex(buffer: Uint8Array): string {
    return Array.from(buffer)
      .map(byte => byte.toString(16).padStart(2, '0'))
      .join('');
  }

  static decimalToByte(value: number): number {
    return value & 0xFF; // 确保返回单字节
  }

  /**
   * 将Uint8Array转换为long（支持1-8字节）
   * @param bytes 字节数组
   * @param littleEndian 是否小端序（默认大端序）
   * @param signed 是否处理为有符号数（默认无符号）
   */
  static bytesToLong(
    bytes: Uint8Array,
    littleEndian: boolean = false,
    signed: boolean = false
  ): number {
    if (!bytes || bytes.length === 0 || bytes.length > 8) {
      console.error("数据长度必须为1-8字节");
      return 0;
    }

    let result = 0;
    const len = bytes.length;

    // 处理字节序
    for (let i = 0; i < len; i++) {
      const shift = littleEndian ? i * 8 : (len - 1 - i) * 8;
      result |= bytes[littleEndian ? i : len - 1 - i] << shift;
    }

    // 处理有符号数（补码转换）
    if (signed && len > 0) {
      const signBit = 1 << (len * 8 - 1);
      if (result & signBit) {
        result -= 2 * signBit;
      }
    }

    return result;
  }

  static isXorValue(checkData: Uint8Array): boolean {
    if (checkData.length < 2) {
      return false;
    }

    const needCheckData = checkData.subarray(0, checkData.length - 1)

    const xorByte = checkData[checkData.length - 1]

    // 计算异或值（从第1个字节开始累积）
    const resultByte = needCheckData.reduce((acc, current) => acc ^ current, 0);

    // 直接比较字节值
    return resultByte === (xorByte & 0xFF); // 确保比较的是单字节
  }

  /**
   * 16进制字符串转Uint8Array（自动处理奇数长度）
   */
  static hexStringToUint8Array(hexStr: string): Uint8Array {
    // 补零到偶数长度
    if (hexStr.length % 2 !== 0) {
      hexStr = '0' + hexStr;
    }

    const bytes: number[] = [];
    for (let i = 0; i < hexStr.length; i += 2) {
      bytes.push(parseInt(hexStr.substr(i, 2), 16));
    }
    return new Uint8Array(bytes);
  }

  /**
   * 将字符串转换为 Uint8Array
   * @param str 输入字符串
   * @param encoding 文本编码格式（默认 UTF-8）
   * @returns Uint8Array
   */
  static stringToUint8Array(str: string, encoding: 'utf-8' | 'utf-16' = 'utf-8'): Uint8Array {
    if (!str) {
      return new Uint8Array(0);
    }

    // 优先使用 HarmonyOS 官方 TextEncoder
    try {
      const encoder = new util.TextEncoder(encoding);
      return encoder.encode(str);
    } catch (e) {
      console.error("TextEncoder failed:", e);
    }

    // 兼容实现（纯ArkTS）
    const bytes = new Uint8Array(str.length * (encoding === 'utf-16' ? 2 : 1));
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i);
      if (encoding === 'utf-16') {
        bytes[i * 2] = code & 0xFF;
        bytes[i * 2 + 1] = code >> 8;
      } else {
        bytes[i] = code > 255 ? 0x3F /*?*/ : code;
      }
    }
    return bytes;
  };


  /**
   * 根据 MTU 拆包
   * @param data 原始数据 (Uint8Array)
   * @param mtu 最大传输单元 (默认 1500)
   * @returns 拆分后的分片数组 (Uint8Array[])
   */
  static splitByMTU = (data: Uint8Array, mtu: number = 20): Uint8Array[] => {
    if (mtu <= 0) {
      throw new Error("MTU must be greater than 0");
    }

    const totalLength = data.length;
    const chunks: Uint8Array[] = [];

    // 计算需要拆分成多少块
    const chunkCount = Math.ceil(totalLength / mtu);

    for (let i = 0; i < chunkCount; i++) {
      const start = i * mtu;
      const end = Math.min(start + mtu, totalLength);
      const chunk = data.slice(start, end); // 截取当前分片
      chunks.push(chunk);
    }

    return chunks;
  };
  /**
   * 根据 MTU 拆包，并在每个分片前拼接 0x00
   * @param data 原始数据 (Uint8Array)
   * @param mtu 最大传输单元 (默认 20)
   * @returns 拆分后的分片数组 (Uint8Array[])，每个分片前带 0x00
   */
  static splitByMTUWithLeadingZero = (data: Uint8Array, mtu: number = 20): Uint8Array[] => {
    if (mtu <= 2) {
      throw new Error("MTU must be greater than 2 (need 2 bytes for header)");
    }

    const payloadSize = mtu - 2; // 扣除 0x00 和包序号占用的 2 字节
    const totalLength = data.length;
    const chunks: Uint8Array[] = [];

    const chunkCount = Math.ceil(totalLength / payloadSize);

    for (let i = 0; i < chunkCount; i++) {
      const start = i * payloadSize;
      const end = Math.min(start + payloadSize, totalLength);

      // 创建新分片（长度 = 原始分片 + 2 字节的头部）
      const chunk = new Uint8Array(end - start + 2);
      chunk[0] = 0x00; // 第一个字节是 0x00
      chunk[1] = i; // 第二个字节是包序号
      chunk.set(data.slice(start, end), 2); // 填充剩余数据

      chunks.push(chunk);
    }

    return chunks;
  };

  private static readonly HEX_CHARS = "0123456789ABCDEF";

  /**
   * 二进制字符串转十六进制字符串
   * @param binary 二进制字符串（仅含0/1）
   * @returns 十六进制字符串（大写）
   */
  static binaryToHexString(binary: string): string {
    // 输入验证
    if (!/^[01]+$/.test(binary)) {
      throw new Error("Invalid binary string");
    }

    // 补全到4的倍数长度
    const paddingLength = (4 - (binary.length % 4)) % 4;
    const paddedBinary = "0".repeat(paddingLength) + binary;

    // 预分配结果数组（性能优化）
    const result = new Array<string>(Math.ceil(paddedBinary.length / 4));

    // 每4位一组处理
    for (let i = 0; i < paddedBinary.length; i += 4) {
      const nibble = paddedBinary.substr(i, 4);
      const decimalValue = parseInt(nibble, 2);
      result.push(ByteUtil.HEX_CHARS.charAt(decimalValue));
    }

    return result.join("");
  }


}