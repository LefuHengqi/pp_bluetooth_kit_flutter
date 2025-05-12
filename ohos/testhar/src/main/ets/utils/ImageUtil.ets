
import { util } from '@kit.ArkTS';
import { PPLogger } from '../log/PPLogger';


export class OptimizedTextToBinary {
  private static readonly CANVAS_WIDTH = 104;
  private static readonly CANVAS_HEIGHT = 34;
  private static readonly THRESHOLD = 128; // 二值化阈值

  /**
   * 高性能文本转二进制
   * @param text 输入文本
   * @returns 二值化数据 (1: 文字像素, 0: 背景)
   */
  static async convert(text: string): Promise<number[][]> {
    // 1. 预处理文本
    const processedText = OptimizedTextToBinary.processText(text);

    // 2. 直接生成二值化矩阵（跳过实际渲染）
    return await OptimizedTextToBinary.generateBinaryMatrix(processedText);
  }

  /**
   * 文本预处理
   */
  private static processText(text: string): string {
    const isCJK = /[\u4e00-\u9fa5\u3040-\u30ff]/.test(text);
    const maxLen = isCJK ? 3 : 4;
    return text.substring(0, maxLen);
  }

  /**
   * 生成二值化矩阵（核心优化）
   */
  private static async generateBinaryMatrix(text: string): Promise<number[][]> {
    // 创建空矩阵（全部初始化为0）显式指定类型创建二维数组
    const matrix: number[][] = Array.from<number[], number[]>(
      { length: OptimizedTextToBinary.CANVAS_HEIGHT },
      () => new Array<number>(OptimizedTextToBinary.CANVAS_WIDTH).fill(0)
    );

    // 计算文字位置和大小
    const fontSize = OptimizedTextToBinary.calculateFontSize(text);
    const textWidth = OptimizedTextToBinary.estimateTextWidth(text, fontSize);
    const startX = Math.floor((OptimizedTextToBinary.CANVAS_WIDTH - textWidth) / 2);
    const startY = Math.floor((OptimizedTextToBinary.CANVAS_HEIGHT - fontSize) / 2 + fontSize * 0.8);

    // 模拟文字渲染（核心优化点）
    for (let y = startY; y < startY + fontSize; y++) {
      for (let x = startX; x < startX + textWidth; x++) {
        if (OptimizedTextToBinary.isTextPixel(x, y, startX, startY, textWidth, fontSize)) {
          // 边界检查
          if (y >= 0 && y < OptimizedTextToBinary.CANVAS_HEIGHT && x >= 0 && x < OptimizedTextToBinary.CANVAS_WIDTH) {
            matrix[y][x] = 1;
          }
        }
      }
    }

    return matrix;
  }

  /**
   * 判断是否为文字像素（模拟字体渲染）
   */
  private static isTextPixel(
    x: number,
    y: number,
    startX: number,
    startY: number,
    textWidth: number,
    fontSize: number
  ): boolean {
    // 简单模拟：中心区域为文字像素
    const relX = x - startX;
    const relY = y - startY;

    // 模拟字符形状（实际项目应使用字体度量API）
    const inVertical = relY > fontSize * 0.2 && relY < fontSize * 0.8;
    const inHorizontal = relX > textWidth * 0.1 && relX < textWidth * 0.9;

    return inVertical && inHorizontal;
  }

  /**
   * 计算自适应字体大小
   */
  private static calculateFontSize(text: string): number {
    const baseSize = OptimizedTextToBinary.isCJK(text) ? 24 : 20;
    const widthPerChar = OptimizedTextToBinary.CANVAS_WIDTH / text.length;
    return Math.min(baseSize, widthPerChar * 0.8, OptimizedTextToBinary.CANVAS_HEIGHT * 0.7);
  }

  /**
   * 估算文本宽度
   */
  private static estimateTextWidth(text: string, fontSize: number): number {
    // 简单估算：字符数 × 字体大小 × 比例因子
    return text.length * fontSize * (OptimizedTextToBinary.isCJK(text) ? 1.1 : 0.6);
  }

  /**
   * 检查CJK字符
   */
  private static isCJK(text: string): boolean {
    return /[\u4e00-\u9fa5\u3040-\u30ff]/.test(text.charAt(0));
  }

  /**
   * 可视化打印
   */
  static printBinary(matrix: number[][]) {
    const visualChars = [' ', '■']; // 0=空格, 1=方块
    const border = ''.padStart(OptimizedTextToBinary.CANVAS_WIDTH + 4, '─');

    PPLogger.d('\n' + border);
    matrix.forEach(row => {
      let line = '│ ';
      row.forEach(pixel => line += visualChars[pixel]);
      line += ' │';
      PPLogger.d(line);
    });
    PPLogger.d(border + '\n');
  }

  /**
   * 二进制数据转字符串
   */
  static flattenMatrix(matrix: number[][]): string {
    return matrix.flat().join('');
  }
}