import 'package:flutter/material.dart';
import 'package:raffle/raffle.dart';

/// 抽奖组件演示页面
/// 展示所有抽奖组件的使用方法
class RaffleDemoPage extends StatefulWidget {
  const RaffleDemoPage({Key? key}) : super(key: key);
  
  @override
  State<RaffleDemoPage> createState() => _RaffleDemoPageState();
}

class _RaffleDemoPageState extends State<RaffleDemoPage> {
  int _currentIndex = 0;
  
  // 示例抽奖物品
  final List<RaffleItem> _sampleItems = [
    RaffleItem(
      id: '1',
      name: '一等奖',
      description: 'iPhone 15 Pro',
      weight: 1,
      type: RaffleItemType.grand,
      imageUrl: 'https://example.com/iphone.png',
      value: 8999.0,
    ),
    RaffleItem(
      id: '2',
      name: '二等奖',
      description: 'iPad Air',
      weight: 5,
      type: RaffleItemType.first,
      imageUrl: 'https://example.com/ipad.png',
      value: 4999.0,
    ),
    RaffleItem(
      id: '3',
      name: '三等奖',
      description: 'AirPods Pro',
      weight: 10,
      type: RaffleItemType.second,
      imageUrl: 'https://example.com/airpods.png',
      value: 1999.0,
    ),
    RaffleItem(
      id: '4',
      name: '四等奖',
      description: '小米手环',
      weight: 20,
      type: RaffleItemType.third,
      imageUrl: 'https://example.com/band.png',
      value: 299.0,
    ),
    RaffleItem(
      id: '5',
      name: '五等奖',
      description: '充电宝',
      weight: 30,
      type: RaffleItemType.consolation,
      imageUrl: 'https://example.com/powerbank.png',
      value: 99.0,
    ),
    RaffleItem(
      id: '6',
      name: '谢谢参与',
      description: '下次再来',
      weight: 34,
      type: RaffleItemType.thanks,
      imageUrl: 'https://example.com/thanks.png',
      value: 0.0,
    ),
  ];
  
  /// 抽奖组件列表
  /// 包含所有可用的抽奖组件类型及其描述信息
  /// 每个组件包含名称、描述、图标和颜色
  final List<Map<String, dynamic>> _raffleTypes = [
    {
      'name': '九宫格抽奖',
      'description': '经典九宫格，光点跑动效果',
      'icon': Icons.grid_3x3,
      'color': Colors.blue,
    },
    {
      'name': '大转盘抽奖',
      'description': '旋转转盘，指针指向中奖',
      'icon': Icons.donut_large,
      'color': Colors.orange,
    },
    {
      'name': '数字滚动',
      'description': '老虎机式数字滚动',
      'icon': Icons.casino,
      'color': Colors.red,
    },
    {
      'name': '刮刮卡',
      'description': '手势刮开涂层',
      'icon': Icons.touch_app,
      'color': Colors.green,
    },
    {
      'name': '卡片翻转',
      'description': '3D翻转动画效果',
      'icon': Icons.flip,
      'color': Colors.purple,
    },
    {
      'name': '扭蛋机',
      'description': '扭蛋掉落动画',
      'icon': Icons.sports_baseball,
      'color': Colors.teal,
    },
    {
      'name': '砸金蛋',
      'description': '敲击交互破蛋',
      'icon': Icons.egg,
      'color': Colors.amber,
    },
    {
      'name': '幸运卡片',
      'description': '卡片展开动画',
      'icon': Icons.style,
      'color': Colors.indigo,
    },
  ];
  
