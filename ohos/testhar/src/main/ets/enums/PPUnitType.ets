/**
 * 设备单位类型枚举
 *
 * @author liyp
 * @email liyp520@foxmail.com
 * @date 2025/2/6 15:49
 */
export class PPUnitType {
  // 枚举值
  public static readonly Unit_KG = new PPUnitType(0);
  public static readonly Unit_LB = new PPUnitType(1);
  public static readonly PPUnitST_LB = new PPUnitType(2);
  public static readonly PPUnitJin = new PPUnitType(3);
  public static readonly PPUnitG = new PPUnitType(4);
  public static readonly PPUnitLBOZ = new PPUnitType(5);
  public static readonly PPUnitOZ = new PPUnitType(6);
  public static readonly PPUnitMLWater = new PPUnitType(7);
  public static readonly PPUnitMLMilk = new PPUnitType(8);
  public static readonly PPUnitFL_OZ_WATER = new PPUnitType(9);
  public static readonly PPUnitFL_OZ_MILK = new PPUnitType(10);
  public static readonly PPUnitST = new PPUnitType(11);

  // 枚举值列表
  public static readonly values: PPUnitType[] = [
    PPUnitType.Unit_KG,
    PPUnitType.Unit_LB,
    PPUnitType.PPUnitST_LB,
    PPUnitType.PPUnitJin,
    PPUnitType.PPUnitG,
    PPUnitType.PPUnitLBOZ,
    PPUnitType.PPUnitOZ,
    PPUnitType.PPUnitMLWater,
    PPUnitType.PPUnitMLMilk,
    PPUnitType.PPUnitFL_OZ_WATER,
    PPUnitType.PPUnitFL_OZ_MILK,
    PPUnitType.PPUnitST
  ];

  // 枚举值
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  /**
   * 获取枚举值
   */
  public get type(): number {
    return this._type;
  }

  /**
   * 根据数值获取枚举实例
   * @param type 枚举数值
   * @returns 对应的枚举实例
   */
  public static fromType(type: number): PPUnitType | null {
    return PPUnitType.values.find(item => item.type === type) || null;
  }

  /**
   * 获取枚举名称
   */
  public toString(): string {
    switch (this) {
      case PPUnitType.Unit_KG: return "Unit_KG";
      case PPUnitType.Unit_LB: return "Unit_LB";
      case PPUnitType.PPUnitST_LB: return "PPUnitST_LB";
      case PPUnitType.PPUnitJin: return "PPUnitJin";
      case PPUnitType.PPUnitG: return "PPUnitG";
      case PPUnitType.PPUnitLBOZ: return "PPUnitLBOZ";
      case PPUnitType.PPUnitOZ: return "PPUnitOZ";
      case PPUnitType.PPUnitMLWater: return "PPUnitMLWater";
      case PPUnitType.PPUnitMLMilk: return "PPUnitMLMilk";
      case PPUnitType.PPUnitFL_OZ_WATER: return "PPUnitFL_OZ_WATER";
      case PPUnitType.PPUnitFL_OZ_MILK: return "PPUnitFL_OZ_MILK";
      case PPUnitType.PPUnitST: return "PPUnitST";
      default: return "Unknown";
    }
  }
}