import 'package:flutter/material.dart';
import 'package:raffle/models/raffle_state.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../controllers/slot_raffle_controller.dart';

/// 数字滚动抽奖组件
class SlotRaffleWidget extends StatefulWidget {
  /// 抽奖项目列表
  final List<RaffleItem> items;

  /// 抽奖配置
  final RaffleConfig config;

  /// 抽奖结果回调
  final Function(RaffleResult)? onResult;

  /// 抽奖开始回调
  final VoidCallback? onStart;

  /// 抽奖停止回调
  final VoidCallback? onStop;

  /// 滚轮数量
  final int reelCount;

  /// 组件宽度
  final double width;

  /// 组件高度
  final double height;

  /// 项目高度
  final double itemHeight;

  /// 可见项目数量
  final int visibleItemCount;

  /// 是否显示开始按钮
  final bool showStartButton;

  /// 开始按钮文本
  final String startButtonText;

  const SlotRaffleWidget({
    Key? key,
    required this.items,
    required this.config,
    this.onResult,
    this.onStart,
    this.onStop,
    this.reelCount = 3,
    this.width = 300.0,
    this.height = 200.0,
    this.itemHeight = 60.0,
    this.visibleItemCount = 3,
    this.showStartButton = true,
    this.startButtonText = '开始抽奖',
  }) : super(key: key);

  @override
  State<SlotRaffleWidget> createState() => _SlotRaffleWidgetState();
}

class _SlotRaffleWidgetState extends State<SlotRaffleWidget>
    with TickerProviderStateMixin {
  late SlotRaffleController _controller;
  List<int> _currentIndices = [];
  bool _isRaffling = false;

  @override
  void initState() {
    super.initState();

    _controller = SlotRaffleController(
      config: widget.config,
      items: widget.items,
      reelCount: widget.reelCount,
      itemHeight: widget.itemHeight,
      visibleItemCount: widget.visibleItemCount,
    );

    // 初始化动画控制器
    _controller.initializeAnimations(this);

    // 初始化当前索引
    _currentIndices = List.filled(widget.reelCount, 0);

    // 监听滚轮状态变化
    _controller.reelStateStream.listen((indices) {
      if (mounted) {
        setState(() {
          _currentIndices = indices;
        });
      }
    });

    // 监听抽奖状态变化
    _controller.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isRaffling = state == RaffleState.running;
        });

        if (state == RaffleState.running) {
          widget.onStart?.call();
        } else if (state == RaffleState.stopped) {
          widget.onStop?.call();
        }
      }
    });

    // 监听抽奖结果
    _controller.resultStream.listen((result) {
      widget.onResult?.call(result);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 开始抽奖
  Future<void> _startRaffle() async {
    if (!_controller.canStart) return;

    try {
      await _controller.startRaffle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('抽奖失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 老虎机区域
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.config.backgroundColor,
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            border: Border.all(
              color: widget.config.borderColor,
              width: widget.config.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildSlotMachine(),
        ),

        // 开始按钮
        if (widget.showStartButton) ...[
          SizedBox(height: widget.config.margin.top),
          _buildStartButton(),
        ],
      ],
    );
  }

  /// 构建老虎机
  Widget _buildSlotMachine() {
    return Padding(
      padding: widget.config.padding,
      child: Row(
        children: List.generate(widget.reelCount, (index) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  widget.config.borderRadius / 2,
                ),
                border: Border.all(
                  color: widget.config.borderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _buildReel(index),
            ),
          );
        }),
      ),
    );
  }

  /// 构建单个滚轮
  Widget _buildReel(int reelIndex) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.config.borderRadius / 2),
      child: SizedBox(
        height: widget.itemHeight * widget.visibleItemCount,
        child: Stack(
          fit: StackFit.expand, // 确保Stack填充可用空间
          children: [
            // 滚动列表
            _buildScrollingList(reelIndex),

            // 中心高亮框
            _buildCenterHighlight(),
          ],
        ),
      ),
    );
  }

  /// 构建滚动列表
  Widget _buildScrollingList(int reelIndex) {
    return StreamBuilder<RaffleState>(
      stream: _controller.stateStream,
      builder: (context, snapshot) {
        final scrollOffset = _controller.getScrollOffset(reelIndex);

        return ClipRect(
          child: Transform.translate(
            offset: Offset(0, -scrollOffset),
            child: SizedBox(
              width: double.infinity,
              height:
                  widget.itemHeight *
                  widget.visibleItemCount *
                  0.95, // 稍微减小高度以避免溢出
              child: Column(
                mainAxisSize: MainAxisSize.min, // 改为min以适应内容大小
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    _buildReelItems(
                      reelIndex,
                    ).take(widget.visibleItemCount).toList(), // 限制子项数量
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建滚轮项目列表
  List<Widget> _buildReelItems(int reelIndex) {
    final items = <Widget>[];
    final currentIndex = _currentIndices[reelIndex];

    // 为了实现无缝滚动，只需要在前后各添加可见项目数量的项目
    // final extraItems = widget.visibleItemCount; // 未使用，移除
    final totalItems = widget.items.length;

    // 计算需要显示的项目范围，避免生成过多项目
    final visibleCount = widget.visibleItemCount; // 调整为仅显示可见数量的项目

    for (int i = 0; i < visibleCount; i++) {
      // 计算实际索引，确保在items范围内循环
      final itemIndex = (currentIndex + i) % totalItems;
      final item = widget.items[itemIndex];

      items.add(_buildReelItem(item, itemIndex == currentIndex));
    }

    return items;
  }

  /// 构建单个滚轮项目
  Widget _buildReelItem(RaffleItem item, bool isCurrent) {
    return Container(
      height: widget.itemHeight,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color:
            isCurrent && !_isRaffling
                ? widget.config.highlightColor.withOpacity(0.2)
                : Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // 改为min以适应内容大小
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 奖品图片
          if (item.imageUrl != null)
            SizedBox(
              height: widget.itemHeight * 0.35, // 进一步减少高度，占据35%的空间
              child: Padding(
                padding: const EdgeInsets.all(2.0), // 减少内边距
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.card_giftcard,
                      color: widget.config.primaryColor,
                      size: 16, // 减小图标大小
                    );
                  },
                ),
              ),
            ),

          // 奖品名称
          SizedBox(
            height: widget.itemHeight * 0.15, // 进一步减少高度，占据15%的空间
            child: Center(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: widget.config.fontSize * 0.6, // 减小字体大小
                  color: widget.config.textColor,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建中心高亮框
  Widget _buildCenterHighlight() {
    // 计算中心位置，确保高亮框在正中间
    final centerTop = (widget.visibleItemCount - 1) * widget.itemHeight / 2;

    return Positioned(
      top: centerTop,
      left: 0,
      right: 0,
      height: widget.itemHeight,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: widget.config.highlightColor, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// 构建开始按钮
  Widget _buildStartButton() {
    return SizedBox(
      width: widget.width * 0.6,
      height: 48,
      child: ElevatedButton(
        onPressed: _isRaffling ? null : _startRaffle,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.config.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
          ),
          elevation: _isRaffling ? 0 : 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRaffling) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _isRaffling ? '抽奖中...' : widget.startButtonText,
              style: TextStyle(
                fontSize: widget.config.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
