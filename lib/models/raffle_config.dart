import 'package:flutter/material.dart';
import 'raffle_result.dart';
import 'raffle_item.dart';

/// 抽奖配置类
/// 用于配置抽奖组件的各种参数，包括样式、动画、交互等

/// 抽奖配置数据模型
class RaffleConfig {
  /// 抽奖类型
  final RaffleType type;
  
  /// 动画持续时间（毫秒）
  final int animationDuration;
  
  /// 是否启用音效
  final bool enableSound;
  
  /// 是否启用震动
  final bool enableVibration;
  
  /// 主题颜色
  final Color primaryColor;
  
  /// 背景颜色
  final Color backgroundColor;
  
  /// 文字颜色
  final Color textColor;
  
  /// 边框颜色
  final Color borderColor;
  
  /// 高亮颜色
  final Color highlightColor;
  
  /// 次要颜色
  final Color secondaryColor;
  
  /// 字体大小
  final double fontSize;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 圆角半径
  final double borderRadius;
  
  /// 内边距
  final EdgeInsets padding;
  
  /// 外边距
  final EdgeInsets margin;
  
  /// 抽奖项目列表
  final List<RaffleItem> items;
  
  /// 自定义样式数据
  final Map<String, dynamic>? customStyle;
  
  /// 抽奖完成回调函数
  final Function(RaffleResult)? onRaffleComplete;
  
  /// 是否在结果出现时播放音效
  final bool playSoundOnResult;
  
  /// 结果音效路径
  final String resultSoundPath;
  
  /// 是否在结果出现时震动
  final bool vibrateOnResult;

  const RaffleConfig({
    required this.type,
    this.animationDuration = 3000,
    this.enableSound = true,
    this.enableVibration = true,
    this.primaryColor = Colors.blue,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.borderColor = Colors.grey,
    this.highlightColor = Colors.amber,
    this.secondaryColor = Colors.grey,
    this.fontSize = 16.0,
    this.borderWidth = 2.0,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(8.0),
    required this.items,
    this.customStyle,
    this.onRaffleComplete,
    this.playSoundOnResult = true,
    this.resultSoundPath = 'assets/sounds/result.mp3',
    this.vibrateOnResult = true,
  });

  /// 创建九宫格抽奖配置
  /// 
  /// 九宫格是一种经典的抽奖形式，通常由3x3的格子组成，光标在格子间跑动
  /// 最终停在某一格上，该格子对应的奖品即为中奖结果
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param highlightColor 高亮颜色
  /// @param customStyle 自定义样式数据
  /// @return 九宫格抽奖配置实例
  factory RaffleConfig.grid({
    int animationDuration = 3000,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.blue,
    Color backgroundColor = Colors.white,
    Color highlightColor = Colors.amber,
    Color secondaryColor = Colors.grey,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
    Function(RaffleResult)? onRaffleComplete,
    bool playSoundOnResult = true,
    String resultSoundPath = 'assets/sounds/result.mp3',
    bool vibrateOnResult = true,
  }) {
    return RaffleConfig(
      type: RaffleType.grid,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      highlightColor: highlightColor,
      secondaryColor: secondaryColor,
      items: items,
      customStyle: customStyle,
      onRaffleComplete: onRaffleComplete,
      playSoundOnResult: playSoundOnResult,
      resultSoundPath: resultSoundPath,
      vibrateOnResult: vibrateOnResult,
    );
  }

  /// 创建大转盘抽奖配置
  /// 
  /// 大转盘是一种常见的抽奖形式，通常由一个圆形转盘和一个指针组成
  /// 转盘旋转后停止，指针指向的扇区对应的奖品即为中奖结果
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param customStyle 自定义样式数据
  /// @return 大转盘抽奖配置实例
  factory RaffleConfig.wheel({
    int animationDuration = 4000,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.red,
    Color backgroundColor = Colors.white,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
    Function(RaffleResult)? onRaffleComplete,
    bool playSoundOnResult = true,
    String resultSoundPath = 'assets/sounds/result.mp3',
    bool vibrateOnResult = true,
  }) {
    return RaffleConfig(
      type: RaffleType.wheel,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      items: items,
      customStyle: customStyle,
      onRaffleComplete: onRaffleComplete,
      playSoundOnResult: playSoundOnResult,
      resultSoundPath: resultSoundPath,
      vibrateOnResult: vibrateOnResult,
    );
  }

  /// 创建数字滚动抽奖配置
  /// 
  /// 数字滚动抽奖类似老虎机，多个数字或图案在垂直方向上滚动
  /// 最终停止后显示的组合即为中奖结果
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param textColor 文字颜色
  /// @param customStyle 自定义样式数据
  /// @return 数字滚动抽奖配置实例
  factory RaffleConfig.slot({
    int animationDuration = 2500,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.green,
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: RaffleType.slot,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      textColor: textColor,
      items: items,
      customStyle: customStyle,
    );
  }

