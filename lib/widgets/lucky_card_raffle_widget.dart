import 'package:flutter/material.dart';
import 'package:raffle/models/raffle_state.dart';
import '../controllers/lucky_card_raffle_controller.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';

/// 幸运卡片抽奖组件
/// 实现卡片展开动画的UI界面
class LuckyCardRaffleWidget extends StatefulWidget {
  final LuckyCardRaffleController controller;
  final List<RaffleItem> items;
  final Function(RaffleResult)? onResult;
  final double width;
  final double height;
  
  const LuckyCardRaffleWidget({
    Key? key,
    required this.controller,
    required this.items,
    this.onResult,
    this.width = 350,
    this.height = 400,
  }) : super(key: key);
  
  @override
  State<LuckyCardRaffleWidget> createState() => _LuckyCardRaffleWidgetState();
}

class _LuckyCardRaffleWidgetState extends State<LuckyCardRaffleWidget>
    with TickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    widget.controller.initializeAnimations(this);
    widget.controller.setItems(widget.items);
    
    // 监听抽奖结果
    widget.controller.resultStream.listen((result) {
      if (widget.onResult != null) {
        widget.onResult!(result);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F3460),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题区域
          _buildHeader(),
          
          // 卡片区域
          Expanded(
            child: _buildCardArea(),
          ),
          
          // 控制区域
          _buildControlArea(),
        ],
      ),
    );
  }
  
  /// 构建标题区域
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '幸运卡片',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<String>(
            stream: widget.controller.stateStream.map((state) {
              switch (state) {
                case RaffleState.idle:
                  return '点击开始选择幸运卡片';
                case RaffleState.running:
                  return widget.controller.isExpanded ? '选择一张卡片' : '卡片展开中...';
                case RaffleState.completed:
                  return '恭喜中奖！';
                default:
                  return '';
              }
            }),
            builder: (context, snapshot) {
              return Text(
                snapshot.data ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建卡片区域
  Widget _buildCardArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<double>(
        stream: widget.controller.expandProgressStream,
        builder: (context, expandSnapshot) {
          final expandProgress = expandSnapshot.data ?? 0.0;
          
          return StreamBuilder<double>(
            stream: widget.controller.glowIntensityStream,
            builder: (context, glowSnapshot) {
              final glowIntensity = glowSnapshot.data ?? 0.0;
              
              return _buildCardGrid(expandProgress, glowIntensity);
            },
          );
        },
      ),
    );
  }
  
  /// 构建卡片网格
  Widget _buildCardGrid(double expandProgress, double glowIntensity) {
    final cardCount = widget.controller.cardCount;
    final selectedIndex = widget.controller.selectedCardIndex;
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16 * expandProgress,
      runSpacing: 16 * expandProgress,
      children: List.generate(cardCount, (index) {
        return _buildCard(
          index,
          expandProgress,
          glowIntensity,
          selectedIndex == index,
        );
      }),
    );
  }
  
  /// 构建单个卡片
  Widget _buildCard(
    int index,
    double expandProgress,
    double glowIntensity,
    bool isSelected,
  ) {
    final cardSize = 80.0 + (40.0 * expandProgress);
    final opacity = (0.3 + (0.7 * expandProgress)).clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: () {
        if (widget.controller.isExpanded) {
          widget.controller.selectCard(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardSize,
        height: cardSize * 1.4,
        child: Stack(
          children: [
            // 光晕效果
            if (!isSelected && expandProgress > 0.8)
              _buildGlowEffect(cardSize, glowIntensity),
            
            // 卡片主体
            _buildCardBody(cardSize, opacity, isSelected, index),
            
            // 选中效果
            if (isSelected)
              _buildSelectedEffect(cardSize),
          ],
        ),
      ),
    );
  }
  
  /// 构建光晕效果
  Widget _buildGlowEffect(double cardSize, double glowIntensity) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity((0.3 * glowIntensity).clamp(0.0, 1.0)),
              blurRadius: 20 * glowIntensity,
              spreadRadius: 5 * glowIntensity,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建卡片主体
  Widget _buildCardBody(
    double cardSize,
    double opacity,
    bool isSelected,
    int index,
  ) {
    return StreamBuilder<Color>(
      stream: widget.controller.cardColorStream,
      builder: (context, colorSnapshot) {
        final cardColor = isSelected 
            ? (colorSnapshot.data ?? Colors.blue)
            : Colors.blue;
        
        return Container(
          width: cardSize,
          height: cardSize * 1.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cardColor.withOpacity(opacity),
                cardColor.withOpacity((opacity * 0.7).clamp(0.0, 1.0)),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _buildCardContent(isSelected, index),
        );
      },
    );
  }
  
  /// 构建卡片内容
  Widget _buildCardContent(bool isSelected, int index) {
    if (isSelected && widget.controller.state == RaffleState.completed) {
      // 显示中奖内容
      final result = widget.controller.result;
      if (result != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              color: Colors.yellow,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              result.item.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
    }
    
    // 默认卡片背面
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            color: Colors.white.withOpacity(0.7),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            '?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建选中效果
  Widget _buildSelectedEffect(double cardSize) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.yellow,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.yellow.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建控制区域
  Widget _buildControlArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 状态信息
          StreamBuilder<RaffleState>(
            stream: widget.controller.stateStream,
            builder: (context, snapshot) {
              final state = snapshot.data ?? RaffleState.idle;
              final result = widget.controller.result;
              
              if (state == RaffleState.completed && result != null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.celebration,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '恭喜获得: ${result.item.name}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
          
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                '开始',
                Icons.play_arrow,
                Colors.green,
                () => widget.controller.startRaffle(),
              ),
              _buildControlButton(
                '预览',
                Icons.visibility,
                Colors.blue,
                () => widget.controller.preview(),
              ),
              _buildControlButton(
                '重置',
                Icons.refresh,
                Colors.orange,
                () => widget.controller.reset(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建控制按钮
  Widget _buildControlButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return StreamBuilder<RaffleState>(
      stream: widget.controller.stateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? RaffleState.idle;
        final isEnabled = text == '重置' || state == RaffleState.idle || state == RaffleState.completed;
        
        return ElevatedButton.icon(
          onPressed: isEnabled ? onPressed : null,
          icon: Icon(icon, size: 18),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}