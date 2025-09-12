import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../models/raffle_state.dart';
import 'raffle_controller.dart';

/// 幸运卡片抽奖控制器
class LuckyCardRaffleController extends RaffleController {
  /// 卡片数量
  int cardCount;
  
  /// 是否允许手动选择
  final bool allowManualSelection;
  
  /// 选择延迟（毫秒）
  final int selectionDelay;
  
  /// 当前选中的卡片索引
  int _selectedCardIndex = -1;
  
  /// 是否自动模式
  bool _isAutoMode = true;
  
  /// 获取选中的卡片索引
  int get selectedCardIndex => _selectedCardIndex;
  
  /// 获取是否自动模式
  bool get isAutoMode => _isAutoMode;
  
  /// 设置卡片数量
  void setCardCount(int count) {
    if (count >= 3 && count <= 12) {
      cardCount = count;
      _cardSelected = List.filled(cardCount, false);
    }
  }
  
  /// 设置自动模式
  void setAutoMode(bool autoMode) {
    _isAutoMode = autoMode;
  }
  
  /// 每张卡片的动画控制器
  final List<AnimationController> _animationControllers = [];
  
  /// 每张卡片的选择动画
  final List<Animation<double>> _selectionAnimations = [];
  
  /// 每张卡片的当前选择状态
  List<bool> _cardSelected = [];
  
  /// 卡片状态流控制器
  final StreamController<List<bool>> _cardStateController = StreamController<List<bool>>.broadcast();
  
  /// 卡片颜色流控制器
  final StreamController<Color> _cardColorController = StreamController<Color>.broadcast();
  
  /// 卡片颜色流
  Stream<Color> get cardColorStream => _cardColorController.stream;
  
  /// 卡片展开进度流控制器
  final StreamController<double> _expandProgressController = StreamController<double>.broadcast();
  
  /// 卡片展开进度流
  Stream<double> get expandProgressStream => _expandProgressController.stream;
  
  /// 卡片发光强度流控制器
  final StreamController<double> _glowIntensityController = StreamController<double>.broadcast();
  
  /// 卡片发光强度流
  Stream<double> get glowIntensityStream => _glowIntensityController.stream;
  
  /// 卡片是否展开
  bool _isExpanded = false;
  
  /// 获取卡片是否展开
  bool get isExpanded => _isExpanded;
  
  /// 卡片状态流
  Stream<List<bool>> get cardStateStream => _cardStateController.stream;
  
  /// 中奖卡片索引
  int? _winnerCardIndex;
  
  /// 抽奖结果
  RaffleResult? _result;
  
  /// 获取抽奖结果
  RaffleResult? get result => _result;
  
  /// 构造函数
  LuckyCardRaffleController({
    required super.config,
    List<RaffleItem>? items,
    this.cardCount = 6,
    this.allowManualSelection = true,
    this.selectionDelay = 300,
    Function(RaffleResult)? onRaffleComplete,
  }) : super(items: items, onRaffleComplete: onRaffleComplete) {
    _cardSelected = List.filled(cardCount, false);
  }
  
  @override
  Future<RaffleResult> startRaffle() async {
    if (_animationControllers.isEmpty) {
      throw Exception('Animation controllers not initialized');
    }
    
    // 更新状态为运行中
    updateState(RaffleState.running);
    
    // 选择中奖卡片
    _winnerCardIndex = Random().nextInt(cardCount);
    
    if (allowManualSelection) {
      // 手动选择模式：等待用户点击卡片
      // 抽奖状态保持运行，直到用户选择卡片
      final result = await generateResult();
      _result = result;
      return result;
    } else {
      // 自动选择模式：自动选择卡片
      return await _performAutoSelection();
    }
  }
  
  /// 执行自动选择
  Future<RaffleResult> _performAutoSelection() async {
    // 随机打乱选择顺序
    final selectionOrder = List.generate(cardCount, (index) => index);
    selectionOrder.shuffle();
    
    // 依次选择卡片
    for (int i = 0; i < selectionOrder.length; i++) {
      final cardIndex = selectionOrder[i];
      
      // 延迟选择
      if (i > 0) {
        await Future.delayed(Duration(milliseconds: selectionDelay));
      }
      
      await _selectCard(cardIndex);
      
      // 如果选到中奖卡片，稍作停顿
      if (cardIndex == _winnerCardIndex) {
        await Future.delayed(Duration(milliseconds: selectionDelay * 2));
      }
    }
    
    // 生成抽奖结果
    final result = await generateResult();
    _result = result;
    
    // 更新状态为已完成
    updateState(RaffleState.completed);
    
    return result;
  }
  
  /// 选择指定卡片
  Future<void> _selectCard(int cardIndex) async {
    if (cardIndex < 0 || cardIndex >= cardCount) return;
    if (_cardSelected[cardIndex]) return; // 已经选择过的卡片不能再选择
    
    _cardSelected[cardIndex] = true;
    _cardStateController.add(List.from(_cardSelected));
    
    // 启动选择动画
    await _animationControllers[cardIndex].forward();
    
    // 如果是手动模式且选到中奖卡片，完成抽奖
    if (allowManualSelection && cardIndex == _winnerCardIndex) {
      _completeRaffle();
    }
  }
  
