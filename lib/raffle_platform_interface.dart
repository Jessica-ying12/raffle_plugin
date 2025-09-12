// 导入必要的包
import 'package:plugin_platform_interface/plugin_platform_interface.dart'; // Flutter平台接口基类

// 导入方法通道实现和模型
import 'raffle_method_channel.dart'; // 方法通道实现
import 'models/raffle_result.dart'; // 抽奖结果模型及类型定义

/// 抽奖平台接口抽象类
/// 定义与原生平台交互的方法接口
/// 所有平台特定实现都应继承此类
abstract class RafflePlatform extends PlatformInterface {
  /// 构造函数
  /// 调用父类构造函数并传入验证令牌
  RafflePlatform() : super(token: _token);

  /// 验证令牌，用于确保平台实例的合法性
  /// 防止未经验证的实现被注册为平台实例
  static final Object _token = Object();

  /// 平台接口的默认实例
  /// 初始化为方法通道实现
  static RafflePlatform _instance = MethodChannelRaffle();

  /// 获取平台接口实例的getter
  /// 默认返回MethodChannelRaffle实例
  /// 用于访问平台特定功能
  static RafflePlatform get instance => _instance;

  /// 设置平台接口实例的setter
  /// 平台特定实现在注册自己时应使用此方法
  /// @param instance 平台特定的实现类实例
  static set instance(RafflePlatform instance) {
    // 验证实例的令牌，确保是合法的平台实现
    PlatformInterface.verifyToken(instance, _token);
    // 设置为新的实例
    _instance = instance;
  }

  /// 获取平台版本信息
  /// 子类必须实现此方法
  /// 返回当前运行平台的版本字符串
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
  
  /// 播放抽奖音效
  /// 子类必须实现此方法
  /// @param type 抽奖类型，不同类型播放不同音效
  Future<void> playRaffleSound(RaffleType type) {
    throw UnimplementedError('playRaffleSound() has not been implemented.');
  }
  
  /// 触发震动反馈
  /// 子类必须实现此方法
  /// @param duration 震动持续时间（毫秒）
  Future<void> triggerVibration(int duration) {
    throw UnimplementedError('triggerVibration() has not been implemented.');
  }
  
  /// 保存抽奖结果到本地存储
  /// 子类必须实现此方法
  /// @param result 抽奖结果的JSON数据
  Future<void> saveRaffleResult(Map<String, dynamic> result) {
    throw UnimplementedError('saveRaffleResult() has not been implemented.');
  }
  
  /// 获取抽奖历史记录
  /// 子类必须实现此方法
  /// 返回所有保存的抽奖结果JSON数据列表
  Future<List<Map<String, dynamic>>> getRaffleHistory() {
    throw UnimplementedError('getRaffleHistory() has not been implemented.');
  }
}
