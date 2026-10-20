import 'dart:math';
import 'package:flutter/material.dart';
import 'package:raffle/models/raffle_state.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../controllers/wheel_raffle_controller.dart';

/// 大转盘抽奖组件
class WheelRaffleWidget extends StatefulWidget {
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

  /// 转盘尺寸
  final double size;

  /// 是否显示开始按钮
  final bool showStartButton;

  /// 开始按钮文本
  final String startButtonText;

  /// 是否启用手势控制
  final bool enableGesture;

  const WheelRaffleWidget({
    Key? key,
    required this.items,
    required this.config,
    this.onResult,
    this.onStart,
    this.onStop,
    this.size = 300.0,
    this.showStartButton = true,
    this.startButtonText = '开始抽奖',
    this.enableGesture = false,
  }) : super(key: key);

  @override
  State<WheelRaffleWidget> createState() => _WheelRaffleWidgetState();
}

class _WheelRaffleWidgetState extends State<WheelRaffleWidget>
    with TickerProviderStateMixin {
  late WheelRaffleController _controller;
  double _currentRotation = 0.0;
  bool _isRaffling = false;

  // 手势相关
  double _lastPanAngle = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();

    _controller = WheelRaffleController(
      config: widget.config,
      items: widget.items,
      onRaffleComplete: widget.onResult,
    );

    // 初始化动画控制器
    _controller.initializeAnimation(this);

    // 监听旋转角度变化
    _controller.rotationStream.listen((rotation) {
      if (mounted) {
        setState(() {
          _currentRotation = rotation;
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

    // 监听抽奖结果并弹出对话框，确保与转盘停止位置一致
    _controller.resultStream.listen((result) {
      widget.onResult?.call(result);
      // 弹窗展示结果，确保与转盘停止位置一致
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('抽奖结果'),
              content: Text('恭喜获得：${result.prize.name}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      }
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

  /// 处理手势开始
  void _onPanStart(DragStartDetails details) {
    if (!widget.enableGesture || _isRaffling) return;

    _isDragging = true;
    final center = Offset(widget.size / 2, widget.size / 2);
    final offset = details.localPosition - center;
    _lastPanAngle = atan2(offset.dy, offset.dx);
  }

  /// 处理手势更新
  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableGesture || _isRaffling || !_isDragging) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final offset = details.localPosition - center;
    final currentAngle = atan2(offset.dy, offset.dx);

    // 计算拖动距离，只有超过一定阈值才更新角度，避免微小抖动
    final distance = offset.distance;
    if (distance > 20) {
      // 设置最小拖动距离阈值
      double deltaAngle = currentAngle - _lastPanAngle;

      // 处理角度跨越边界的情况
      if (deltaAngle > pi) {
        deltaAngle -= 2 * pi;
      } else if (deltaAngle < -pi) {
        deltaAngle += 2 * pi;
      }

      _controller.addRotation(deltaAngle);
      _lastPanAngle = currentAngle;
    }
  }

  /// 处理手势结束
  void _onPanEnd(DragEndDetails details) {
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 转盘区域
        Container(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 转盘背景
              _buildWheelBackground(),

              // 转盘内容
              _buildWheel(),

              // 指针
              _buildPointer(),
            ],
          ),
        ),

        // 开始按钮
        if (widget.showStartButton) ...[
          SizedBox(height: widget.config.margin.top),
          _buildStartButton(),
        ],
      ],
    );
  }

  /// 构建转盘背景
  Widget _buildWheelBackground() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.config.backgroundColor,
        border: Border.all(
          color: widget.config.borderColor,
          width: widget.config.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  /// 构建转盘
  Widget _buildWheel() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.rotate(
        angle: _currentRotation,
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: WheelPainter(items: widget.items, config: widget.config),
        ),
      ),
    );
  }

  /// 构建指针
  Widget _buildPointer() {
    return Positioned(
      top: 10,
      child: Container(
        width: 20,
        height: 30,
        decoration: BoxDecoration(
          color: widget.config.highlightColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建开始按钮
  Widget _buildStartButton() {
    return SizedBox(
      width: widget.size * 0.4,
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
        child: Text(
          _isRaffling ? '抽奖中...' : widget.startButtonText,
          style: TextStyle(
            fontSize: widget.config.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 转盘绘制器
class WheelPainter extends CustomPainter {
  final List<RaffleItem> items;
  final RaffleConfig config;

  WheelPainter({required this.items, required this.config});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - config.borderWidth;
    final sectorAngle = 2 * pi / items.length;

    // 预定义颜色列表
    final colors = [
      Colors.red.shade300,
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.indigo.shade300,
    ];

    for (int i = 0; i < items.length; i++) {
      final startAngle = i * sectorAngle - pi / 2; // 从顶部开始
      final sweepAngle = sectorAngle;

      // 绘制扇形
      final paint =
          Paint()
            ..color = colors[i % colors.length]
            ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // 绘制边框
      final borderPaint =
          Paint()
            ..color = config.borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // 绘制文字
      _drawText(
        canvas,
        items[i].name,
        center,
        radius * 0.7,
        startAngle + sweepAngle / 2,
      );
    }
  }

  /// 绘制文字
  void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double angle,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: config.textColor,
          fontSize: config.fontSize * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final textOffset = Offset(
      center.dx + cos(angle) * radius - textPainter.width / 2,
      center.dy + sin(angle) * radius - textPainter.height / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