  /// 构建页面主体
  /// @param context 构建上下文
  /// @return 构建的Widget树
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('抽奖组件演示'), // 页面标题
        backgroundColor: _raffleTypes[_currentIndex]['color'], // 根据当前选中的组件类型设置颜色
        foregroundColor: Colors.white, // 前景色为白色
      ),
      body: Column(
        children: [
          // 组件选择器 - 水平滚动的抽奖类型列表
          _buildTypeSelector(),
          
          // 抽奖组件展示区域 - 展示当前选中的抽奖组件
          Expanded(
            child: _buildRaffleWidget(),
          ),
        ],
      ),
    );
  }
  
  /// 构建抽奖类型选择器
  /// 水平滚动的卡片列表，用于选择不同的抽奖组件类型
  /// @return 类型选择器Widget
  Widget _buildTypeSelector() {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _raffleTypes.length,
        itemBuilder: (context, index) {
          final type = _raffleTypes[index];
          final isSelected = index == _currentIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIndex = index;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? type['color'] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: type['color'].withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'],
                    size: 32,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  /// 构建抽奖组件
  Widget _buildRaffleWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: _getRaffleWidget(_currentIndex),
      ),
    );
  }
  
  /// 获取对应的抽奖组件
  Widget _getRaffleWidget(int index) {
    switch (index) {
      case 0:
        return _buildGridRaffle();
      case 1:
        return _buildWheelRaffle();
      case 2:
        return _buildSlotRaffle();
      case 3:
        return _buildScratchRaffle();
      case 4:
        return _buildCardFlipRaffle();
      case 5:
        return _buildGashaponRaffle();
      case 6:
        return _buildGoldenEggRaffle();
      case 7:
        return _buildLuckyCardRaffle();
      default:
        return const Text('未知组件');
    }
  }
  
  /// 九宫格抽奖
  Widget _buildGridRaffle() {
    final config = RaffleConfig.grid(items: _sampleItems);
    
    return GridRaffleWidget(
      config: config,
      items: _sampleItems,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 大转盘抽奖
  Widget _buildWheelRaffle() {
    final config = RaffleConfig.wheel(items: _sampleItems);
    
    return WheelRaffleWidget(
      config: config,
      items: _sampleItems,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 数字滚动抽奖
  Widget _buildSlotRaffle() {
    final config = RaffleConfig.slot(items: _sampleItems);
    
    return SlotRaffleWidget(
      config: config,
      items: _sampleItems,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 刮刮卡抽奖
  Widget _buildScratchRaffle() {
    final config = RaffleConfig.scratch(items: _sampleItems);
    
    return ScratchRaffleWidget(
      config: config,
      items: _sampleItems,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 卡片翻转抽奖
  Widget _buildCardFlipRaffle() {
    final config = RaffleConfig(
      type: RaffleType.flip,
      primaryColor: Colors.purple,
      items: _sampleItems,
    );
    final controller = CardFlipRaffleController(config: config, items: _sampleItems);
    
    return CardFlipRaffleWidget(
      controller: controller,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 扭蛋机抽奖
  Widget _buildGashaponRaffle() {
    final config = RaffleConfig(
      type: RaffleType.gashapon,
      primaryColor: Colors.pink,
      items: _sampleItems,
    );
    final controller = GashaponRaffleController(config: config, items: _sampleItems);
    
    return GashaponRaffleWidget(
      controller: controller,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 砸金蛋抽奖
  Widget _buildGoldenEggRaffle() {
    final config = RaffleConfig(
      type: RaffleType.egg,
      primaryColor: Colors.amber,
      items: _sampleItems,
    );
    
    return GoldenEggRaffleWidget(
      config: config,
      items: _sampleItems,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 幸运卡片抽奖
  Widget _buildLuckyCardRaffle() {
    final config = RaffleConfig(
      type: RaffleType.card,
      primaryColor: Colors.teal,
      items: _sampleItems,
    );
    final controller = LuckyCardRaffleController(config: config, items: _sampleItems);
    
    return LuckyCardRaffleWidget(
      controller: controller,
      items: _sampleItems,
      onResult: (result) {
        _showResultDialog(result);
      },
    );
  }
  
  /// 显示抽奖结果对话框
  void _showResultDialog(RaffleResult? result) {
    if (result == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('抽奖结果'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '恭喜您获得：',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.prize.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.prize.description ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if ((result.prize.value ?? 0) > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '价值：¥${(result.prize.value ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '抽奖时间：${_formatDateTime(result.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  /// 格式化日期时间
  String _formatDateTime(int timestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}