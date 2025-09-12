import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../models/raffle_state.dart';
import 'raffle_controller.dart';

/// 卡片翻转抽奖控制器
class CardFlipRaffleController extends RaffleController {
  /// 卡片数量
  int cardCount;
  
  /// 是否允许手动翻牌
  final bool allowManualFlip;
  
  /// 翻牌延迟（毫秒）
  final int flipDelay;
  
  /// 当前选中的卡片索引
  final int _selectedCardIndex = -1;
  
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
      _cardFlipped = List.filled(cardCount, false);
    }
  }
  
  /// 设置自动模式
  void setAutoMode(bool autoMode) {
    _isAutoMode = autoMode;
  }
  
  /// 每张卡片的动画控制器
  final List<AnimationController> _animationControllers = [];
  
  /// 每张卡片的翻转动画
  final List<Animation<double>> _flipAnimations = [];
  
  /// 每张卡片的当前翻转状态
  List<bool> _cardFlipped = [];
  
  /// 卡片状态流控制器
  final StreamController<List<bool>> _cardStateController = StreamController<List<bool>>.broadcast();
  
  /// 卡片状态流
  Stream<List<bool>> get cardStateStream => _cardStateController.stream;
  
  /// 中奖卡片索引
  int? _winnerCardIndex;
  

  
  CardFlipRaffleController({
    required super.config,
    List<RaffleItem>? items,
    this.cardCount = 6,
    this.allowManualFlip = true,
    this.flipDelay = 300,
    Function(RaffleResult)? onRaffleComplete,
  }) : super(items: items, onRaffleComplete: onRaffleComplete) {
    _cardFlipped = List.filled(cardCount, false);
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
    
    if (allowManualFlip) {
      // 手动翻转模式：等待用户点击卡片
      // 抽奖状态保持运行，直到用户翻开中奖卡片
      final result = await generateResult();
      return result;
    } else {
      // 自动翻转模式：依次翻转所有卡片
      return await _performAutoFlip();
    }
  }
  
  /// 执行自动翻转
  Future<RaffleResult> _performAutoFlip() async {
    // 随机打乱翻转顺序
    final flipOrder = List.generate(cardCount, (index) => index);
    flipOrder.shuffle();
    
    // 依次翻转卡片
    for (int i = 0; i < flipOrder.length; i++) {
      final cardIndex = flipOrder[i];
      
      // 延迟翻转
      if (i > 0) {
        await Future.delayed(Duration(milliseconds: flipDelay));
      }
      
      await _flipCard(cardIndex);
      
      // 如果翻到中奖卡片，稍作停顿
      if (cardIndex == _winnerCardIndex) {
        await Future.delayed(Duration(milliseconds: flipDelay * 2));
      }
    }
    
    // 生成抽奖结果
    final result = await generateResult();
    
    // 更新状态为已完成
    updateState(RaffleState.completed);
    
    return result;
  }
  
  /// 翻转指定卡片
  Future<void> _flipCard(int cardIndex) async {
    if (cardIndex < 0 || cardIndex >= cardCount) return;
    if (_cardFlipped[cardIndex]) return; // 已经翻转过的卡片不能再翻转
    
    _cardFlipped[cardIndex] = true;
    _cardStateController.add(List.from(_cardFlipped));
    
    // 启动翻转动画
    await _animationControllers[cardIndex].forward();
    
    // 如果是手动模式且翻到中奖卡片，完成抽奖
    if (allowManualFlip && cardIndex == _winnerCardIndex) {
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
  
  /// 手动翻转卡片（用于用户交互）
  Future<void> flipCardManually(int cardIndex) async {
    if (state != RaffleState.running || !allowManualFlip) return;
    
    await _flipCard(cardIndex);
    
    // 如果翻到中奖卡片，完成抽奖
    if (cardIndex == _winnerCardIndex) {
      await _completeRaffle();
    }
  }
  
  /// 初始化动画控制器
  void initializeAnimations(TickerProvider vsync) {
    _animationControllers.clear();
    _flipAnimations.clear();
    
    for (int i = 0; i < cardCount; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600),
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
      _flipAnimations.add(animation);
    }
  }
  
  /// 重置所有卡片
  @override
  Future<void> resetRaffle() async {
    // 更新状态为空闲
    updateState(RaffleState.idle);
    
    for (final controller in _animationControllers) {
      controller.reset();
    }
    
    _cardFlipped = List.filled(cardCount, false);
    _winnerCardIndex = null;
    _cardStateController.add(List.from(_cardFlipped));
  }
  
  /// 获取指定卡片的翻转动画
  Animation<double>? getFlipAnimation(int cardIndex) {
    if (cardIndex >= 0 && cardIndex < _flipAnimations.length) {
      return _flipAnimations[cardIndex];
    }
    return null;
  }
  
  /// 检查卡片是否已翻转
  bool isCardFlipped(int cardIndex) {
    if (cardIndex >= 0 && cardIndex < _cardFlipped.length) {
      return _cardFlipped[cardIndex];
    }
    return false;
  }
  
  /// 检查是否为中奖卡片
  bool isWinnerCard(int cardIndex) {
    return _winnerCardIndex == cardIndex;
  }
  
  /// 获取中奖卡片索引
  int? get winnerCardIndex => _winnerCardIndex;
  
  /// 获取已翻转的卡片数量
  int get flippedCardCount => _cardFlipped.where((flipped) => flipped).length;
  
  /// 检查是否所有卡片都已翻转
  bool get allCardsFlipped => _cardFlipped.every((flipped) => flipped);
  
  /// 获取指定卡片的内容
  RaffleItem getCardContent(int cardIndex) {
    if (cardIndex == _winnerCardIndex) {
      // 中奖卡片显示中奖项目
      final winnerItem = selectRandomItem();
      return winnerItem;
    } else {
      // 其他卡片随机显示非中奖项目或安慰奖
      final availableItems = items.where((item) => item.type != RaffleItemType.grand).toList();
      if (availableItems.isNotEmpty) {
        return availableItems[Random().nextInt(availableItems.length)];
      } else {
        return items[Random().nextInt(items.length)];
      }
    }
  }
  
  /// 强制翻转所有卡片（用于调试）
  Future<void> flipAllCards() async {
    if (state == RaffleState.running) {
      for (int i = 0; i < cardCount; i++) {
        if (!_cardFlipped[i]) {
          await _flipCard(i);
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    }
  }
  
  @override
  void dispose() {
    for (final controller in _animationControllers) {
      controller.dispose();
    }
    _cardStateController.close();
    super.dispose();
  }
  
  /// 重置抽奖（兼容性方法）
  /// 调用resetRaffle方法
  Future<void> reset() async {
    return resetRaffle();
  }
}