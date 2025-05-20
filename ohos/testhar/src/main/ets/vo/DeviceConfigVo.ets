interface BrandJson {
  brandName: string;
  brandLogo: string;
}

export interface DeviceConfigVoJson {
  createTime?: string;
  updateTime?: string;
  id?: number;
  deviceName?: string;
  sign?: string;
  advLength?: number;
  macAddressStart?: number;
  calorieStatus?: number;
  deviceConnectType?: number;
  deviceType?: number;
  deviceProtocolType?: number;
  deviceCalcuteType?: number;
  devicePowerType?: number;
  deviceFuncType?: number;
  deviceAccuracyType?: number;
  deviceUnitType?: string;
  customDeviceName?: string;
  imgUrl?: string;
  brandId?: number;
  brand?: BrandJson;
  productModel?: string;
  standardType?: number;
  avatarType?: number;
}

export class Brand {
  brandName?: string;
  brandLogo?: string;

  constructor(brandName: string, brandLogo: string) {
    this.brandName = brandName;
    this.brandLogo = brandLogo;
  }

  static fromJson(json: BrandJson): Brand {
    return new Brand(json.brandName, json.brandLogo);
  }

  toJson(): BrandJson {
    return {
      brandName: this.brandName || "",
      brandLogo: this.brandLogo || ""
    };
  }
}

export class DeviceConfigVo {
  createTime?: string;
  updateTime?: string;
  id?: number;
  deviceName?: string;
  sign?: string;
  advLength?: number;
  macAddressStart?: number;
  calorieStatus?: number;
  deviceConnectType?: number;
  deviceType?: number;
  deviceProtocolType?: number;
  deviceCalcuteType?: number;
  devicePowerType?: number;
  deviceFuncType?: number;
  deviceAccuracyType?: number;
  deviceUnitType?: string;
  customDeviceName?: string;
  imgUrl?: string;
  brandId?: number;
  brand?: Brand;
  productModel?: string;
  standardType?: number;
  avatarType?: number;

  static fromJson(json: DeviceConfigVoJson): DeviceConfigVo {
    const deviceConfigVo = new DeviceConfigVo();
    deviceConfigVo.createTime = json.createTime;
    deviceConfigVo.updateTime = json.updateTime;
    deviceConfigVo.id = json.id;
    deviceConfigVo.deviceName = json.deviceName;
    deviceConfigVo.sign = json.sign;
    deviceConfigVo.advLength = json.advLength;
    deviceConfigVo.macAddressStart = json.macAddressStart;
    deviceConfigVo.calorieStatus = json.calorieStatus;
    deviceConfigVo.deviceConnectType = json.deviceConnectType;
    deviceConfigVo.deviceType = json.deviceType;
    deviceConfigVo.deviceProtocolType = json.deviceProtocolType;
    deviceConfigVo.deviceCalcuteType = json.deviceCalcuteType;
    deviceConfigVo.devicePowerType = json.devicePowerType;
    deviceConfigVo.deviceFuncType = json.deviceFuncType;
    deviceConfigVo.deviceAccuracyType = json.deviceAccuracyType;
    deviceConfigVo.deviceUnitType = json.deviceUnitType;
    deviceConfigVo.customDeviceName = json.customDeviceName;
    deviceConfigVo.imgUrl = json.imgUrl;
    deviceConfigVo.brandId = json.brandId;
    deviceConfigVo.brand = json.brand ? Brand.fromJson(json.brand) : undefined;
    deviceConfigVo.productModel = json.productModel;
    deviceConfigVo.standardType = json.standardType;
    deviceConfigVo.avatarType = json.avatarType;
    return deviceConfigVo;
  }

  toJson(): DeviceConfigVoJson {
    return {
      createTime: this.createTime,
      updateTime: this.updateTime,
      id: this.id,
      deviceName: this.deviceName,
      sign: this.sign,
      advLength: this.advLength,
      macAddressStart: this.macAddressStart,
      calorieStatus: this.calorieStatus,
      deviceConnectType: this.deviceConnectType,
      deviceType: this.deviceType,
      deviceProtocolType: this.deviceProtocolType,
      deviceCalcuteType: this.deviceCalcuteType,
      devicePowerType: this.devicePowerType,
      deviceFuncType: this.deviceFuncType,
      deviceAccuracyType: this.deviceAccuracyType,
      deviceUnitType: this.deviceUnitType,
      customDeviceName: this.customDeviceName,
      imgUrl: this.imgUrl,
      brandId: this.brandId,
      brand: this.brand ? this.brand.toJson() : undefined,
      productModel: this.productModel,
      standardType: this.standardType,
      avatarType: this.avatarType
    };
  }
}
