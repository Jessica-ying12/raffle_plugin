import 'dart:async';
import 'package:flutter/material.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_state.dart';
import 'raffle_controller.dart';

/// 数字滚动抽奖控制器
class SlotRaffleController extends RaffleController {
  /// 抽奖结果
  RaffleResult? _result;

  /// 获取抽奖结果
  RaffleResult? get result => _result;

  /// 滚轮数量
  int reelCount;

  /// 每个转轴的符号数量
  final int symbolsPerReel;

  /// 设置转轴数量
  void setReelCount(int count) {
    if (count >= 3 && count <= 5) {
      reelCount = count;
      _currentIndices = List.filled(reelCount, 0);
    }
  }

  /// 每个滚轮的动画控制器
  final List<AnimationController> _animationControllers = [];

  /// 每个滚轮的滚动动画
  final List<Animation<double>> _scrollAnimations = [];

  /// 每个滚轮的动画监听器（用于移除旧监听）
  final List<VoidCallback?> _animationListeners = [];

  /// 每个滚轮当前显示的索引
  List<int> _currentIndices = [];

  /// 滚轮状态流控制器
  final StreamController<List<int>> _reelStateController =
      StreamController<List<int>>.broadcast();

  /// 滚轮状态流
  Stream<List<int>> get reelStateStream => _reelStateController.stream;

  /// 每个滚轮的项目高度
  final double itemHeight;

  /// 可见项目数量
  final int visibleItemCount;

  SlotRaffleController({
    required super.config,
    List<RaffleItem>? items,
    this.reelCount = 3,
    this.symbolsPerReel = 10,
    this.itemHeight = 60.0,
    this.visibleItemCount = 3,
    Function(RaffleResult)? onRaffleComplete,
  }) : super(items: items, onRaffleComplete: onRaffleComplete) {
    _currentIndices = List.filled(reelCount, 0);
    // 初始化监听器占位
    _animationListeners.addAll(List<VoidCallback?>.filled(reelCount, null));
  }

  /// 开始抽奖
  /// 初始化并启动滚动抽奖
  @override
  Future<RaffleResult> startRaffle() async {
    // 更新状态为进行中
    updateState(RaffleState.running);

    // 重置滚轮状态
    _currentIndices = List.filled(reelCount, 0);
    _reelStateController.add(_currentIndices);

    // 重置控制器，清理旧监听
    for (int i = 0; i < _animationControllers.length; i++) {
      final controller = _animationControllers[i];
      if (controller.isAnimating) {
        controller.stop();
      }
      controller.reset();
      // 移除旧监听
      final oldListener =
          _animationListeners.length > i ? _animationListeners[i] : null;
      if (oldListener != null && _scrollAnimations.length > i) {
        _scrollAnimations[i].removeListener(oldListener);
        _animationListeners[i] = null;
      }
    }

    // 执行抽奖逻辑
    _result = await _performRaffle();

    // 更新状态为已完成
    updateState(RaffleState.completed);

    // 发送结果
    resultController.add(_result!);

    return _result!;
  }

