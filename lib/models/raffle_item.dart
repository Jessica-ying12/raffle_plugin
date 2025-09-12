/// 抽奖项目数据模型
/// 
/// 表示抽奖活动中的一个奖品项目，包含奖品的基本信息、权重和类型等
/// 用于在抽奖过程中展示奖品信息，并根据权重计算中奖概率
class RaffleItem {
  /// 奖品ID
  final String id;
  
  /// 奖品名称
  final String name;
  
  /// 奖品描述
  final String? description;
  
  /// 奖品图片URL
  final String? imageUrl;
  
  /// 奖品权重（用于概率计算）
  final int weight;
  
  /// 奖品类型
  final RaffleItemType type;
  
  /// 奖品价值
  final double? value;
  
  /// 是否为特等奖
  final bool isSpecial;
  
  /// 自定义数据
  final Map<String, dynamic>? customData;

  const RaffleItem({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.weight,
    this.type = RaffleItemType.normal,
    this.value,
    this.isSpecial = false,
    this.customData,
  });
  
  /// 获取奖品概率
  /// 返回基于权重的概率值
  double get probability => weight / 100.0;
  
  /// 创建当前对象的副本并修改部分属性
  /// 
  /// 用于在不改变原对象的情况下创建新的对象实例
  /// 
  /// @param id 新的奖品ID
  /// @param name 新的奖品名称
  /// @param description 新的奖品描述
  /// @param imageUrl 新的奖品图片URL
  /// @param weight 新的奖品权重
  /// @param probability 新的奖品概率（会转换为权重）
  /// @param type 新的奖品类型
  /// @param value 新的奖品价值
  /// @param isSpecial 是否为特等奖
  /// @param customData 新的自定义数据
  /// @return 修改后的新RaffleItem对象
  RaffleItem copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? weight,
    double? probability,
    RaffleItemType? type,
    double? value,
    bool? isSpecial,
    Map<String, dynamic>? customData,
  }) {
    return RaffleItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      weight: probability != null ? (probability * 100).round() : (weight ?? this.weight),
      type: type ?? this.type,
      value: value ?? this.value,
      isSpecial: isSpecial ?? this.isSpecial,
      customData: customData ?? this.customData,
    );
  }

  /// 从JSON创建RaffleItem
  /// 
  /// 将JSON格式的数据转换为RaffleItem对象
  /// 用于从存储或API中恢复奖品数据
  /// 
  /// @param json 包含奖品数据的JSON对象
  /// @return 根据JSON数据创建的RaffleItem实例
  factory RaffleItem.fromJson(Map<String, dynamic> json) {
    return RaffleItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      weight: json['weight'] as int,
      type: RaffleItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RaffleItemType.normal,
      ),
      value: json['value']?.toDouble(),
      isSpecial: json['isSpecial'] as bool? ?? false,
      customData: json['customData'] as Map<String, dynamic>?,
    );
  }

  /// 转换为JSON
  /// 
  /// 将RaffleItem对象转换为JSON格式，用于存储或传输
  /// 
  /// @return 包含奖品数据的JSON对象
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'weight': weight,
      'type': type.name,
      'value': value,
      'isSpecial': isSpecial,
      'customData': customData,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RaffleItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // 已移除重复的probability getter

  @override
  String toString() {
    return 'RaffleItem(id: $id, name: $name, weight: $weight)';
  }
}

/// 奖品类型枚举
enum RaffleItemType {
  /// 普通奖品
  normal,
  /// 特等奖
  grand,
  /// 一等奖
  first,
  /// 二等奖
  second,
  /// 三等奖
  third,
  /// 安慰奖
  consolation,
  /// 谢谢参与
  thanks,
}