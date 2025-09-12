// 抽奖控制器基类
// 定义所有抽奖控制器的通用接口和功能

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/raffle_config.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_state.dart';
import '../raffle.dart';

/// 抽奖控制器基类
/// 所有具体抽奖类型的控制器都应继承此类
abstract class RaffleController {
  /// 抽奖完成回调函数
  final Function(RaffleResult)? onRaffleComplete;
  /// 抽奖插件实例
  final Raffle _raffle = Raffle();
  
  /// 获取抽奖插件实例（供子类使用）
  @protected
  Raffle get raffle => _raffle;
  
  /// 抽奖配置
  final RaffleConfig config;
  
  /// 抽奖项目列表
  List<RaffleItem> _items = [];
  
  /// 获取抽奖项目列表
  List<RaffleItem> get items => _items;
  
  /// 抽奖状态流控制器
  final _stateController = StreamController<RaffleState>.broadcast();
  
  /// 抽奖结果流控制器
  final _resultController = StreamController<RaffleResult>.broadcast();
  
  /// 获取结果控制器（供子类使用）
  @protected
  StreamController<RaffleResult> get resultController => _resultController;
  
  /// 抽奖状态流
  Stream<RaffleState> get stateStream => _stateController.stream;
  
  /// 抽奖结果流
  Stream<RaffleResult> get resultStream => _resultController.stream;
  
  /// 当前抽奖状态
  RaffleState _state = RaffleState.idle;
  
  /// 获取当前抽奖状态
  RaffleState get state => _state;
  
  /// 判断是否可以开始抽奖
  bool get canStart => _state == RaffleState.idle;
  
  /// 构造函数
  RaffleController({
    required this.config, 
    List<RaffleItem>? items,
    this.onRaffleComplete,
  }) {
    if (items != null) {
      _items = items;
    }
  }
  
  /// 开始抽奖
  /// 子类必须实现此方法
  Future<RaffleResult> startRaffle();
  
  /// 停止抽奖
  /// 子类必须实现此方法
  Future<void> stopRaffle();
  
  /// 重置抽奖
  /// 将抽奖状态重置为初始状态
  @mustCallSuper
  Future<void> resetRaffle() async {
    updateState(RaffleState.idle);
  }
  
  /// 更新抽奖状态
  /// @param newState 新的抽奖状态
  void updateState(RaffleState newState) {
    _state = newState;
    _stateController.add(newState);
  }
  
  /// 设置抽奖项目列表
  void setItems(List<RaffleItem> items) {
    _items = items;
  }
  
  /// 随机选择一个奖品
  RaffleItem selectRandomItem() {
    if (_items.isEmpty) {
      throw Exception('No raffle items available');
    }
    
    // 计算权重总和
    int totalWeight = _items.fold(0, (sum, item) => sum + item.weight);
    
    // 生成随机数
    int random = Random().nextInt(totalWeight);
    
    // 根据权重选择奖品
    int cumulativeWeight = 0;
    for (var item in _items) {
      cumulativeWeight += item.weight;
      if (random < cumulativeWeight) {
        return item;
      }
    }
    
    // 如果没有选中任何奖品（理论上不应该发生），选择第一个奖品
    return _items.first;
  }
  
  /// 生成抽奖结果
  /// 根据概率随机选择一个奖品
  /// @return 抽奖结果
  Future<RaffleResult> generateResult() async {
    // 如果没有奖品，抛出异常
    if (_items.isEmpty) {
      throw Exception('No raffle items available');
    }
    
    // 计算概率总和
    double totalProbability = items.fold(0, (sum, item) => sum + item.probability);
    
    // 如果概率总和不为1，进行归一化处理
    List<RaffleItem> normalizedItems = items;
    if (totalProbability != 1.0) {
      normalizedItems = items.map((item) {
        return item.copyWith(
          probability: item.probability / totalProbability
        );
      }).toList();
    }
    
    // 生成随机数
    double random = Random().nextDouble();
    
    // 根据概率选择奖品
    double cumulativeProbability = 0.0;
    RaffleItem? selectedItem;
    
    for (var item in normalizedItems) {
      cumulativeProbability += item.probability;
      if (random <= cumulativeProbability) {
        selectedItem = item;
        break;
      }
    }
    
    // 如果没有选中任何奖品（理论上不应该发生），选择第一个奖品
    selectedItem ??= normalizedItems.first;
    
    // 创建抽奖结果
    final result = RaffleResult(
      type: config.type,
      prize: selectedItem,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    
    // 播放音效（如果启用）
    if (config.enableSound) {
      await _raffle.playRaffleSound(config.type);
    }
    
    // 触发震动（如果启用）
    if (config.enableVibration) {
      await _raffle.triggerVibration(200);
    }
    
    // 保存抽奖结果
    await _raffle.saveRaffleResult(result);
    
    // 发送结果到流
    _resultController.add(result);
    
    // 调用抽奖完成回调
    onRaffleComplete?.call(result);
    
    return result;
  }
  
  /// 释放资源
  void dispose() {
    _stateController.close();
    _resultController.close();
  }
}

// RaffleState 枚举已移至 models/raffle_state.dart