import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_state.dart';
import 'raffle_controller.dart';

/// 大转盘抽奖控制器
///
/// 实现大转盘形式的抽奖逻辑，包括旋转动画控制和结果计算
/// 继承自RaffleController基类，提供大转盘特有的抽奖体验
class WheelRaffleController extends RaffleController {
  /// 抽奖结果
  RaffleResult? _result;

  /// 获取抽奖结果
  RaffleResult? get result => _result;

  /// 动画控制器
  AnimationController? _animationController;

  /// 旋转动画
  Animation<double>? _rotationAnimation;

  /// 当前旋转角度
  double _currentRotation = 0.0;

  /// 当前旋转角度
  double _rotationAngle = 0.0;

  /// 是否正在旋转
  bool _isSpinning = false;

  /// 旋转角度流控制器
  final StreamController<double> _rotationController =
      StreamController<double>.broadcast();

  /// 获取旋转角度
  double get rotationAngle => _rotationAngle;

  /// 获取是否正在旋转
  bool get isSpinning => _isSpinning;

  /// 旋转角度流
  Stream<double> get rotationStream => _rotationController.stream;

  /// 每个扇形的角度
  double get sectorAngle => 2 * pi / config.items.length;

  /// 构造函数
  ///
  /// 创建大转盘抽奖控制器实例
  ///
  /// @param config 抽奖配置，必须是大转盘类型的配置
  /// @param items 可选的初始奖品列表
  WheelRaffleController({
    required super.config,
    List<RaffleItem>? items,
    Function(RaffleResult)? onRaffleComplete,
  }) : super(items: items, onRaffleComplete: onRaffleComplete);

  /// 开始抽奖
  /// 初始化并启动大转盘抽奖
  @override
  Future<RaffleResult> startRaffle() async {
    // 更新状态为进行中
    updateState(RaffleState.running);

    // 设置为正在旋转
    _isSpinning = true;

    // 执行抽奖逻辑
    // 注意：_performRaffle内部已经调用了onRaffleComplete回调
    _result = await _performRaffle();

    // 更新状态为已完成
    updateState(RaffleState.completed);

    // 设置为不再旋转
    _isSpinning = false;

    // 发送结果
    resultController.add(_result!);

    return _result!;
  }

