
// 抽奖插件主文件

// 导入必要的包和模型
import 'package:raffle/models/raffle_result.dart'; // 抽奖结果模型

// 导入平台接口
import 'raffle_platform_interface.dart';

// 导出所有公共API，使外部可以直接使用这些组件和模型
// 模型导出
export 'models/raffle_item.dart'; // 抽奖项目模型
export 'models/raffle_result.dart'; // 抽奖结果模型
export 'models/raffle_config.dart'; // 抽奖配置模型

// 控制器基类导出
export 'controllers/raffle_controller.dart'; // 抽奖控制器基类

// 抽奖组件导出
export 'widgets/grid_raffle_widget.dart'; // 网格抽奖组件
export 'widgets/wheel_raffle_widget.dart'; // 转盘抽奖组件
export 'widgets/slot_raffle_widget.dart'; // 老虎机抽奖组件
export 'widgets/scratch_raffle_widget.dart'; // 刮刮卡抽奖组件
export 'widgets/card_flip_raffle_widget.dart'; // 翻牌抽奖组件
export 'widgets/gashapon_raffle_widget.dart'; // 扭蛋机抽奖组件
export 'widgets/golden_egg_raffle_widget.dart'; // 金蛋抽奖组件
export 'widgets/lucky_card_raffle_widget.dart'; // 幸运卡片抽奖组件

// 导出各种抽奖控制器实现类
export 'controllers/grid_raffle_controller.dart'; // 网格抽奖控制器
export 'controllers/wheel_raffle_controller.dart'; // 转盘抽奖控制器
export 'controllers/slot_raffle_controller.dart'; // 老虎机抽奖控制器
export 'controllers/scratch_raffle_controller.dart'; // 刮刮卡抽奖控制器
export 'controllers/card_flip_raffle_controller.dart'; // 翻牌抽奖控制器
export 'controllers/gashapon_raffle_controller.dart'; // 扭蛋机抽奖控制器
export 'controllers/golden_egg_raffle_controller.dart'; // 金蛋抽奖控制器
export 'controllers/lucky_card_raffle_controller.dart'; // 幸运卡片抽奖控制器

/// 抽奖插件主类，提供与平台交互的方法
/// 使用单例模式确保全局只有一个实例
class Raffle {
  // 私有静态实例，用于单例模式
  static final Raffle _instance = Raffle._internal();
  // 工厂构造函数，返回单例实例
  factory Raffle() => _instance;
  // 私有构造函数，防止外部直接创建实例
  Raffle._internal();
  
  /// 获取平台版本信息
  /// 返回当前运行平台的版本字符串
  /// 主要用于测试平台集成是否正常
  Future<String?> getPlatformVersion() {
    return RafflePlatform.instance.getPlatformVersion();
  }
  
  /// 播放抽奖音效
  /// @param type 抽奖类型，不同类型播放不同音效
  /// 通过平台通道调用原生音效播放功能
  Future<void> playRaffleSound(RaffleType type) {
    return RafflePlatform.instance.playRaffleSound(type);
  }
  
  /// 触发震动反馈
  /// @param duration 震动持续时间（毫秒）
  /// 通过平台通道调用原生震动功能，增强用户体验
  Future<void> triggerVibration(int duration) {
    return RafflePlatform.instance.triggerVibration(duration);
  }
  
  /// 保存抽奖结果到本地存储
  /// @param result 抽奖结果对象
  /// 将抽奖结果转换为JSON并通过平台通道保存
  Future<void> saveRaffleResult(RaffleResult result) {
    return RafflePlatform.instance.saveRaffleResult(result.toJson());
  }
  
  /// 获取抽奖历史记录
  /// 返回所有保存的抽奖结果列表
  /// 从平台获取JSON数据并转换为RaffleResult对象列表
  Future<List<RaffleResult>> getRaffleHistory() async {
    // 通过平台通道获取历史数据
    final historyData = await RafflePlatform.instance.getRaffleHistory();
    // 将JSON数据转换为RaffleResult对象列表
    return historyData.map((data) => RaffleResult.fromJson(data)).toList();
  }
}
