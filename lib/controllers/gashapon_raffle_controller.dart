import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:raffle/models/raffle_state.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import 'raffle_controller.dart';

/// 扭蛋机抽奖控制器
class GashaponRaffleController extends RaffleController {
  /// 扭蛋掉落动画控制器
  AnimationController? _dropAnimationController;
  
  /// 扭蛋掉落动画
  Animation<double>? _dropAnimation;
  
  /// 扭蛋旋转动画控制器
  AnimationController? _rotationAnimationController;
  
  /// 扭蛋旋转动画
  Animation<double>? _rotationAnimation;
  
  /// 扭蛋弹跳动画控制器
  AnimationController? _bounceAnimationController;
  
  /// 扭蛋弹跳动画
  Animation<double>? _bounceAnimation;
  
  /// 扭蛋位置流控制器
  final StreamController<Offset> _eggPositionController = StreamController<Offset>.broadcast();
  
  /// 扭蛋位置流
  Stream<Offset> get eggPositionStream => _eggPositionController.stream;
  
  /// 扭蛋旋转角度流控制器
  final StreamController<double> _eggRotationController = StreamController<double>.broadcast();
  
  /// 扭蛋旋转角度流
  Stream<double> get eggRotationStream => _eggRotationController.stream;
  
  /// 扭蛋可见性流控制器
  final StreamController<bool> _eggVisibilityController = StreamController<bool>.broadcast();
  
  /// 扭蛋可见性流
  Stream<bool> get eggVisibilityStream => _eggVisibilityController.stream;
  
  /// 当前扭蛋颜色
  Color _currentEggColor = Colors.blue;
  
  
  /// 扭蛋颜色流控制器
  final StreamController<Color> _eggColorController = StreamController<Color>.broadcast();
  
  /// 扭蛋颜色流
  Stream<Color> get eggColorStream => _eggColorController.stream;
  
  /// 掉落高度
  final double dropHeight;
  
  /// 弹跳次数
  final int bounceCount;
  
  /// 扭蛋大小
  final double eggSize;
  
  /// 是否显示粒子效果
  final bool showParticles;
  
  GashaponRaffleController({
    required super.config,
    required super.items,
    this.dropHeight = 300.0,
    this.bounceCount = 3,
    this.eggSize = 80.0,
    this.showParticles = true,
    super.onRaffleComplete,
  });

  @override
  Future<RaffleResult> startRaffle() async {
    if (_dropAnimationController == null) {
      throw Exception('Animation controllers not initialized');
    }
    
    // 更新状态为运行中
    updateState(RaffleState.running);
    
    // 选择中奖项目
    final winnerItem = selectRandomItem();
    
    // 根据奖品等级设置扭蛋颜色
    _setEggColorByPrize(winnerItem);
    
    // 显示扭蛋
    _eggVisibilityController.add(true);
    
    // 执行掉落动画序列
    await _performDropSequence();
    
    // 更新状态为已完成
    updateState(RaffleState.completed);
    
    // 创建结果
    final result = RaffleResult(
      type: config.type,
      prize: winnerItem,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      extraData: {'color': _currentEggColor.value},
    );
    
    // 处理结果（播放音效、震动等）
    await processResult(result);
    
    return result;
  }
  
  @override
  Future<void> stopRaffle() async {
    // 如果不在运行状态，则不执行任何操作
    if (state != RaffleState.running) return;
    
    // 停止所有动画
    _dropAnimationController?.stop();
    _rotationAnimationController?.stop();
    _bounceAnimationController?.stop();
    
    // 更新状态为空闲
    updateState(RaffleState.idle);
    
    // 隐藏扭蛋
    _eggVisibilityController.add(false);
  }
  
  /// 处理抽奖结果
  /// 播放音效、触发震动等
  Future<void> processResult(RaffleResult result) async {
    // 播放音效（如果启用）
    if (config.enableSound) {
      await super.raffle.playRaffleSound(config.type);
    }
    
    // 触发震动（如果启用）
    if (config.enableVibration) {
      await super.raffle.triggerVibration(200);
    }
    
    // 保存抽奖结果
    await super.raffle.saveRaffleResult(result);
    
    // 发送结果到流
    super.resultController.add(result);
  }
  

  
  /// 执行抽奖逻辑（内部方法）
  Future<void> _performRaffle() async {
    if (_dropAnimationController == null) {
      throw Exception('Animation controllers not initialized');
    }
    
    // 选择中奖项目
    final winnerItem = selectRandomItem();
    
    // 根据奖品等级设置扭蛋颜色
    _setEggColorByPrize(winnerItem);
    
    // 显示扭蛋
    _eggVisibilityController.add(true);
    
    // 执行掉落动画序列
    await _performDropSequence();
  }
  
