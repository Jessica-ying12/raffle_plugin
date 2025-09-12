import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_state.dart';
import 'raffle_controller.dart';

/// 九宫格抽奖控制器
///
/// 实现九宫格形式的抽奖逻辑，包括动画控制和结果计算
/// 继承自RaffleController基类，提供九宫格特有的抽奖体验
class GridRaffleController extends RaffleController {
  /// 抽奖结果
  RaffleResult? _result;

  /// 动画定时器
  Timer? _animationTimer;

  /// 高亮位置流控制器
  final StreamController<int> _highlightController =
      StreamController<int>.broadcast();

  /// 跑动路径（按顺序）
  static const List<int> _runPath = [
    0,
    1,
    2,
    5,
    8,
    7,
    6,
    3,
    0,
    1,
    2,
    5,
    8,
    7,
    6,
    3,
  ];

  /// 最小跑动圈数
  final int minRounds;

  /// 最大跑动圈数
  final int maxRounds;

  /// 跑动速度（毫秒）
  final int initialSpeed;

  /// 减速因子
  final double decelerationFactor;

  /// 当前高亮位置索引
  int _currentIndex = 0;

  /// 获取指定奖品在九宫格中的索引位置
  ///
  /// @param item 要查找的奖品
  /// @return 奖品在九宫格中的索引，如果未找到则返回-1
  int getItemIndex(RaffleItem item) {
    return items.indexWhere((element) => element.id == item.id);
  }

  /// 构造函数
  ///
  /// 创建九宫格抽奖控制器实例
  ///
  /// @param config 抽奖配置，必须是九宫格类型的配置
  GridRaffleController({
    required super.config,
    List<RaffleItem>? items,
    this.minRounds = 3,
    this.maxRounds = 5,
    this.initialSpeed = 100,
    this.decelerationFactor = 1.2,
    Function(RaffleResult)? onRaffleComplete,
  }) : super(items: items, onRaffleComplete: onRaffleComplete);

  /// 获取高亮位置流
  Stream<int> get highlightStream => _highlightController.stream;

  /// 初始化动画
  ///
  /// @param tickerProvider 动画控制器提供者
  void initializeAnimations(TickerProvider tickerProvider) {
    // 初始化动画相关资源
  }

  /// 处理抽奖结果
  /// 播放音效、触发震动等
  Future<void> processResult(RaffleResult result) async {
    // 播放音效（如果启用）
    if (config.playSoundOnResult && config.enableSound) {
      await super.raffle.playRaffleSound(result.type);
    }

    // 触发震动（如果启用）
    if (config.vibrateOnResult && config.enableVibration) {
      await super.raffle.triggerVibration(200);
    }

    // 保存抽奖结果
    await super.raffle.saveRaffleResult(result);

    // 发送结果到流
    super.resultController.add(result);
  }

  /// 获取当前索引
  int get currentIndex => _currentIndex;

  /// 获取抽奖结果
  RaffleResult? get result => _result;

  /// 开始抽奖
  ///
  /// 启动九宫格抽奖动画并返回抽奖结果
  /// 实现抽奖的核心逻辑，包括动画控制和结果计算
  ///
  /// @return 抽奖结果
  @override
  Future<RaffleResult> startRaffle() async {
    // 如果已经在运行中，则不执行任何操作
    if (state == RaffleState.running) {
      throw Exception('抽奖已经在进行中');
    }

    // 更新状态为运行中
    updateState(RaffleState.running);

    // 执行抽奖逻辑
    final result = await _performRaffle();

    // 更新状态为已完成
    updateState(RaffleState.completed);

    // 处理结果
    await processResult(result);

    // 触发回调
    if (config.onRaffleComplete != null) {
      config.onRaffleComplete!(result);
    }

    return result;
  }