  /// 创建刮刮卡配置
  /// 
  /// 刮刮卡是一种互动性强的抽奖形式，用户通过手势刮开涂层
  /// 露出下面的奖品信息
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param customStyle 自定义样式数据
  /// @return 刮刮卡抽奖配置实例
  factory RaffleConfig.scratch({
    int animationDuration = 1000,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.orange,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: RaffleType.scratch,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      items: items,
      customStyle: customStyle,
    );
  }

  /// 创建卡片翻转抽奖配置
  /// 
  /// 卡片翻转是一种互动性强的抽奖形式，用户通过点击卡片使其翻转
  /// 翻转后显示的奖品即为中奖结果
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param customStyle 自定义样式数据
  /// @return 卡片翻转抽奖配置实例
  factory RaffleConfig.cardFlip({
    int animationDuration = 1500,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.purple,
    Color backgroundColor = Colors.white,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: RaffleType.cardFlip,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      items: items,
      customStyle: customStyle,
    );
  }

  /// 创建扭蛋机抽奖配置
  /// 
  /// 扭蛋机是一种模拟现实扭蛋机的抽奖形式，用户通过旋转或按下按钮
  /// 获得一个随机的扭蛋，打开后显示奖品
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param customStyle 自定义样式数据
  /// @return 扭蛋机抽奖配置实例
  factory RaffleConfig.gashapon({
    int animationDuration = 3500,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.blue,
    Color backgroundColor = Colors.white,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: RaffleType.gashapon,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      items: items,
      customStyle: customStyle,
    );
  }

  /// 创建砸金蛋抽奖配置
  /// 
  /// 砸金蛋是一种互动性强的抽奖形式，用户通过点击或敲击金蛋
  /// 使其破碎，显示内部的奖品
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param customStyle 自定义样式数据
  /// @return 砸金蛋抽奖配置实例
  factory RaffleConfig.goldenEgg({
    int animationDuration = 2000,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.amber,
    Color backgroundColor = Colors.white,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: RaffleType.goldenEgg,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      items: items,
      backgroundColor: backgroundColor,
      customStyle: customStyle,
    );
  }

  /// 创建幸运卡片抽奖配置
  /// 
  /// 幸运卡片是一种互动性强的抽奖形式，用户通过选择和展开卡片
  /// 查看卡片内的奖品
  /// 
  /// @param animationDuration 动画持续时间（毫秒）
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param customStyle 自定义样式数据
  /// @return 幸运卡片抽奖配置实例
  factory RaffleConfig.luckyCard({
    int animationDuration = 1800,
    bool enableSound = true,
    bool enableVibration = true,
    Color primaryColor = Colors.teal,
    Color backgroundColor = Colors.white,
    List<RaffleItem> items = const [],
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: RaffleType.luckyCard,
      animationDuration: animationDuration,
      enableSound: enableSound,
      enableVibration: enableVibration,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      items: items,
      customStyle: customStyle,
    );
  }

  /// 复制配置并修改部分属性
  /// 
  /// 此方法用于创建当前配置的副本，并可选择性地修改某些属性
  /// 未指定的属性将保持原值不变
  /// 
  /// @param type 抽奖类型
  /// @param animationDuration 动画持续时间
  /// @param enableSound 是否启用音效
  /// @param enableVibration 是否启用震动
  /// @param primaryColor 主题颜色
  /// @param backgroundColor 背景颜色
  /// @param textColor 文字颜色
  /// @param borderColor 边框颜色
  /// @param highlightColor 高亮颜色
  /// @param fontSize 字体大小
  /// @param borderWidth 边框宽度
  /// @param borderRadius 圆角半径
  /// @param padding 内边距
  /// @param margin 外边距
  /// @param customStyle 自定义样式数据
  /// @return 修改后的新配置实例
  RaffleConfig copyWith({
    RaffleType? type,
    int? animationDuration,
    bool? enableSound,
    bool? enableVibration,
    Color? primaryColor,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    Color? highlightColor,
    double? fontSize,
    double? borderWidth,
    double? borderRadius,
    EdgeInsets? padding,
    EdgeInsets? margin,
    List<RaffleItem>? items,
    Map<String, dynamic>? customStyle,
  }) {
    return RaffleConfig(
      type: type ?? this.type,
      animationDuration: animationDuration ?? this.animationDuration,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      highlightColor: highlightColor ?? this.highlightColor,
      fontSize: fontSize ?? this.fontSize,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      margin: margin ?? this.margin,
      items: items ?? this.items,
      customStyle: customStyle ?? this.customStyle,
    );
  }
}