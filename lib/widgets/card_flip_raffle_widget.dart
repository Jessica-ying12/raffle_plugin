import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/card_flip_raffle_controller.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';

/// 卡片翻转抽奖组件
class CardFlipRaffleWidget extends StatefulWidget {
  /// 抽奖控制器
  final CardFlipRaffleController controller;
  
  /// 卡片背景颜色
  final Color cardBackColor;
  
  /// 卡片正面颜色
  final Color cardFrontColor;
  
  /// 中奖卡片颜色
  final Color winnerCardColor;
  
  /// 卡片圆角
  final double cardRadius;
  
  /// 卡片间距
  final double cardSpacing;
  
  /// 结果回调
  final Function(RaffleResult)? onResult;
  
  /// 状态变化回调
  final Function(String)? onStateChanged;
  
  const CardFlipRaffleWidget({
    Key? key,
    required this.controller,
    this.cardBackColor = const Color(0xFF4A90E2),
    this.cardFrontColor = const Color(0xFFFFFFFF),
    this.winnerCardColor = const Color(0xFFFFD700),
    this.cardRadius = 12.0,
    this.cardSpacing = 8.0,
    this.onResult,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<CardFlipRaffleWidget> createState() => _CardFlipRaffleWidgetState();
}

class _CardFlipRaffleWidgetState extends State<CardFlipRaffleWidget>
    with TickerProviderStateMixin {
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    widget.controller.initializeAnimations(this);
    
    // 监听抽奖结果
    widget.controller.resultStream.listen((result) {
      widget.onResult?.call(result);
    });
    
    // 监听状态变化
    widget.controller.stateStream.listen((state) {
      widget.onStateChanged?.call(state.toString().split('.').last);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 卡片区域
        Expanded(
          child: _buildCardGrid(),
        ),
        
        const SizedBox(height: 24),
        
        // 控制按钮
        _buildControlButtons(),
        
        const SizedBox(height: 16),
        
        // 状态信息
        _buildStatusInfo(),
      ],
    );
  }
  
  /// 构建卡片网格
  Widget _buildCardGrid() {
    return StreamBuilder<List<bool>>(
      stream: widget.controller.cardStateStream,
      initialData: List.filled(widget.controller.cardCount, false),
      builder: (context, snapshot) {
        final cardStates = snapshot.data ?? [];
        
        return GridView.builder(
          padding: EdgeInsets.all(widget.cardSpacing),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(),
            crossAxisSpacing: widget.cardSpacing,
            mainAxisSpacing: widget.cardSpacing,
            childAspectRatio: 0.75,
          ),
          itemCount: widget.controller.cardCount,
          itemBuilder: (context, index) {
            return _buildCard(index, cardStates);
          },
        );
      },
    );
  }
  
  /// 获取网格列数
  int _getCrossAxisCount() {
    switch (widget.controller.cardCount) {
      case 4:
        return 2;
      case 6:
        return 3;
      case 9:
        return 3;
      default:
        return 2;
    }
  }
  
  /// 构建单张卡片
  Widget _buildCard(int index, List<bool> cardStates) {
    final animation = widget.controller.getFlipAnimation(index);
    
    if (animation == null) {
      return const SizedBox();
    }
    
    return GestureDetector(
      onTap: () => _onCardTap(index),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final isShowingFront = animation.value >= 0.5;
          
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(animation.value * pi),
            child: isShowingFront
                ? _buildCardFront(index)
                : _buildCardBack(index),
          );
        },
      ),
    );
  }
  
  /// 构建卡片背面
  Widget _buildCardBack(int index) {
    return Container(
      decoration: BoxDecoration(
        color: widget.cardBackColor,
        borderRadius: BorderRadius.circular(widget.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 48,
              color: Colors.white.withOpacity(0.8),
            ),
            const SizedBox(height: 8),
            Text(
              '?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建卡片正面
  Widget _buildCardFront(int index) {
    final isWinner = widget.controller.isWinnerCard(index);
    final cardContent = widget.controller.getCardContent(index);
    
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(pi),
      child: Container(
        decoration: BoxDecoration(
          color: isWinner ? widget.winnerCardColor : widget.cardFrontColor,
          borderRadius: BorderRadius.circular(widget.cardRadius),
          border: Border.all(
            color: isWinner ? Colors.orange : Colors.grey.shade300,
            width: isWinner ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isWinner 
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isWinner ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 奖品图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isWinner ? Colors.orange : Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getItemIcon(cardContent.type),
                color: Colors.white,
                size: 24,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 奖品名称
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                cardContent.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color: isWinner ? Colors.orange.shade800 : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // 中奖标识
            if (isWinner) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '中奖',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// 获取奖品类型对应的图标
  IconData _getItemIcon(RaffleItemType type) {
    switch (type) {
      case RaffleItemType.grand:
        return Icons.emoji_events;
      case RaffleItemType.first:
        return Icons.star;
      case RaffleItemType.second:
        return Icons.favorite;
      case RaffleItemType.third:
        return Icons.thumb_up;
      case RaffleItemType.consolation:
        return Icons.card_giftcard;
      case RaffleItemType.thanks:
        return Icons.close;
      case RaffleItemType.normal:
        return Icons.card_membership;
    }
  }
  
  /// 处理卡片点击
  void _onCardTap(int index) {
    if (widget.controller.allowManualFlip) {
      widget.controller.flipCardManually(index);
    }
  }
  
  /// 构建控制按钮
  Widget _buildControlButtons() {
    return StreamBuilder<String>(
      stream: widget.controller.stateStream.map((state) => state.toString().split('.').last),
      initialData: 'idle',
      builder: (context, snapshot) {
        final state = snapshot.data ?? 'idle';
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 开始抽奖按钮
            ElevatedButton(
              onPressed: state == 'idle' ? () => widget.controller.startRaffle() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '开始抽奖',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            
            // 重置按钮
            ElevatedButton(
              onPressed: state != 'running' ? () => widget.controller.reset() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '重置',
                style: TextStyle(fontSize: 16),
              ),
            ),
            
            // 翻开所有卡片按钮（调试用）
            if (widget.controller.allowManualFlip && state == 'running')
              ElevatedButton(
                onPressed: () => widget.controller.flipAllCards(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '全部翻开',
                  style: TextStyle(fontSize: 14),
                ),
              ),
          ],
        );
      },
    );
  }
  
  /// 构建状态信息
  Widget _buildStatusInfo() {
    return StreamBuilder<String>(
      stream: widget.controller.stateStream.map((state) => state.toString().split('.').last),
      initialData: 'idle',
      builder: (context, snapshot) {
        final state = snapshot.data ?? 'idle';
        
        return StreamBuilder<List<bool>>(
          stream: widget.controller.cardStateStream,
          initialData: List.filled(widget.controller.cardCount, false),
          builder: (context, cardSnapshot) {
            final flippedCount = widget.controller.flippedCardCount;
            
            String statusText;
            Color statusColor;
            
            switch (state) {
              case 'idle':
                statusText = '点击"开始抽奖"开始游戏';
                statusColor = Colors.grey;
                break;
              case 'running':
                if (widget.controller.allowManualFlip) {
                  statusText = '点击卡片翻开查看奖品 ($flippedCount/${widget.controller.cardCount})';
                } else {
                  statusText = '正在自动翻转卡片...';
                }
                statusColor = Colors.blue;
                break;
              case 'completed':
                statusText = '抽奖完成！';
                statusColor = Colors.green;
                break;
              default:
                statusText = '未知状态';
                statusColor = Colors.red;
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}