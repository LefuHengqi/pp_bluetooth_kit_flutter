/**
 * WiFi配置状态枚举
 * 用于描述设备配网过程中的各种状态
 */
export enum PPConfigWifiStateMenu {
  /**
   * 配网成功 Successful distribution network
   */
  CONFIG_STATE_SUCCESS,

  /**
   * 电量过低 Low battery level
   */
  CONFIG_STATE_LOW_BATTERY_LEVEL,

  /**
   * 注册失败 login has failed
   */
  CONFIG_STATE_REGIST_FAIL,

  /**
   * 获取配置失败 Failed to obtain configuration
   */
  CONFIG_STATE_GET_CONFIG_FAIL,

  /**
   * 找不到路由 Unable to find route
   */
  CONFIG_STATE_ROUTER_FAIL,

  /**
   * 密码错误 Password error
   */
  CONFIG_STATE_PASSWORD_ERR,

  /**
   * 其它错误（app可以不用关注）
   * Other errors (app can be ignored)
   */
  CONFIG_STATE_OTHER_FAIL,
  /**
   * 确认开始配网失败
   */
  CONFIG_STATE_ERROR_TYPE_START_FAIL,

  /**
   * 确认开始发送数据
   */
  CONFIG_STATE_ERROR_TYPE_DATA_SEND_FAIL,

  /**
   * 发送ssid数据失败
   */
  CONFIG_STATE_ERROR_TYPE_DATA_SEND_SSID_FAIL,

  /**
   * 发送pwd数据失败
   */
  CONFIG_STATE_ERROR_TYPE_DATA_SEND_PWD_FAIL,

  /**
   * 发送domain数据失败
   */
  CONFIG_STATE_ERROR_TYPE_DATA_SEND_DOMAIN_FAIL,

  /**
   * 超时失败
   */
  CONFIG_STATE_ERROR_TYPE_REGIST_TIMEOUT,

  /**
   * 路由器连接失败
   */
  CONFIG_STATE_ERROR_TYPE_REGIST_ROUTER,

  /**
   * HTTP网络错误
   */
  CONFIG_STATE_ERROR_TYPE_REGIST_HTTP,

  /**
   * HTTPS网络错误
   */
  CONFIG_STATE_ERROR_TYPE_REGIST_HTTPS,

  /**
   * 服务器返回失败
   */
  CONFIG_STATE_ERROR_TYPE_REGIST_SERVER,

  /**
   * 配网指令漏发导致的失败
   */
  CONFIG_STATE_ERROR_TYPE_REGIST_FAIL,

  /**
   * 用户主动退出配网
   */
  CONFIG_STATE_EXIT
}

/**
 * WiFi配置状态工具类
 */
export class PPConfigWifiStateMenuUtil {
  /**
   * 获取状态描述
   * @param state 配置状态
   * @returns 对应的描述信息
   */
  public static getDescription(state: PPConfigWifiStateMenu): string {
    switch (state) {
      case PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS:
        return '配网成功';
      case PPConfigWifiStateMenu.CONFIG_STATE_LOW_BATTERY_LEVEL:
        return '电量过低';
      case PPConfigWifiStateMenu.CONFIG_STATE_REGIST_FAIL:
        return '注册失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_GET_CONFIG_FAIL:
        return '获取配置失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ROUTER_FAIL:
        return '找不到路由';
      case PPConfigWifiStateMenu.CONFIG_STATE_PASSWORD_ERR:
        return '密码错误';
      case PPConfigWifiStateMenu.CONFIG_STATE_OTHER_FAIL:
        return '其它错误';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_START_FAIL:
        return '开始配网失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_FAIL:
        return '发送数据失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_SSID_FAIL:
        return '发送SSID失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_PWD_FAIL:
        return '发送密码失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_DOMAIN_FAIL:
        return '发送域名失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_TIMEOUT:
        return '配网超时';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_ROUTER:
        return '路由器连接失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_HTTP:
        return 'HTTP网络错误';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_HTTPS:
        return 'HTTPS网络错误';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_SERVER:
        return '服务器错误';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_FAIL:
        return '配网指令失败';
      case PPConfigWifiStateMenu.CONFIG_STATE_EXIT:
        return '用户主动退出';
      default:
        return '未知状态';
    }
  }

  /**
   * 获取英文描述
   * @param state 配置状态
   * @returns 对应的英文描述
   */
  public static getEnglishDescription(state: PPConfigWifiStateMenu): string {
    switch (state) {
      case PPConfigWifiStateMenu.CONFIG_STATE_SUCCESS:
        return 'Configuration success';
      case PPConfigWifiStateMenu.CONFIG_STATE_LOW_BATTERY_LEVEL:
        return 'Low battery level';
      case PPConfigWifiStateMenu.CONFIG_STATE_REGIST_FAIL:
        return 'Registration failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_GET_CONFIG_FAIL:
        return 'Failed to get configuration';
      case PPConfigWifiStateMenu.CONFIG_STATE_ROUTER_FAIL:
        return 'Router not found';
      case PPConfigWifiStateMenu.CONFIG_STATE_PASSWORD_ERR:
        return 'Incorrect password';
      case PPConfigWifiStateMenu.CONFIG_STATE_OTHER_FAIL:
        return 'Other error';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_START_FAIL:
        return 'Start configuration failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_FAIL:
        return 'Data send failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_SSID_FAIL:
        return 'SSID send failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_PWD_FAIL:
        return 'Password send failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_DATA_SEND_DOMAIN_FAIL:
        return 'Domain send failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_TIMEOUT:
        return 'Registration timeout';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_ROUTER:
        return 'Router connection failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_HTTP:
        return 'HTTP network error';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_HTTPS:
        return 'HTTPS network error';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_SERVER:
        return 'Server error';
      case PPConfigWifiStateMenu.CONFIG_STATE_ERROR_TYPE_REGIST_FAIL:
        return 'Configuration command failed';
      case PPConfigWifiStateMenu.CONFIG_STATE_EXIT:
        return 'User canceled';
      default:
        return 'Unknown state';
    }
  }
}