  /// 执行九宫格抽奖逻辑
  ///
  /// 实现抽奖动画和结果计算的核心方法
  /// 包括选择中奖项目、计算动画参数、控制高亮位置变化等
  ///
  /// @return 抽奖结果
  /// @throws StateError 当中奖索引无效时抛出
  Future<RaffleResult> _performRaffle() async {
    final completer = Completer<RaffleResult>();

    // 选择中奖项目
    final winningItem = selectRandomItem();
    final winningIndex = getItemIndex(winningItem);

    // 确保中奖索引有效
    if (winningIndex < 0 || winningIndex >= config.items.length) {
      throw StateError('无效的中奖索引: $winningIndex');
    }

    // 计算跑动参数
    // 随机确定跑动圈数，在最小和最大圈数之间
    final rounds = minRounds + Random().nextInt(maxRounds - minRounds + 1);
    // 获取中奖位置在路径中的索引
    final pathIndex = _getPathIndexForGridIndex(winningIndex);
    // 计算总步数 = 完整圈数 * 每圈步数(8) + 额外步数
    final totalSteps = rounds * 8 + pathIndex;

    int currentStep = 0;
    int currentSpeed = initialSpeed;

    void runAnimation() {
      if (currentStep >= totalSteps) {
        // 动画结束，确保停在正确位置
        _currentIndex = winningIndex;
        _highlightController.add(_currentIndex);
        _animationTimer?.cancel();

        final result = RaffleResult(
          type: config.type,
          prize: winningItem,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          extraData: {
            'index': winningIndex,
            'animationDuration': config.animationDuration,
          },
        );
        _result = result;
        completer.complete(result);
        return;
      }

      // 更新当前高亮位置（按路径移动）
      final pathPosition = currentStep % 8;
      _currentIndex = _runPath[pathPosition];
      _highlightController.add(_currentIndex);

      // 计算下一步的速度（逐渐减速）
      if (currentStep > totalSteps * 0.7) {
        currentSpeed = (currentSpeed * decelerationFactor).round();
        currentSpeed = currentSpeed.clamp(200, 800); // 调整速度范围
      }

      currentStep++;

      // 设置下一次动画
      _animationTimer = Timer(
        Duration(milliseconds: currentSpeed),
        runAnimation,
      );
    }

    // 开始动画
    runAnimation();

    return completer.future;
  }

  /// 获取网格索引对应的路径索引
  ///
  /// 将九宫格位置索引转换为动画路径上的位置
  /// 九宫格按顺时针方向运行，此方法确保动画正确显示
  ///
  /// @param gridIndex 九宫格位置索引(0-8)
  /// @return 对应的路径索引(0-7)
  int _getPathIndexForGridIndex(int gridIndex) {
    // 九宫格布局：
    // 0 1 2
    // 3 4 5
    // 6 7 8
    //
    // 跑动路径：0->1->2->5->8->7->6->3->0...
    const gridToPathMap = {
      0: 0, // 左上
      1: 1, // 上中
      2: 2, // 右上
      5: 3, // 右中
      8: 4, // 右下
      7: 5, // 下中
      6: 6, // 左下
      3: 7, // 左中
      4: 0, // 中心（映射到起始位置）
    };

    return gridToPathMap[gridIndex] ?? 0;
  }

  /// 停止抽奖
  ///
  /// 取消当前运行的动画定时器并更新状态
  /// 用于中断正在进行的抽奖过程
  @override
  Future<void> stopRaffle() async {
    // 如果不在运行状态，直接返回
    if (state != RaffleState.running) return;

    // 取消动画定时器
    _animationTimer?.cancel();

    // 更新状态为已完成
    updateState(RaffleState.completed);
  }

  /// 更新抽奖项目
  ///
  /// 替换当前的奖品列表
  ///
  /// @param newItems 新的奖品列表
  void updateItems(List<RaffleItem> newItems) {
    setItems(newItems);
  }

  /// 重置抽奖
  ///
  /// 取消动画，重置高亮位置，并恢复初始状态
  @override
  Future<void> resetRaffle() async {
    await super.resetRaffle();
    _animationTimer?.cancel();
    _currentIndex = 0;
    _highlightController.add(_currentIndex);
    _result = null;
  }

  /// 重置抽奖（兼容性方法）
  Future<void> reset() async {
    return resetRaffle();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    _highlightController.close();
    super.dispose();
  }
}
