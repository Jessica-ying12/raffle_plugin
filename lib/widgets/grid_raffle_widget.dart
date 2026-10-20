import 'package:flutter/material.dart';
import '../controllers/grid_raffle_controller.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../models/raffle_state.dart';

/// 九宫格抽奖组件
class GridRaffleWidget extends StatefulWidget {
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

  /// 网格行数
  final int rows;

  /// 网格列数
  final int columns;

  /// 是否显示开始按钮
  final bool showStartButton;

  /// 开始按钮文本
  final String startButtonText;

  const GridRaffleWidget({
    Key? key,
    required this.items,
    required this.config,
    this.onResult,
    this.onStart,
    this.onStop,
    this.rows = 3,
    this.columns = 3,
    this.showStartButton = true,
    this.startButtonText = '开始抽奖',
  }) : super(key: key);

  @override
  State<GridRaffleWidget> createState() => _GridRaffleWidgetState();
}

class _GridRaffleWidgetState extends State<GridRaffleWidget>
    with TickerProviderStateMixin {
  late GridRaffleController _controller;
  int _highlightedIndex = -1;
  bool _isRaffling = false;

  @override
  void initState() {
    super.initState();

    _controller = GridRaffleController(
      config: widget.config,
      items: widget.items,
    );

    // 初始化动画控制器
    _controller.initializeAnimations(this);

    // 监听高亮索引变化
    _controller.highlightStream.listen((index) {
      if (mounted) {
        setState(() {
          _highlightedIndex = index;
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 九宫格区域
        AspectRatio(
          aspectRatio: widget.columns / widget.rows,
          child: Container(
            decoration: BoxDecoration(
              color: widget.config.backgroundColor,
              borderRadius: BorderRadius.circular(widget.config.borderRadius),
              border: Border.all(color: widget.config.primaryColor, width: 2.0),
            ),
            child: _buildGrid(),
          ),
        ),

        const SizedBox(height: 24),

        // 移除外部控制按钮（不允许手动停止）
      ],
    );
  }

  /// 构建九宫格
  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.rows * widget.columns,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildGridItem(index);
      },
    );
  }

  /// 构建格子项
  Widget _buildGridItem(int index) {
    final isHighlighted = index == _highlightedIndex;
    final isCenter = index == (widget.rows * widget.columns) ~/ 2;

    // 中间格子固定为开始按钮：抽奖中保持位置不变，但禁用点击
    if (isCenter && widget.showStartButton) {
      return _buildStartButton(disabled: _isRaffling);
    }

    // 获取对应的奖品
    final itemIndex =
        index >= (widget.rows * widget.columns) ~/ 2 ? index - 1 : index;
    final item =
        widget.items.length > itemIndex ? widget.items[itemIndex] : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:
            isHighlighted
                ? widget.config.primaryColor
                : widget.config.secondaryColor,
        borderRadius: BorderRadius.circular(widget.config.borderRadius / 2),
        boxShadow:
            isHighlighted
                ? [
                  BoxShadow(
                    color: widget.config.primaryColor.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
                : null,
      ),
      child:
          item != null
              ? _buildItemContent(item, isHighlighted)
              : const SizedBox(),
    );
  }

  /// 构建奖品内容
  Widget _buildItemContent(RaffleItem item, bool isHighlighted) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 奖品图片
          if (item.imageUrl != null)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Image.network(
                  item.imageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.card_giftcard,
                      size: 24,
                      color:
                          isHighlighted
                              ? Colors.white
                              : widget.config.primaryColor,
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 4),

          // 奖品名称
          Expanded(
            flex: 2,
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: widget.config.fontSize * 0.8,
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建开始按钮
  Widget _buildStartButton({bool disabled = false}) {
    return Container(
      decoration: BoxDecoration(
        color: widget.config.primaryColor,
        borderRadius: BorderRadius.circular(widget.config.borderRadius / 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : () => _controller.startRaffle(),
          borderRadius: BorderRadius.circular(widget.config.borderRadius / 2),
          child: Center(
            child: Text(
              widget.startButtonText,
              style: TextStyle(
                fontSize: widget.config.fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(disabled ? 0.6 : 1.0),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // 移除控制按钮（不允许手动停止）
}
