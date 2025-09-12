// 抽奖结果模型类
// 定义抽奖类型和结果数据结构

import 'raffle_item.dart';

/// 抽奖类型枚举
/// 定义支持的各种抽奖形式
enum RaffleType {
  /// 九宫格抽奖
  grid,
  
  /// 大转盘抽奖
  wheel,
  
  /// 数字滚动抽奖（老虎机）
  slot,
  
  /// 刮刮卡抽奖
  scratch,
  
  /// 卡片翻转抽奖
  flip,
  cardFlip,
  
  /// 扭蛋机抽奖
  gashapon,
  
  /// 砸金蛋抽奖
  egg,
  goldenEgg,
  
  /// 幸运卡片抽奖
  card,
  luckyCard
}

/// 抽奖结果类
/// 包含抽奖的完整结果信息
class RaffleResult {
  /// 抽奖类型
  final RaffleType type;
  
  /// 中奖项目
  final RaffleItem prize;
  
  /// 抽奖时间戳
  final int timestamp;
  
  /// 抽奖唯一ID
  final String id;
  
  /// 获取中奖项目（兼容性方法）
  RaffleItem get item => prize;
  
  /// 中奖项目在抽奖列表中的索引
  final int? index;
  
  /// 额外数据，可用于存储特定抽奖类型的附加信息
  final Map<String, dynamic>? extraData;
  
  /// 构造函数
  RaffleResult({
    required this.type,
    required this.prize,
    required this.timestamp,
    required this.id,
    this.index,
    this.extraData,
  });
  
  /// 从JSON创建抽奖结果对象
  factory RaffleResult.fromJson(Map<String, dynamic> json) {
    return RaffleResult(
      type: RaffleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RaffleType.grid,
      ),
      prize: RaffleItem.fromJson(json['prize']),
      timestamp: json['timestamp'] as int,
      id: json['id'] as String,
      index: json['index'] as int?,
      extraData: json['extraData'] != null
          ? Map<String, dynamic>.from(json['extraData'])
          : null,
    );
  }
  
  /// 将抽奖结果转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'prize': prize.toJson(),
      'timestamp': timestamp,
      'id': id,
      if (index != null) 'index': index,
      if (extraData != null) 'extraData': extraData,
    };
  }
}