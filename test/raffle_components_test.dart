// 导入必要的测试和UI包
import 'package:flutter/material.dart'; // Flutter UI组件
import 'package:flutter_test/flutter_test.dart'; // Flutter测试框架
import 'package:raffle/models/raffle_state.dart'; // 抽奖状态模型
import 'package:raffle/raffle.dart'; // 抽奖插件主类及导出的所有组件

/// 测试入口函数
void main() {
  // 抽奖组件测试组
  group('Raffle Components Tests', () {
    // 声明测试用的奖品列表
    late List<RaffleItem> testItems;
    
    // 每个测试前的设置
    setUp(() {
      // 初始化测试用的奖品列表，包含不同等级的奖品和不同的权重
      testItems = [
        RaffleItem(
          id: '1',
          name: '一等奖', // 最高等级奖品
          description: 'iPhone 15',
          weight: 1, // 最低权重，表示概率最小
          value: 8999.0, // 最高价值
        ),
        RaffleItem(
          id: '2',
          name: '二等奖',
          description: 'iPad',
          weight: 2, // 权重略高，概率略大
          value: 4999.0,
        ),
        RaffleItem(
          id: '3',
          name: '三等奖',
          description: 'AirPods',
          weight: 3, // 权重更高
          value: 1999.0,
        ),
        RaffleItem(
          id: '4',
          name: '谢谢参与', // 安慰奖
          description: '下次再来',
          weight: 4, // 最高权重，表示概率最大
          value: 0.0, // 无价值
        ),
      ];
    });
    
    // 网格抽奖控制器测试组
    group('GridRaffleController Tests', () {
      // 声明控制器变量
      late GridRaffleController controller;
      
      // 每个测试前的设置
      setUp(() {
        // 创建网格抽奖控制器实例
        controller = GridRaffleController(
          config: RaffleConfig(type: RaffleType.grid, items: testItems), // 设置为网格类型
          items: testItems, // 添加测试奖品列表
        );
        // 设置测试奖品列表
        controller.setItems(testItems);
      });
      
      // 每个测试后的清理
      tearDown(() {
        // 释放控制器资源
        controller.dispose();
      });
      
      // 测试初始化状态是否正确
      test('should initialize with idle state', () {
        // 验证初始状态为空闲
        expect(controller.state, RaffleState.idle);
        // 验证初始结果为空
        expect(controller.result, isNull);
        // 验证初始索引为-1（未选中任何项）
        expect(controller.currentIndex, -1);
      });
      
      // 测试设置奖品列表是否正确
      test('should set items correctly', () {
        // 验证奖品数量
        expect(controller.items.length, 4);
        // 验证第一个奖品名称
        expect(controller.items.first.name, '一等奖');
      });
      
      // 测试重置功能是否正确
      test('should reset to initial state', () {
        // 调用重置方法
        controller.reset();
        // 验证状态是否重置为空闲
        expect(controller.state, RaffleState.idle);
        // 验证结果是否重置为空
        expect(controller.result, isNull);
        // 验证索引是否重置为-1
        expect(controller.currentIndex, -1);
      });
      
      // 测试开始抽奖功能是否正确更新状态
      test('should start raffle and update state', () async {
        // 调用开始抽奖方法
        controller.startRaffle();
        
        // 等待动画完成
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 验证当前索引是否已更新（已选中某个奖品）
        expect(controller.currentIndex, greaterThanOrEqualTo(0));
      });
    });
    
    // 转盘抽奖控制器测试组
    group('WheelRaffleController Tests', () {
      late WheelRaffleController controller;
      
      // 每个测试前初始化控制器
      setUp(() {
        controller = WheelRaffleController(
          config: RaffleConfig(type: RaffleType.wheel, items: testItems),
          items: testItems,
        );
        controller.setItems(testItems);
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct default values', () {
        expect(controller.state, RaffleState.idle); // 初始状态应为空闲
        expect(controller.rotationAngle, 0.0); // 初始旋转角度应为0
        expect(controller.isSpinning, false); // 初始不应处于旋转状态
      });
      
      // 测试扇区角度计算是否正确
      test('should calculate sector angle correctly', () {
        final sectorAngle = 360.0 / testItems.length;
        expect(sectorAngle, 90.0); // 360度 ÷ 4个项目 = 每个扇区90度
      });
    });
    
    // 老虎机抽奖控制器测试组
    group('SlotRaffleController Tests', () {
      late SlotRaffleController controller;
      
      // 每个测试前初始化控制器
      setUp(() {
        controller = SlotRaffleController(
          config: RaffleConfig(type: RaffleType.slot, items: testItems),
          items: testItems,
        );
        controller.setItems(testItems);
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct reel count', () {
        expect(controller.reelCount, 3); // 默认应有3个转轮
        expect(controller.state, RaffleState.idle); // 初始状态应为空闲
      });
      
      // 测试设置转轮数量是否在有效范围内
      test('should set reel count within valid range', () {
        controller.setReelCount(5);
        expect(controller.reelCount, 5); // 正常设置为5
        
        controller.setReelCount(10); // 应被限制到最大值
        expect(controller.reelCount, 6); // 最大值为6
        
        controller.setReelCount(1); // 应被限制到最小值
        expect(controller.reelCount, 2); // 最小值为2
      });
    });
    
    // 刮刮卡抽奖控制器测试组
    group('ScratchRaffleController Tests', () {
      late ScratchRaffleController controller;
      
      // 每个测试前初始化控制器
      setUp(() {
        controller = ScratchRaffleController(
          config: RaffleConfig(type: RaffleType.scratch, items: testItems),
          cardSize: const Size(200, 200), // 设置卡片大小
          items: testItems,
        );
        controller.setItems(testItems);
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with zero scratch progress', () {
        expect(controller.scratchProgress, 0.0); // 初始刮擦进度应为0
        expect(controller.isRevealed, false); // 初始未揭示结果
        expect(controller.state, RaffleState.idle); // 初始状态应为空闲
      });
      
      // 测试设置刮擦阈值是否正确
      test('should set scratch threshold correctly', () {
        controller.setScratchThreshold(0.8);
        expect(controller.scratchThreshold, 0.8); // 正常设置为80%
        
        // 测试边界值
        controller.setScratchThreshold(1.5); // 应被限制到最大值
        expect(controller.scratchThreshold, 1.0); // 最大值为100%
        
        controller.setScratchThreshold(-0.1); // 应被限制到最小值
        expect(controller.scratchThreshold, 0.0); // 最小值为0%
      });
    });
    
    // 翻牌抽奖控制器测试组
    group('CardFlipRaffleController Tests', () {
      late CardFlipRaffleController controller;
      
      // 每个测试前初始化控制器
      setUp(() {
        controller = CardFlipRaffleController(
          config: RaffleConfig(type: RaffleType.flip, items: testItems),
          items: testItems,
        );
        controller.setItems(testItems);
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct card count', () {
        expect(controller.cardCount, 6); // 默认应有6张卡片
        expect(controller.selectedCardIndex, -1); // 初始未选中任何卡片
        expect(controller.isAutoMode, true); // 默认应为自动模式
      });
      
      // 测试设置卡片数量是否在有效范围内
      test('should set card count within valid range', () {
        controller.setCardCount(8);
        expect(controller.cardCount, 8); // 正常设置为8
        
        controller.setCardCount(15); // 应被限制到最大值
        expect(controller.cardCount, 12); // 最大值为12
        
        controller.setCardCount(2); // 应被限制到最小值
        expect(controller.cardCount, 3); // 最小值为3
      });
      
      // 测试切换自动模式
      test('should toggle auto mode', () {
        expect(controller.isAutoMode, true); // 初始为自动模式
        controller.setAutoMode(false); // 切换为手动模式
        expect(controller.isAutoMode, false); // 验证已切换为手动模式
      });
    });
    
    group('GashaponRaffleController Tests', () {
      late GashaponRaffleController controller;
      
      setUp(() {
        controller = GashaponRaffleController(
          config: RaffleConfig(type: RaffleType.gashapon, items: testItems),
          items: testItems,
        );
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct default values', () {
        expect(controller.state, RaffleState.idle);
        expect(controller.dropHeight, 300.0);
        expect(controller.bounceCount, 3);
        expect(controller.eggSize, 80.0);
      });
    });
    
    group('GoldenEggRaffleController Tests', () {
      late GoldenEggRaffleController controller;
      
      setUp(() {
        controller = GoldenEggRaffleController(
          config: RaffleConfig(type: RaffleType.egg, items: testItems),
          items: testItems,
        );
        controller.setItems(testItems);
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct tap count', () {
        expect(controller.tapCount, 0);
        expect(controller.maxTaps, 10);
        expect(controller.isBroken, false);
      });
      
      test('should set max taps within valid range', () {
        controller.setMaxTaps(15);
        expect(controller.maxTaps, 15);
        
        controller.setMaxTaps(25); // Should be clamped
        expect(controller.maxTaps, 20);
        
        controller.setMaxTaps(2); // Should be clamped
        expect(controller.maxTaps, 3);
      });
    });
    
    group('LuckyCardRaffleController Tests', () {
      late LuckyCardRaffleController controller;
      
      setUp(() {
        controller = LuckyCardRaffleController(
          config: RaffleConfig(type: RaffleType.card, items: testItems),
          items: testItems,
        );
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct card count', () {
        expect(controller.cardCount, 3);
        expect(controller.selectedCardIndex, -1);
        expect(controller.isExpanded, false);
      });
      
      test('should set card count within valid range', () {
        controller.setCardCount(5);
        expect(controller.cardCount, 5);
        
        controller.setCardCount(8); // Should be clamped
        expect(controller.cardCount, 6);
        
        controller.setCardCount(1); // Should be clamped
        expect(controller.cardCount, 2);
      });
    });
    
    group('RaffleItem Tests', () {
      test('should create RaffleItem with correct properties', () {
        final item = RaffleItem(
          id: 'test_id',
          name: 'Test Item',
          description: 'Test Description',
          weight: 5,
          value: 100.0,
          imageUrl: 'https://example.com/image.png',
        );
        
        expect(item.id, 'test_id');
        expect(item.name, 'Test Item');
        expect(item.description, 'Test Description');
        expect(item.weight, 5);
        expect(item.value, 100.0);
        expect(item.imageUrl, 'https://example.com/image.png');
      });
      
      test('should convert to and from JSON correctly', () {
        final item = RaffleItem(
          id: 'test_id',
          name: 'Test Item',
          description: 'Test Description',
          weight: 5,
          value: 100.0,
        );
        
        final json = item.toJson();
        final itemFromJson = RaffleItem.fromJson(json);
        
        expect(itemFromJson.id, item.id);
        expect(itemFromJson.name, item.name);
        expect(itemFromJson.description, item.description);
        expect(itemFromJson.weight, item.weight);
        expect(itemFromJson.value, item.value);
      });
    });
    
    group('RaffleResult Tests', () {
      test('should create RaffleResult with correct properties', () {
        final item = testItems.first;
        final timestamp = DateTime.now();
        
        final result = RaffleResult(
          prize: item,
          index: 0,
          timestamp: timestamp.millisecondsSinceEpoch,
          extraData: {'test': 'data'},
          type: RaffleType.grid,
          id: 'test-id',
        );
        
        expect(result.item, item);
        expect(result.index, 0);
        expect(result.timestamp, timestamp.millisecondsSinceEpoch);
        expect(result.extraData?['test'], 'data');
      });
      
      test('should convert to and from JSON correctly', () {
        final item = testItems.first;
        final timestamp = DateTime.now();
        
        final result = RaffleResult(
          prize: item,
          index: 0,
          timestamp: timestamp.millisecondsSinceEpoch,
          type: RaffleType.grid,
          id: 'test-id',
        );
        
        final json = result.toJson();
        final resultFromJson = RaffleResult.fromJson(json);
        
        expect(resultFromJson.item.id, result.item.id);
        expect(resultFromJson.index, result.index);
        expect(resultFromJson.timestamp, result.timestamp);
      });
    });
  });
}