  /// 执行掉落动画序列
  Future<void> _performDropSequence() async {
    // 1. 启动旋转动画
    _rotationAnimationController?.repeat();
    
    // 2. 执行掉落动画
    await _dropAnimationController?.forward();
    
    // 3. 停止旋转
    _rotationAnimationController?.stop();
    
    // 4. 执行弹跳动画
    for (int i = 0; i < bounceCount; i++) {
      await _bounceAnimationController?.forward();
      await _bounceAnimationController?.reverse();
      
      // 每次弹跳后稍作停顿
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // 5. 稍作停顿显示结果
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  /// 根据奖品等级设置扭蛋颜色
  void _setEggColorByPrize(RaffleItem item) {
    switch (item.type) {
      case RaffleItemType.grand:
        _currentEggColor = Colors.amber;
        break;
      case RaffleItemType.first:
        _currentEggColor = Colors.purple;
        break;
      case RaffleItemType.second:
        _currentEggColor = Colors.blue;
        break;
      case RaffleItemType.third:
        _currentEggColor = Colors.orange;
        break;
      case RaffleItemType.consolation:
        _currentEggColor = Colors.brown;
        break;
      case RaffleItemType.thanks:
        _currentEggColor = Colors.grey[300]!;
        break;
      case RaffleItemType.normal:
        _currentEggColor = Colors.grey;
        break;
    }
    
    _eggColorController.add(_currentEggColor);
  }
  
  /// 初始化动画控制器
  void initializeAnimations(TickerProvider vsync) {
    // 掉落动画
    _dropAnimationController = AnimationController(
      duration: Duration(milliseconds: config.animationDuration),
      vsync: vsync,
    );
    
    _dropAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dropAnimationController!,
      curve: Curves.bounceOut,
    ));
    
    _dropAnimation?.addListener(() {
      final progress = _dropAnimation!.value;
      final yPosition = dropHeight * progress;
      _eggPositionController.add(Offset(0, yPosition));
    });
    
    // 旋转动画
    _rotationAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: vsync,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_rotationAnimationController!);
    
    _rotationAnimation?.addListener(() {
      _eggRotationController.add(_rotationAnimation!.value);
    });
    
    // 弹跳动画
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 20.0,
    ).animate(CurvedAnimation(
      parent: _bounceAnimationController!,
      curve: Curves.elasticOut,
    ));
    
    _bounceAnimation?.addListener(() {
      final currentPosition = _eggPositionController.hasListener 
          ? Offset(0, dropHeight) 
          : Offset(0, dropHeight);
      final bounceOffset = Offset(0, currentPosition.dy - _bounceAnimation!.value);
      _eggPositionController.add(bounceOffset);
    });
  }
  
  /// 手动触发扭蛋掉落（用于用户交互）
  Future<void> triggerDrop() async {
    if (state == RaffleState.running) {
      // 如果正在运行，不允许重复触发
      return;
    }
    
    await startRaffle();
  }
  
  /// 重置扭蛋机
  @override
  Future<void> resetRaffle() async {
    _dropAnimationController?.reset();
    _rotationAnimationController?.reset();
    _bounceAnimationController?.reset();
    
    _eggPositionController.add(const Offset(0, 0));
    _eggRotationController.add(0.0);
    _eggVisibilityController.add(false);
    _eggColorController.add(Colors.blue);
    
    _currentEggColor = Colors.blue;
    
    // 更新状态为空闲
    updateState(RaffleState.idle);
  }
  
  /// 获取当前扭蛋颜色
  Color get currentEggColor => _currentEggColor;
  
  /// 获取扭蛋掉落进度
  double get dropProgress => _dropAnimation?.value ?? 0.0;
  
  /// 获取扭蛋旋转角度
  double get rotationAngle => _rotationAnimation?.value ?? 0.0;
  
  /// 获取扭蛋弹跳偏移
  double get bounceOffset => _bounceAnimation?.value ?? 0.0;
  
  /// 检查扭蛋是否可见
  bool get isEggVisible => state == RaffleState.running || state == RaffleState.completed;
  
  /// 生成随机扭蛋颜色（用于预览）
  Color getRandomEggColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];
    
    return colors[Random().nextInt(colors.length)];
  }
  
  /// 预览扭蛋掉落（不进行实际抽奖）
  Future<void> previewDrop() async {
    if (state != RaffleState.idle) return;
    
    // 设置随机颜色
    final previewColor = getRandomEggColor();
    _eggColorController.add(previewColor);
    
    // 显示扭蛋
    _eggVisibilityController.add(true);
    
    // 执行简化的掉落动画
    _rotationAnimationController?.repeat();
    await _dropAnimationController?.forward();
    _rotationAnimationController?.stop();
    
    // 短暂停顿后隐藏
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // 重置状态
    _dropAnimationController?.reset();
    _rotationAnimationController?.reset();
    _eggPositionController.add(const Offset(0, 0));
    _eggRotationController.add(0.0);
    _eggVisibilityController.add(false);
  }
  
  /// 获取当前状态描述
  String getStatusDescription() {
    switch (state) {
      case RaffleState.idle:
        return '准备就绪，点击扭蛋机开始';
      case RaffleState.running:
        return '正在抽取扭蛋...';
      case RaffleState.completed:
        return '恭喜获得奖品！';
      default:
        return '扭蛋机状态未知';
    }
  }
  
  /// 计算扭蛋在屏幕上的实际位置
  Offset calculateEggScreenPosition(Size screenSize) {
    final centerX = screenSize.width / 2;
    final startY = 100.0; // 扭蛋机出口位置
    final currentOffset = _eggPositionController.hasListener 
        ? Offset(0, dropHeight) 
        : const Offset(0, 0);
    
    return Offset(centerX, startY + currentOffset.dy);
  }
  
  @override
  void dispose() {
    _dropAnimationController?.dispose();
    _rotationAnimationController?.dispose();
    _bounceAnimationController?.dispose();
    
    _eggPositionController.close();
    _eggRotationController.close();
    _eggVisibilityController.close();
    _eggColorController.close();
    
    super.dispose();
  }
  
  /// 重置抽奖（兼容性方法）
  /// 调用resetRaffle方法
  Future<void> reset() async {
    return resetRaffle();
  }
}