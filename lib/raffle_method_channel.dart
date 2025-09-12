// 导入必要的包
import 'package:flutter/foundation.dart'; // 提供@visibleForTesting注解
import 'package:flutter/services.dart'; // 提供MethodChannel类

// 导入平台接口和模型
import 'raffle_platform_interface.dart'; // 抽奖平台接口
import 'models/raffle_result.dart'; // 抽奖结果模型及类型定义

/// 使用方法通道实现的抽奖平台接口
/// 通过MethodChannel与原生平台代码通信
/// 实现了RafflePlatform定义的所有方法
class MethodChannelRaffle extends RafflePlatform {
  /// 用于与原生平台交互的方法通道
  /// 通道名称为'raffle'，与原生端保持一致
  /// @visibleForTesting注解允许测试代码访问此字段
  @visibleForTesting
  final methodChannel = const MethodChannel('raffle');

  /// 获取平台版本信息
  /// 通过方法通道调用原生方法'getPlatformVersion'
  /// 返回当前运行平台的版本字符串
  @override
  Future<String?> getPlatformVersion() async {
    // 调用原生方法并获取返回值
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
  
  /// 播放抽奖音效
  /// 通过方法通道调用原生方法'playRaffleSound'
  /// @param type 抽奖类型，不同类型播放不同音效
  @override
  Future<void> playRaffleSound(RaffleType type) async {
    // 调用原生方法并传递抽奖类型参数
    await methodChannel.invokeMethod('playRaffleSound', {
      'type': type.name, // 将枚举转换为字符串名称
    });
  }
  
  /// 触发震动反馈
  /// 通过方法通道调用原生方法'triggerVibration'
  /// @param duration 震动持续时间（毫秒）
  @override
  Future<void> triggerVibration(int duration) async {
    // 调用原生方法并传递震动持续时间参数
    await methodChannel.invokeMethod('triggerVibration', {
      'duration': duration, // 震动持续时间（毫秒）
    });
  }
  
  /// 保存抽奖结果到本地存储
  /// 通过方法通道调用原生方法'saveRaffleResult'
  /// @param result 抽奖结果的JSON数据
  @override
  Future<void> saveRaffleResult(Map<String, dynamic> result) async {
    // 调用原生方法并传递抽奖结果JSON数据
    await methodChannel.invokeMethod('saveRaffleResult', result);
  }
  
  /// 获取抽奖历史记录
  /// 通过方法通道调用原生方法'getRaffleHistory'
  /// 返回所有保存的抽奖结果JSON数据列表
  @override
  Future<List<Map<String, dynamic>>> getRaffleHistory() async {
    // 调用原生方法获取历史数据
    final result = await methodChannel.invokeMethod<List>('getRaffleHistory');
    // 将结果转换为正确的类型，如果为空则返回空列表
    return result?.cast<Map<String, dynamic>>() ?? [];
  }
}
