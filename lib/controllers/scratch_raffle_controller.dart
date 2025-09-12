import 'dart:async';
import 'package:flutter/material.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../models/raffle_state.dart';
import 'raffle_controller.dart';

/// 刮刮卡抽奖控制器
class ScratchRaffleController extends RaffleController {
  /// 抽奖结果
  RaffleResult? _result;
  
  /// 获取抽奖结果
  RaffleResult? get result => _result;
  /// 刮开的路径点
  final List<Offset> _scratchedPoints = [];
  
  /// 刮开区域流控制器
  final StreamController<List<Offset>> _scratchController = StreamController<List<Offset>>.broadcast();
  
  /// 刮开区域流
  Stream<List<Offset>> get scratchStream => _scratchController.stream;
  
  /// 刮开进度流控制器
  final StreamController<double> _progressController = StreamController<double>.broadcast();
  
  /// 刮开进度流
  Stream<double> get progressStream => _progressController.stream;
  
  /// 卡片尺寸
  final Size cardSize;
  
  /// 刮开阈值（0.0-1.0）
  double _scratchThreshold = 0.7;
  
  /// 刮开进度（0.0-1.0）
  double _scratchProgress = 0.0;
  
  /// 是否已完全刮开
  bool _isRevealed = false;
  
  /// 获取刮开阈值
  double get scratchThreshold => _scratchThreshold;
  
  /// 获取刮开进度
  double get scratchProgress => _scratchProgress;
  
  /// 获取是否已刮开
  bool get isRevealed => _isRevealed;
  
  /// 设置刮开阈值
  void setScratchThreshold(double threshold) {
    if (threshold >= 0.0 && threshold <= 1.0) {
      _scratchThreshold = threshold;
    }
  }
  
  /// 刮开画笔大小
  final double brushSize;
  
  /// 完成刮开的阈值（0.0-1.0）
  final double completeThreshold;
  
  /// 当前刮开进度
  double _currentProgress = 0.0;
  
  /// 中奖项目（预先确定）
  RaffleItem? _winnerItem;
  
  /// 是否已经完成刮开
  bool _isCompleted = false;
  
  ScratchRaffleController({
    required super.config,
    List<RaffleItem>? items,
    required this.cardSize,
    this.brushSize = 20.0,
    this.completeThreshold = 0.6,
    Function(RaffleResult)? onRaffleComplete,
  }) : super(items: items, onRaffleComplete: onRaffleComplete);
  
  /// 开始抽奖
  /// 初始化刮刮卡抽奖，预先确定中奖项目
  @override
  Future<RaffleResult> startRaffle() async {
    // 更新状态为进行中
    updateState(RaffleState.running);
    
    // 重置刮开状态
    _scratchedPoints.clear();
    _scratchProgress = 0.0;
    _isRevealed = false;
    _isCompleted = false;
    
    // 发送初始状态
    _scratchController.add(_scratchedPoints);
    _progressController.add(_scratchProgress);
    
    // 执行抽奖逻辑
    _result = await _performRaffle();
    return _result!;
  }
  
  /// 停止抽奖
  /// 强制完成刮刮卡抽奖
  @override
  Future<void> stopRaffle() async {
    if (state != RaffleState.running) return;
    
    // 如果尚未完成，强制完成
    if (!_isCompleted && _result == null) {
      // 预先确定中奖项目
      _winnerItem = selectRandomItem();
      
      _result = RaffleResult(
        prize: _winnerItem!,
        type: config.type,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      
      // 发送结果
      resultController.add(_result!);
    }
    
    // 更新状态为已完成
    updateState(RaffleState.completed);
    
    // 设置为已完全刮开
    _isRevealed = true;
    _scratchProgress = 1.0;
    _progressController.add(_scratchProgress);
  }

  Future<RaffleResult> _performRaffle() async {
    // 预先确定中奖项目
    _winnerItem = selectRandomItem();
    
    // 刮刮卡不需要自动动画，等待用户手势操作
    // 返回一个Completer，等待刮开完成
    final completer = Completer<RaffleResult>();
    
    // 监听进度变化，当达到阈值时完成抽奖
    late StreamSubscription subscription;
    subscription = progressStream.listen((progress) {
      if (progress >= completeThreshold && !_isCompleted) {
        _isCompleted = true;
        subscription.cancel();
        
        final result = RaffleResult(
          prize: _winnerItem!,
          type: RaffleType.scratch,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        
        completer.complete(result);
      }
    });
    
    return completer.future;
  }
  
  /// 添加刮开点
  void addScratchPoint(Offset point) {
    if (state != RaffleState.running || _isCompleted) return;
    
    _scratchedPoints.add(point);
    _scratchController.add(List.from(_scratchedPoints));
    
    // 计算刮开进度
    _updateProgress();
  }
  
  /// 添加刮开路径
  void addScratchPath(List<Offset> points) {
    if (state != RaffleState.running || _isCompleted) return;
    
    _scratchedPoints.addAll(points);
    _scratchController.add(List.from(_scratchedPoints));
    
    // 计算刮开进度
    _updateProgress();
  }
  
  /// 更新刮开进度
  void _updateProgress() {
    if (_scratchedPoints.isEmpty) {
      _currentProgress = 0.0;
    } else {
      // 简化的进度计算：基于刮开点的数量和分布
      final totalArea = cardSize.width * cardSize.height;
      final scratchedArea = _calculateScratchedArea();
      _currentProgress = (scratchedArea / totalArea).clamp(0.0, 1.0);
    }
    
    _progressController.add(_currentProgress);
    
    // 检查是否达到完成阈值
    if (_currentProgress >= completeThreshold && !_isCompleted) {
      _completeRaffle();
    }
  }
  
  /// 计算刮开面积
  double _calculateScratchedArea() {
    if (_scratchedPoints.isEmpty) return 0.0;
    
    // 使用网格采样方法估算刮开面积
    const gridSize = 10;
    final stepX = cardSize.width / gridSize;
    final stepY = cardSize.height / gridSize;
    
    int scratchedCells = 0;
    
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final cellCenter = Offset(
          x * stepX + stepX / 2,
          y * stepY + stepY / 2,
        );
        
        // 检查这个网格单元是否被刮开
        if (_isCellScratched(cellCenter)) {
          scratchedCells++;
        }
      }
    }
    
    return (scratchedCells / (gridSize * gridSize)) * (cardSize.width * cardSize.height);
  }
  