  /// 停止抽奖
  /// 强制停止滚动抽奖
  @override
  Future<void> stopRaffle() async {
    if (state != RaffleState.running) return;

    // 停止所有动画
    for (final controller in _animationControllers) {
      if (controller.isAnimating) {
        controller.stop();
      }
    }

    // 如果尚未有结果，生成一个结果
    if (_result == null) {
      final winnerItem = selectRandomItem();

      _result = RaffleResult(
        prize: winnerItem,
        type: config.type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // 发送结果
      resultController.add(_result!);
    }

    // 更新状态为已完成
    updateState(RaffleState.stopped);
  }

  Future<RaffleResult> _performRaffle() async {
    if (_animationControllers.isEmpty) {
      throw Exception('Animation controllers not initialized');
    }

    // 选择中奖项目
    final winnerItem = selectRandomItem();
    final winnerIndex = config.items.indexOf(winnerItem);

    // 为每个滚轮计算停止位置
    final targetIndices = _calculateTargetIndices(winnerIndex);

    // 创建滚动动画
    _createScrollAnimations(targetIndices);

    // 依次启动每个滚轮的动画（错开时间）
    final futures = <Future>[];
    for (int i = 0; i < reelCount; i++) {
      futures.add(_startReelAnimation(i, i * 200)); // 每个滚轮延迟200ms
    }

    // 等待所有动画完成
    await Future.wait(futures);

    // 等待额外的短暂延迟，确保动画完全结束
    await Future.delayed(const Duration(milliseconds: 200));

    // 创建抽奖结果
    final result = RaffleResult(
      prize: winnerItem,
      type: RaffleType.slot,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // 触发结果回调
    onRaffleComplete?.call(result);

    return result;
  }

  /// 计算每个滚轮的目标索引
  List<int> _calculateTargetIndices(int winnerIndex) {
    final targetIndices = <int>[];

    // 所有滚轮都显示中奖项目
    for (int i = 0; i < reelCount; i++) {
      targetIndices.add(winnerIndex);
    }

    return targetIndices;
  }

  /// 创建滚动动画
  void _createScrollAnimations(List<int> targetIndices) {
    _scrollAnimations.clear();

    for (int i = 0; i < reelCount; i++) {
      final currentIndex = _currentIndices[i];
      final targetIndex = targetIndices[i];

      // 计算滚动距离（统一滚动5圈）
      final minRotations = 5; // 所有滚轮滚动相同圈数
      final totalItems =
          minRotations * config.items.length + (targetIndex - currentIndex);

      _scrollAnimations.add(
        Tween<double>(
          begin: currentIndex.toDouble(),
          end: currentIndex + totalItems.toDouble(),
        ).animate(
          CurvedAnimation(
            parent: _animationControllers[i],
            curve: Curves.easeOutQuart, // 使用更强的减速效果，确保所有滚轮同步停止
          ),
        ),
      );
    }
  }

  /// 启动单个滚轮动画
  Future<void> _startReelAnimation(int reelIndex, int delayMs) async {
    // 可选延迟启动，用于实现错峰停止效果
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    // 防御性重置与停止
    final controller = _animationControllers[reelIndex];
    if (controller.isAnimating) {
      controller.stop();
    }
    controller.reset();

    // 监听动画变化
    final listener = () {
      final value = _scrollAnimations[reelIndex].value;
      _currentIndices[reelIndex] = (value % config.items.length).floor();
      _reelStateController.add(List.from(_currentIndices));
    };

    // 先移除旧监听，避免叠加
    if (_animationListeners.length > reelIndex &&
        _animationListeners[reelIndex] != null) {
      _scrollAnimations[reelIndex].removeListener(
        _animationListeners[reelIndex]!,
      );
    }
    _scrollAnimations[reelIndex].addListener(listener);
    if (_animationListeners.length <= reelIndex) {
      _animationListeners.add(listener);
    } else {
      _animationListeners[reelIndex] = listener;
    }

    // 启动动画
    await controller.forward();

    // 结束后再强制对齐一次并广播
    final endValue = _scrollAnimations[reelIndex].value;
    _currentIndices[reelIndex] = (endValue % config.items.length).floor();
    _reelStateController.add(List.from(_currentIndices));

    // 移除本次监听，避免堆积
    _scrollAnimations[reelIndex].removeListener(listener);
    _animationListeners[reelIndex] = null;
  }

  /// 初始化动画控制器
  void initializeAnimations(TickerProvider vsync) {
    _animationControllers.clear();
    _scrollAnimations.clear();
    _animationListeners.clear();

    for (int i = 0; i < reelCount; i++) {
      final duration = Duration(
        milliseconds: config.animationDuration + i * 500, // 后面的滚轮动画时间更长
      );

      _animationControllers.add(
        AnimationController(duration: duration, vsync: vsync),
      );
      // 占位，避免越界
      _animationListeners.add(null);
    }
  }

  /// 重置所有滚轮
  @override
  Future<void> resetRaffle() async {
    await super.resetRaffle();

    for (final controller in _animationControllers) {
      controller.reset();
    }

    _currentIndices = List.filled(reelCount, 0);
    _reelStateController.add(List.from(_currentIndices));
  }

  /// 重置抽奖（兼容性方法）
  Future<void> reset() async {
    return resetRaffle();
  }

  /// 获取指定滚轮的当前项目
  RaffleItem getCurrentItem(int reelIndex) {
    if (reelIndex >= 0 && reelIndex < reelCount) {
      final index = _currentIndices[reelIndex];
      return config.items[index % config.items.length];
    }
    return config.items[0];
  }

  /// 获取指定滚轮的滚动偏移量
  double getScrollOffset(int reelIndex) {
    if (reelIndex >= 0 && reelIndex < _scrollAnimations.length) {
      final animation = _scrollAnimations[reelIndex];
      final value = animation.value;
      final itemIndex = value % config.items.length;
      return (itemIndex - itemIndex.floor()) * itemHeight;
    }
    return 0.0;
  }

  /// 手动设置滚轮位置（用于手势控制）
  void setReelPosition(int reelIndex, int position) {
    if (state == RaffleState.idle && reelIndex >= 0 && reelIndex < reelCount) {
      _currentIndices[reelIndex] = position % config.items.length;
      _reelStateController.add(List.from(_currentIndices));
    }
  }

  @override
  void dispose() {
    for (int i = 0; i < _animationControllers.length; i++) {
      // 清理监听
      if (i < _scrollAnimations.length && i < _animationListeners.length) {
        final l = _animationListeners[i];
        if (l != null) {
          _scrollAnimations[i].removeListener(l);
          _animationListeners[i] = null;
        }
      }
      final controller = _animationControllers[i];
      controller.dispose();
    }
    _reelStateController.close();
    super.dispose();
  }
}
