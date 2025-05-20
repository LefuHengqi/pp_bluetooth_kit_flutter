import { PPUnitType } from "../enums/PPUnitType";

// 设备管理器类
class DeviceManager {
  static readonly HEALTH_SCALE3: string = "HealthScale3";
}

// 单位工具类
export class UnitUtil {
  // 单位常量
  static readonly unitKG: number = 0;
  static readonly unitLB: number = 1;
  static readonly unitST: number = 2;
  static readonly unitJin: number = 3;
  static readonly unitG: number = 4;
  static readonly unitLBOZ: number = 5;
  static readonly unitOZ: number = 6;
  static readonly unitMLWater: number = 7;
  static readonly unitMLMilk: number = 8;
  static readonly unitST_LB: number = 9;

  // 根据单位类型获取对应整数值
  static getUnitInt(unitType: PPUnitType, scaleName: string): number {
    switch (unitType) {
      case PPUnitType.Unit_KG:
        return UnitUtil.unitKG;
      case PPUnitType.Unit_LB:
        return UnitUtil.unitLB;
      case PPUnitType.PPUnitST_LB:
        return UnitUtil.unitST_LB;
      case PPUnitType.PPUnitST:
        return (scaleName && scaleName === DeviceManager.HEALTH_SCALE3)
          ? UnitUtil.unitST_LB : UnitUtil.unitST;
      case PPUnitType.PPUnitJin:
        return UnitUtil.unitJin;
      case PPUnitType.PPUnitG:
        return UnitUtil.unitG;
      case PPUnitType.PPUnitLBOZ:
        return UnitUtil.unitLBOZ;
      case PPUnitType.PPUnitOZ:
        return UnitUtil.unitOZ;
      case PPUnitType.PPUnitMLWater:
        return UnitUtil.unitMLWater;
      case PPUnitType.PPUnitMLMilk:
        return UnitUtil.unitMLMilk;
      case PPUnitType.PPUnitFL_OZ_MILK:
        return UnitUtil.unitMLMilk;
      case PPUnitType.PPUnitFL_OZ_WATER:
        return UnitUtil.unitMLWater;
      default:
        return UnitUtil.unitKG;
    }
  }

  // 根据整数值获取单位类型
  static getUnitType(unit: number, scaleName: string): PPUnitType {
    switch (unit) {
      case 0:
        return PPUnitType.Unit_KG;
      case 1:
        return PPUnitType.Unit_LB;
      case 2:
        return (scaleName && scaleName === DeviceManager.HEALTH_SCALE3)
          ? PPUnitType.PPUnitST : PPUnitType.PPUnitST_LB;
      case 3:
        return PPUnitType.PPUnitJin;
      case 4:
        return PPUnitType.PPUnitG;
      case 5:
        return PPUnitType.PPUnitLBOZ;
      case 6:
        return PPUnitType.PPUnitOZ;
      case 7:
        return PPUnitType.PPUnitMLWater;
      case 8:
        return PPUnitType.PPUnitMLMilk;
      case 9:
        return PPUnitType.PPUnitFL_OZ_WATER;
      case 10:
        return PPUnitType.PPUnitFL_OZ_MILK;
      case 11:
        return PPUnitType.PPUnitST;
      default:
        return PPUnitType.Unit_KG;
    }
  }

  // 简化版的获取单位类型方法
  static getUnitTypeSimple(unit: number): PPUnitType {
    return UnitUtil.getUnitType(unit, "");
  }

  // 电子单位枚举转整数值
  static electronicUnitEnum2Int(unitType: PPUnitType): number {
    switch (unitType) {
      case PPUnitType.Unit_KG:
      case PPUnitType.PPUnitJin:
        return 1;
      case PPUnitType.Unit_LB:
        return 2;
      case PPUnitType.PPUnitLBOZ:
        return 4;
      default:
        return 0;
    }
  }

  // Torre单位转PPUnit
  static unitTorre2PPUnit(unit: number): PPUnitType {
    switch (unit) {
      case 0:
        return PPUnitType.Unit_KG;
      case 1:
        return PPUnitType.Unit_LB;
      case 2:
        return PPUnitType.PPUnitJin;
      case 3:
        return PPUnitType.PPUnitST;
      case 4:
        return PPUnitType.PPUnitST_LB;
      default:
        return PPUnitType.Unit_KG;
    }
  }

  // PPUnit转Torre单位整数值
  static unitTorre2Int(unitType: PPUnitType): number {
    switch (unitType) {
      case PPUnitType.Unit_KG:
        return 0;
      case PPUnitType.Unit_LB:
        return 1;
      case PPUnitType.PPUnitJin:
        return 2;
      case PPUnitType.PPUnitST:
        return 3;
      case PPUnitType.PPUnitST_LB:
        return 4;
      default:
        return 0;
    }
  }

  static getUnitStr(unit?: PPUnitType | null): string {
    if (!unit || unit == null) return "kg";
    switch (unit) {
      case PPUnitType.Unit_KG:
        return "kg";
      case PPUnitType.Unit_LB:
        return "lb";
      case PPUnitType.PPUnitST:
        return "st";
      case PPUnitType.PPUnitJin:
        return "斤";
      case PPUnitType.PPUnitG:
        return "g";
      case PPUnitType.PPUnitLBOZ:
        return "lb:oz";
      case PPUnitType.PPUnitOZ:
        return "oz";
      case PPUnitType.PPUnitMLWater:
        return "water";
      case PPUnitType.PPUnitMLMilk:
        return "milk";
      default:
        return "kg";
    }
  }
}