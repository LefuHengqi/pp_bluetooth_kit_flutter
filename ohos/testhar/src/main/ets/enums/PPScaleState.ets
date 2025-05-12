/**
 * 秤状态类
 */
export class PPScaleState {
  public heartRateType: PPScaleStateHeartRateType = PPScaleStateHeartRateType.HEARTRATE_NO_MEASURE;
  public impedanceType: PPScaleStateImpedanceType = PPScaleStateImpedanceType.IMPEDANCE_NO_MEASURE;
  public weightType: PPScaleStateWeightType = PPScaleStateWeightType.WEIGHT_PROCESSING;
  public measureModeType: PPScaleStateMeasureModeType = PPScaleStateMeasureModeType.MEASURE_MODE;
  public captureZeroType: PPScaleStateCaptureZeroType = PPScaleStateCaptureZeroType.CAPTURE_ZERO_ING;
  public measureResultType: PPScaleStateMeasureResultType = PPScaleStateMeasureResultType.MEASURE_RESULT_PROCESSING;
  public powerType: PPScaleStatePowerType = PPScaleStatePowerType.POWER_OFF;
  public footState: PPScaleFootState = PPScaleFootState.PPScaleFootStateNotMeasured

  /**
   * 转换为字符串
   */
  public toString(): string {
    try {
      return `heartRateType: ${this.heartRateType.toString()}
impedanceType: ${this.impedanceType.toString()}
weightType: ${this.weightType.toString()}
measureModeType: ${this.measureModeType.toString()}
captureZeroType: ${this.captureZeroType.toString()}
measureType: ${this.measureResultType.toString()}
powerType: ${this.powerType.toString()}`;
    } catch (e) {
      return "";
    }
  }
}

export enum PPScaleFootState {
  PPScaleFootStateNotMeasured, // 脚长未测量
  PPScaleFootStatePrepare, // 脚长准备中
  PPScaleFootStateMeasuring, // 脚长测量中
  PPScaleFootStateMeasurementSuccessful, // 脚长测量成功
  PPScaleFootStateMeasurementFailed, // 脚长测量失败

}

/**
 * 心率测量状态枚举
 */
export class PPScaleStateHeartRateType {
  public static readonly HEARTRATE_NO_MEASURE = new PPScaleStateHeartRateType(0);
  public static readonly HEARTRATE_MEASURING = new PPScaleStateHeartRateType(1);
  public static readonly HEARTRATE_SUCCESS = new PPScaleStateHeartRateType(2);
  public static readonly HEARTRATE_FAIL = new PPScaleStateHeartRateType(3);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "HEARTRATE_NO_MEASURE";
      case 1:
        return "HEARTRATE_MEASURING";
      case 2:
        return "HEARTRATE_SUCCESS";
      case 3:
        return "HEARTRATE_FAIL";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 阻抗测量状态枚举
 */
export class PPScaleStateImpedanceType {
  public static readonly IMPEDANCE_NO_MEASURE = new PPScaleStateImpedanceType(0);
  public static readonly IMPEDANCE_MEASURING = new PPScaleStateImpedanceType(1);
  public static readonly IMPEDANCE_SUCCESS = new PPScaleStateImpedanceType(2);
  public static readonly IMPEDANCE_FAIL = new PPScaleStateImpedanceType(3);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "IMPEDANCE_NO_MEASURE";
      case 1:
        return "IMPEDANCE_MEASURING";
      case 2:
        return "IMPEDANCE_SUCCESS";
      case 3:
        return "IMPEDANCE_FAIL";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 重量状态枚举
 */
export class PPScaleStateWeightType {
  public static readonly WEIGHT_PROCESSING = new PPScaleStateWeightType(0);
  public static readonly WEIGHT_LOCK = new PPScaleStateWeightType(1);
  public static readonly WEIGHT_OVERWEIGHT = new PPScaleStateWeightType(2);
  public static readonly WEIGHT_LEAVE_SCALE = new PPScaleStateWeightType(3);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "WEIGHT_PROCESSING";
      case 1:
        return "WEIGHT_LOCK";
      case 2:
        return "WEIGHT_OVERWEIGHT";
      case 3:
        return "WEIGHT_LEAVE_SCALE";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 测量模式枚举
 */
export class PPScaleStateMeasureModeType {
  public static readonly MEASURE_MODE = new PPScaleStateMeasureModeType(0);
  public static readonly CALIBRATION_MODE = new PPScaleStateMeasureModeType(1);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "MEASURE_MODE";
      case 1:
        return "CALIBRATION_MODE";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 抓零状态枚举
 */
export class PPScaleStateCaptureZeroType {
  public static readonly CAPTURE_ZERO_ING = new PPScaleStateCaptureZeroType(0);
  public static readonly CAPTURE_ZERO_SUCCESS = new PPScaleStateCaptureZeroType(1);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "CAPTURE_ZERO_ING";
      case 1:
        return "CAPTURE_ZERO_SUCCESS";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 测量结果枚举
 */
export class PPScaleStateMeasureResultType {
  public static readonly MEASURE_RESULT_PROCESSING = new PPScaleStateMeasureResultType(0);
  public static readonly MEASURE_RESULT_FINISH = new PPScaleStateMeasureResultType(1);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "MEASURE_RESULT_PROCESSING";
      case 1:
        return "MEASURE_RESULT_FINISH";
      default:
        return "UNKNOWN";
    }
  }
}

/**
 * 电源状态枚举
 */
export class PPScaleStatePowerType {
  public static readonly POWER_ON = new PPScaleStatePowerType(0);
  public static readonly POWER_OFF = new PPScaleStatePowerType(1);
  private readonly _type: number;

  private constructor(type: number) {
    this._type = type;
  }

  public get type(): number {
    return this._type;
  }

  public toString(): string {
    switch (this._type) {
      case 0:
        return "POWER_ON";
      case 1:
        return "POWER_OFF";
      default:
        return "UNKNOWN";
    }
  }
}