  /// 完成抽奖（手动模式）
  Future<RaffleResult> _completeRaffle() async {
    if (_winnerCardIndex == null) {
      throw Exception('Winner card index not set');
    }
    
    // 生成抽奖结果
    final result = await generateResult();
    _result = result;
    
    // 更新状态为已完成
    updateState(RaffleState.completed);
    
    return result;
  }
  
  /// 停止抽奖
  @override
  Future<void> stopRaffle() async {
    // 如果不在运行状态，直接返回
    if (state != RaffleState.running) return;
    
    // 更新状态为已停止
    updateState(RaffleState.stopped);
  }
  
  /// 手动选择卡片（用于用户交互）
  Future<void> selectCardManually(int cardIndex) async {
    if (state != RaffleState.running || !allowManualSelection) return;
    
    await _selectCard(cardIndex);
    
    // 如果选到中奖卡片，完成抽奖
    if (cardIndex == _winnerCardIndex) {
      await _completeRaffle();
    }
  }
  
  /// 选择卡片（兼容性方法）
  Future<void> selectCard(int cardIndex) async {
    return selectCardManually(cardIndex);
  }
  
  /// 初始化动画控制器
  void initAnimations(TickerProvider vsync) {
    initializeAnimations(vsync);
  }
  
  /// 初始化动画控制器（兼容性方法）
  void initializeAnimations(TickerProvider vsync) {
    // 清除旧的动画控制器
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    _selectionAnimations.clear();
    
    // 为每张卡片创建动画控制器
    for (int i = 0; i < cardCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 500),
        vsync: vsync,
      );
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
      
      _animationControllers.add(controller);
      _selectionAnimations.add(animation);
    }
  }
  
  /// 获取指定卡片的选择动画
  Animation<double>? getSelectionAnimation(int index) {
    if (index < 0 || index >= _selectionAnimations.length) return null;
    return _selectionAnimations[index];
  }
  
  /// 重置所有卡片
  @override
  Future<void> resetRaffle() async {
    // 更新状态为空闲
    updateState(RaffleState.idle);
    
    for (final controller in _animationControllers) {
      controller.reset();
    }
    
    _cardSelected = List.filled(cardCount, false);
    _winnerCardIndex = null;
    _result = null;
    _cardStateController.add(List.from(_cardSelected));
    
    // 重置展开状态
    _isExpanded = false;
    _expandProgressController.add(0.0);
    _glowIntensityController.add(0.0);
    _cardColorController.add(Colors.blue);
  }
  
  /// 重置抽奖（兼容性方法）
  Future<void> reset() async {
    return resetRaffle();
  }
  
  /// 预览抽奖结果（兼容性方法）
  Future<void> preview() async {
    // 模拟抽奖过程，但不改变状态
    final previewItem = selectRandomItem();
    // 从 customData 中获取颜色，如果没有则使用默认颜色
    final cardColor = previewItem.customData?['color'] ?? Colors.blue;
    _cardColorController.add(cardColor);
    _glowIntensityController.add(1.0);
    await Future.delayed(const Duration(milliseconds: 500));
    _glowIntensityController.add(0.0);
  }
  
  /// 释放资源
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _cardStateController.close();
    _cardColorController.close();
    _expandProgressController.close();
    _glowIntensityController.close();
  }
  
  /// 是否是中奖卡片
  bool isWinnerCard(int cardIndex) {
    return cardIndex == _winnerCardIndex && state == RaffleState.completed;
  }
  
  /// 获取指定卡片的内容
  RaffleItem getCardContent(int cardIndex) {
    if (cardIndex == _winnerCardIndex) {
      // 中奖卡片显示中奖项目
      final winnerItem = selectRandomItem();
      return winnerItem;
    } else {
      // 其他卡片随机显示非中奖项目或安慰奖
      final availableItems = config.items.where((item) => item.type != RaffleItemType.grand).toList();
      if (availableItems.isNotEmpty) {
        return availableItems[Random().nextInt(availableItems.length)];
      } else {
        return config.items[Random().nextInt(config.items.length)];
      }
    }
  }
  
  /// 随机选择一个奖品
  RaffleItem selectRandomItem() {
    if (config.items.isEmpty) {
      throw Exception('No raffle items available');
    }
    
    // 计算概率总和
    double totalProbability = config.items.fold(0.0, (sum, item) => sum + item.probability);
    
    // 如果概率总和不为1，进行归一化处理
    List<RaffleItem> normalizedItems = config.items.toList();
    if (totalProbability != 1.0) {
      normalizedItems = config.items.map((item) {
        return item.copyWith(
          probability: item.probability / totalProbability
        );
      }).toList();
    }
    
    // 生成随机数
    double random = Random().nextDouble();
    
    // 根据概率选择奖品
    double cumulativeProbability = 0.0;
    RaffleItem selectedItem = normalizedItems.first; // 默认选择第一个，确保始终有返回值
    
    for (var item in normalizedItems) {
      cumulativeProbability += item.probability;
      if (random <= cumulativeProbability) {
        selectedItem = item;
        break;
      }
    }
    
    return selectedItem;
  }
}