  /// 停止抽奖
  /// 强制停止大转盘抽奖
  @override
  Future<void> stopRaffle() async {
    if (state != RaffleState.running) return;

    // 停止动画
    if (_animationController != null && _animationController!.isAnimating) {
      _animationController!.stop();
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
    updateState(RaffleState.completed);

    // 设置为不再旋转
    _isSpinning = false;
  }

  /// 执行大转盘抽奖逻辑
  ///
  /// 实现抽奖动画和结果计算的核心方法
  /// 包括选择中奖项目、计算旋转角度、控制转盘旋转等
  ///
  /// @return 抽奖结果
  /// @throws Exception 当动画控制器未初始化时抛出
  Future<RaffleResult> _performRaffle() async {
    if (_animationController == null) {
      throw Exception('Animation controller not initialized');
    }

    // 选择中奖项目
    final winnerItem = selectRandomItem();
    final winnerIndex = config.items.indexOf(winnerItem);

    // 计算目标角度
    final targetAngle = _calculateTargetAngle(winnerIndex);

    // 创建旋转动画，使用更平滑的曲线提高流畅度
    _rotationAnimation = Tween<double>(
      begin: _currentRotation,
      end: targetAngle,
    ).animate(
      CurvedAnimation(
        parent: _animationController!,
        // 使用easeOutCubic曲线提供更自然的减速效果
        curve: Curves.easeOutCubic,
      ),
    );

    // 监听动画变化
    _rotationAnimation!.addListener(() {
      _currentRotation = _rotationAnimation!.value;
      _rotationController.add(_currentRotation);
    });

    // 启动动画
    await _animationController!.forward();

    // 动画结束后，根据最终角度重新计算实际指向的奖品
    final finalSectorIndex = getCurrentSectorIndex();
    final actualWinnerItem = config.items[finalSectorIndex];

    // 创建抽奖结果，使用实际停止位置对应的奖品
    final result = RaffleResult(
      prize: actualWinnerItem,
      type: RaffleType.wheel,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      extraData: {
        'sectorIndex': finalSectorIndex,
        'rotationAngle': _currentRotation,
        'animationDuration': config.animationDuration,
      },
    );

    // 调用抽奖完成回调
    if (onRaffleComplete != null) {
      onRaffleComplete!(result);
    }

    return result;
  }

  /// 计算目标角度
  ///
  /// 根据中奖索引计算转盘需要旋转的目标角度
  /// 包括基础旋转圈数、随机额外旋转和目标扇形位置计算
  ///
  /// @param winnerIndex 中奖项目在列表中的索引
  /// @return 转盘需要旋转的目标角度（弧度）
  double _calculateTargetAngle(int winnerIndex) {
    // 基础旋转圈数（至少4圈，提供更流畅的体验）
    const baseRotations = 4;
    final baseAngle = baseRotations * 2 * pi;

    // 随机额外旋转（0.5-1.5圈），增加随机性但保持平滑
    final extraRotations = 0.5 + Random().nextDouble();
    final extraAngle = extraRotations * 2 * pi;

    // 目标扇形的中心角度
    final sectorCenterAngle = winnerIndex * sectorAngle + sectorAngle / 2;

    // 由于转盘是顺时针旋转，但指针固定在顶部，所以需要反向计算
    final targetSectorAngle = 2 * pi - sectorCenterAngle;

    // 添加随机偏移（在扇形范围内，但范围更小以确保精确性）
    final randomOffset = (Random().nextDouble() - 0.5) * sectorAngle * 0.4;

    return _currentRotation +
        baseAngle +
        extraAngle +
        targetSectorAngle +
        randomOffset;
  }

  /// 初始化动画控制器
  ///
  /// 设置转盘旋转动画的控制器
  /// 初始化动画
  /// 必须在使用控制器前调用此方法
  ///
  /// @param vsync 动画帧同步器，通常是StatefulWidget的State对象
  void initializeAnimation(TickerProvider vsync) {
    _animationController = AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: config.animationDuration),
    );
  }

  /// 重置转盘
  ///
  /// 将转盘重置为初始状态，清除旋转角度
  /// 重写父类方法以添加转盘特有的重置逻辑
  @override
  Future<void> resetRaffle() async {
    await super.resetRaffle();
    _animationController?.reset();
    _currentRotation = 0.0;
    _rotationController.add(_currentRotation);
  }

  /// 重置抽奖（兼容性方法）
  Future<void> reset() async {
    return resetRaffle();
  }

  /// 获取当前旋转角度
  double get currentRotation => _currentRotation;

  /// 根据角度获取当前指向的扇形索引
  ///
  /// 计算当前旋转角度下指针指向的扇形索引
  /// 用于手动旋转或动画过程中获取当前位置
  ///
  /// @return 当前指向的扇形索引
  int getCurrentSectorIndex() {
    // 标准化角度到 0-2π 范围
    final normalizedAngle = _currentRotation % (2 * pi);

    // 由于指针在顶部，需要调整角度计算
    final adjustedAngle = (2 * pi - normalizedAngle) % (2 * pi);

    // 计算扇形索引
    final sectorIndex = (adjustedAngle / sectorAngle).floor();

    return sectorIndex.clamp(0, config.items.length - 1);
  }

  /// 手动设置旋转角度（用于手势控制）
  void setRotation(double angle) {
    if (state == RaffleState.idle) {
      _currentRotation = angle;
      _rotationController.add(_currentRotation);
    }
  }

  /// 添加旋转角度（用于惯性滚动）
  void addRotation(double deltaAngle) {
    if (state == RaffleState.idle) {
      _currentRotation += deltaAngle;
      _rotationController.add(_currentRotation);
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _rotationController.close();
    super.dispose();
  }
}
