# Flutter 抽奖插件 (Raffle Plugin)

一个功能丰富的 Flutter 抽奖插件，提供多种抽奖组件和动画效果。

## 功能特性

### 🎯 抽奖组件
- **九宫格抽奖** - 经典九宫格布局，光点跑动动画
- **大转盘抽奖** - 旋转转盘，指针指向中奖位置
- **数字滚动抽奖** - 老虎机式数字滚动效果
- **刮刮卡抽奖** - 手势刮开涂层交互
- **卡片翻转抽奖** - 3D翻转动画效果
- **扭蛋机抽奖** - 扭蛋掉落动画
- **砸金蛋抽奖** - 敲击交互破蛋效果
- **幸运卡片抽奖** - 卡片展开动画

### ✨ 动画效果
- 流畅的动画过渡
- 丰富的视觉反馈
- 自定义动画参数
- 响应式交互设计

### 🔧 功能支持
- 概率控制
- 结果回调
- 状态管理
- 自定义样式
- 音效震动（平台相关）

## 安装

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  raffle:
    git:
      url: https://github.com/Jessica-ying12/raffle_plugin.git
```

然后运行：

```bash
flutter pub get
```

## 快速开始

### 1. 导入插件

```dart
import 'package:raffle/raffle.dart';
```

### 2. 创建抽奖物品

```dart
final List<RaffleItem> items = [
  RaffleItem(
    id: '1',
    name: '一等奖',
    description: 'iPhone 15 Pro',
    probability: 0.01,
    value: 8999.0,
    imageUrl: 'https://example.com/iphone.png',
  ),
  RaffleItem(
    id: '2',
    name: '二等奖',
    description: 'iPad Air',
    probability: 0.05,
    value: 4999.0,
  ),
  // 更多物品...
];
```

### 3. 使用抽奖组件

#### 九宫格抽奖

```dart
class GridRaffleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = GridRaffleController();
    
    return GridRaffleWidget(
      controller: controller,
      items: items,
      onResult: () {
        final result = controller.result;
        print('中奖结果: ${result?.winningItem.name}');
      },
    );
  }
}
```

#### 大转盘抽奖

```dart
class WheelRaffleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = WheelRaffleController();
    
    return WheelRaffleWidget(
      controller: controller,
      items: items,
      onResult: () {
        final result = controller.result;
        print('中奖结果: ${result?.winningItem.name}');
      },
    );
  }
}
```

#### 刮刮卡抽奖

```dart
class ScratchRaffleExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = ScratchRaffleController();
    
    return ScratchRaffleWidget(
      controller: controller,
      items: items,
      onResult: () {
        final result = controller.result;
        print('中奖结果: ${result?.winningItem.name}');
      },
    );
  }
}
```

## 详细使用说明

### 控制器方法

所有抽奖控制器都继承自 `RaffleController`，提供以下通用方法：

```dart
// 开始抽奖
await controller.startRaffle();

// 重置状态
await controller.reset();

// 设置抽奖物品
controller.setItems(items);

// 监听状态变化
controller.stateStream.listen((state) {
  print('当前状态: $state');
});

// 监听结果变化
controller.resultStream.listen((result) {
  if (result != null) {
    print('中奖物品: ${result.winningItem.name}');
  }
});
```

### 自定义配置

#### 九宫格抽奖配置

```dart
final controller = GridRaffleController();

// 设置跑动速度
controller.setRunSpeed(200); // 毫秒

// 设置最小跑动圈数
controller.setMinRounds(3);
```

#### 大转盘抽奖配置

```dart
final controller = WheelRaffleController();

// 设置旋转持续时间
controller.setSpinDuration(Duration(seconds: 3));

// 启用手势控制
controller.enableGestureControl(true);
```

#### 刮刮卡配置

```dart
final controller = ScratchRaffleController();

// 设置刮开阈值（0.0-1.0）
controller.setScratchThreshold(0.7);
```

### 样式自定义

大部分组件支持自定义尺寸和样式：

```dart
GridRaffleWidget(
  controller: controller,
  items: items,
  width: 300,
  height: 300,
  // 其他自定义参数
)
```

## 示例应用

查看 `example` 目录中的完整示例应用，展示了所有抽奖组件的使用方法。

运行示例：

```bash
cd example
flutter run
```

## API 文档

### RaffleItem

抽奖物品模型：

```dart
class RaffleItem {
  final String id;           // 唯一标识
  final String name;         // 物品名称
  final String description;  // 物品描述
  final double probability;  // 中奖概率 (0.0-1.0)
  final double value;        // 物品价值
  final String? imageUrl;    // 图片URL
  final Map<String, dynamic>? metadata; // 额外数据
}
```

### RaffleResult

抽奖结果模型：

```dart
class RaffleResult {
  final RaffleItem winningItem;    // 中奖物品
  final int winningIndex;          // 中奖索引
  final DateTime timestamp;        // 抽奖时间
  final Map<String, dynamic>? additionalData; // 额外数据
}
```

### RaffleState

抽奖状态枚举：

```dart
enum RaffleState {
  idle,      // 空闲状态
  running,   // 运行中
  completed, // 已完成
}
```

## 平台支持

| 平台 | 支持状态 | 备注 |
|------|----------|------|
| Android | ✅ | 完全支持 |

注：本插件仅支持Android平台，提供完整的音效和震动功能支持。

## 测试

运行测试：

```bash
flutter test
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 更新日志

### v1.0.0
- 初始版本发布
- 支持 8 种抽奖组件
- 完整的动画效果
- 跨平台支持