  /// 检查网格单元是否被刮开
  bool _isCellScratched(Offset cellCenter) {
    for (final point in _scratchedPoints) {
      final distance = (point - cellCenter).distance;
      if (distance <= brushSize / 2) {
        return true;
      }
    }
    return false;
  }
  
  /// 完成刮开
  void _completeRaffle() {
    // 完成逻辑已在_performRaffle中处理
    // 这里只需要标记完成状态
    _isCompleted = true;
  }
  
  /// 手动完成刮开（用于调试或强制完成）
  void forceComplete() {
    if (state == RaffleState.running && !_isCompleted) {
      _currentProgress = 1.0;
      _progressController.add(_currentProgress);
      _completeRaffle();
    }
  }
  
  /// 清除刮开区域
  void clearScratch() {
    if (state == RaffleState.idle) {
      _scratchedPoints.clear();
      _currentProgress = 0.0;
      _isCompleted = false;
      _winnerItem = null;
      
      _scratchController.add([]);
      _progressController.add(0.0);
    }
  }
  
  /// 重置刮刮卡
  @override
  Future<void> resetRaffle() async {
    await super.resetRaffle();
    _scratchedPoints.clear();
    _currentProgress = 0.0;
    _isCompleted = false;
    _winnerItem = null;
    
    _scratchController.add([]);
    _progressController.add(0.0);
  }
  
  /// 获取当前刮开进度
  double get currentProgress => _currentProgress;
  
  /// 获取中奖项目（如果已确定）
  RaffleItem? get winnerItem => _winnerItem;
  
  /// 获取刮开点列表
  List<Offset> get scratchedPoints => List.from(_scratchedPoints);
  
  /// 检查指定点是否已被刮开
  bool isPointScratched(Offset point) {
    for (final scratchPoint in _scratchedPoints) {
      final distance = (point - scratchPoint).distance;
      if (distance <= brushSize / 2) {
        return true;
      }
    }
    return false;
  }
  
  /// 获取刮开遮罩路径
  Path getScratchMaskPath() {
    final path = Path();
    
    for (int i = 0; i < _scratchedPoints.length; i++) {
      final point = _scratchedPoints[i];
      
      if (i == 0) {
        path.addOval(Rect.fromCircle(
          center: point,
          radius: brushSize / 2,
        ));
      } else {
        // 连接相邻的点
        final prevPoint = _scratchedPoints[i - 1];
        final distance = (point - prevPoint).distance;
        
        if (distance <= brushSize) {
          // 添加连接线
          path.addOval(Rect.fromCircle(
            center: point,
            radius: brushSize / 2,
          ));
        } else {
          // 距离太远，开始新的路径
          path.addOval(Rect.fromCircle(
            center: point,
            radius: brushSize / 2,
          ));
        }
      }
    }
    
    return path;
  }
  
  // This is a duplicate method that should be removed since there's already a resetRaffle method defined earlier in the file
  
  /// 重置抽奖（兼容性方法）
  Future<void> reset() async {
    return resetRaffle();
  }
  
  @override
  void dispose() {
    _scratchController.close();
    _progressController.close();
    super.dispose();
  }
}