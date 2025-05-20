import { PPDeviceCalculateType, PPDeviceConnectType, PPDevicePeripheralType, PPDeviceProtocolType, PPDeviceType } from "../enums/PPDeviceEnums";

// Brand接口定义
interface BrandJson {
  brandName: string;
  brandLogo: string;
}

// PPDeviceModel的JSON接口定义
interface PPDeviceModelJson {
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
  deviceCalculateType?: number;
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
  deviceMac?: string;
  deviceRemoteId?: string;
  devicePower?: number;
  rssi?: number;
  firmwareVersion?: string;
  hardwareVersion?: string;
  manufacturerName?: string;
  softwareVersion?: string;
  serialNumber?: string;
  modelNumber?: string;
  calculateVersion?: string;
  mtu?: number;
  illumination?: number;
  deviceSettingId?: number;
}

// Brand类实现
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

// PPDeviceModel类实现
export class PPDeviceModel {
  // 基础字段
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
  deviceCalculateType?: number;
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
  // 设备特有字段
  deviceMac?: string;
  deviceRemoteId?: string;
  devicePower?: number;
  rssi?: number;
  firmwareVersion?: string;
  hardwareVersion?: string;
  manufacturerName?: string;
  softwareVersion?: string;
  serialNumber?: string;
  modelNumber?: string;
  calculateVersion?: string;
  mtu?: number;
  illumination?: number;
  deviceSettingId?: number;

  constructor(deviceName: string, deviceMac: string) {
    this.deviceName = deviceName;
    this.deviceMac = deviceMac;
  }

  getDevicePeripheralType(): PPDevicePeripheralType {
    if (this.deviceConnectType == PPDeviceConnectType.PPDeviceConnectTypeLte) {
      return PPDevicePeripheralType.PeripheralKiwifruit;
    } else if (this.deviceConnectType == PPDeviceConnectType.PPDeviceConnectTypeDirect) {
      if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV2) {
        if (this.deviceType == PPDeviceType.PPDeviceTypeCA) {
          return PPDevicePeripheralType.PeripheralEgg;
        } else if (this.deviceCalculateType == PPDeviceCalculateType.PPDeviceCalculateTypeInScale) {
          return PPDevicePeripheralType.PeripheralDurian;
        } else {
          return PPDevicePeripheralType.PeripheralApple;
        }
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV3) {
        if (this.deviceType == PPDeviceType.PPDeviceTypeCA) {
          return PPDevicePeripheralType.PeripheralFish;
        } else {
          return PPDevicePeripheralType.PeripheralCoconut;
        }
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV4) {
        return PPDevicePeripheralType.PeripheralIce;
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeTorre) {
        return PPDevicePeripheralType.PeripheralTorre;
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeBorre) {
        return PPDevicePeripheralType.PeripheralBorre;
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeDorre) {
        return PPDevicePeripheralType.PeripheralDorre;
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeForre) {
        return PPDevicePeripheralType.PeripheralForre;
      }
    } else {
      if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV2) {
        if (this.deviceType == PPDeviceType.PPDeviceTypeCA) {
          return PPDevicePeripheralType.PeripheralGrapes;
        } else {
          return PPDevicePeripheralType.PeripheralBanana;
        }
      } else if (this.deviceProtocolType == PPDeviceProtocolType.PPDeviceProtocolTypeV3) {
        if (this.deviceType == PPDeviceType.PPDeviceTypeCA) {
          return PPDevicePeripheralType.PeripheralHamburger;
        } else {
          return PPDevicePeripheralType.PeripheralJambul;
        }
      }
    }
    return PPDevicePeripheralType.PeripheralApple;
  }

  static fromJson(json: PPDeviceModelJson): PPDeviceModel {
    const model = new PPDeviceModel(json.deviceName || "", json.deviceMac || "");

    // 基础字段赋值
    model.createTime = json.createTime;
    model.updateTime = json.updateTime;
    model.id = json.id;
    model.sign = json.sign;
    model.advLength = json.advLength;
    model.macAddressStart = json.macAddressStart;
    model.calorieStatus = json.calorieStatus;
    model.deviceConnectType = json.deviceConnectType;
    model.deviceType = json.deviceType;
    model.deviceProtocolType = json.deviceProtocolType;
    model.deviceCalculateType = json.deviceCalculateType;
    model.devicePowerType = json.devicePowerType;
    model.deviceFuncType = json.deviceFuncType;
    model.deviceAccuracyType = json.deviceAccuracyType;
    model.deviceUnitType = json.deviceUnitType;
    model.customDeviceName = json.customDeviceName;
    model.imgUrl = json.imgUrl;
    model.brandId = json.brandId;
    model.brand = json.brand ? Brand.fromJson(json.brand) : undefined;
    model.productModel = json.productModel;
    model.standardType = json.standardType;
    model.avatarType = json.avatarType;

    // 设备特有字段赋值
    model.deviceRemoteId = json.deviceRemoteId;
    model.devicePower = json.devicePower;
    model.rssi = json.rssi;
    model.firmwareVersion = json.firmwareVersion;
    model.hardwareVersion = json.hardwareVersion;
    model.manufacturerName = json.manufacturerName;
    model.softwareVersion = json.softwareVersion;
    model.serialNumber = json.serialNumber;
    model.modelNumber = json.modelNumber;
    model.calculateVersion = json.calculateVersion;
    model.mtu = json.mtu;
    model.illumination = json.illumination;
    model.deviceSettingId = json.deviceSettingId;

    return model;
  }

  toJson(): PPDeviceModelJson {
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
      deviceCalculateType: this.deviceCalculateType,
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
      avatarType: this.avatarType,
      deviceMac: this.deviceMac,
      deviceRemoteId: this.deviceRemoteId,
      devicePower: this.devicePower,
      rssi: this.rssi,
      firmwareVersion: this.firmwareVersion,
      hardwareVersion: this.hardwareVersion,
      manufacturerName: this.manufacturerName,
      softwareVersion: this.softwareVersion,
      serialNumber: this.serialNumber,
      modelNumber: this.modelNumber,
      calculateVersion: this.calculateVersion,
      mtu: this.mtu,
      illumination: this.illumination,
      deviceSettingId: this.deviceSettingId
    };
  }
}
