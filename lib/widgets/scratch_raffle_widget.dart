import 'package:flutter/material.dart';
import 'package:raffle/models/raffle_state.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';
import '../controllers/scratch_raffle_controller.dart';

/// 刮刮卡抽奖组件
class ScratchRaffleWidget extends StatefulWidget {
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
  
  /// 卡片宽度
  final double width;
  
  /// 卡片高度
  final double height;
  
  /// 刮开画笔大小
  final double brushSize;
  
  /// 完成刮开的阈值
  final double completeThreshold;
  
  /// 涂层颜色
  final Color scratchColor;
  
  /// 涂层文本
  final String scratchText;
  
  /// 是否显示进度条
  final bool showProgress;
  
  /// 是否显示开始按钮
  final bool showStartButton;
  
  /// 开始按钮文本
  final String startButtonText;

  const ScratchRaffleWidget({
    Key? key,
    required this.items,
    required this.config,
    this.onResult,
    this.onStart,
    this.onStop,
    this.width = 300.0,
    this.height = 200.0,
    this.brushSize = 20.0,
    this.completeThreshold = 0.6,
    this.scratchColor = const Color(0xFFC0C0C0),
    this.scratchText = '刮开涂层',
    this.showProgress = true,
    this.showStartButton = true,
    this.startButtonText = '开始抽奖',
  }) : super(key: key);

  @override
  State<ScratchRaffleWidget> createState() => _ScratchRaffleWidgetState();
}

class _ScratchRaffleWidgetState extends State<ScratchRaffleWidget> {
  late ScratchRaffleController _controller;
  List<Offset> _scratchedPoints = [];
  double _currentProgress = 0.0;
  bool _isRaffling = false;
  RaffleItem? _winnerItem;

  @override
  void initState() {
    super.initState();
    
    _controller = ScratchRaffleController(
      config: widget.config,
      items: widget.items,
      cardSize: Size(widget.width, widget.height),
      brushSize: widget.brushSize,
      completeThreshold: widget.completeThreshold,
    );
    
    // 监听刮开区域变化
    _controller.scratchStream.listen((points) {
      if (mounted) {
        setState(() {
          _scratchedPoints = points;
        });
      }
    });
    
    // 监听刮开进度变化
    _controller.progressStream.listen((progress) {
      if (mounted) {
        setState(() {
          _currentProgress = progress;
        });
      }
    });
    
    // 监听抽奖状态变化
    _controller.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isRaffling = state == RaffleState.running;
          _winnerItem = _controller.winnerItem;
        });
        
        if (state == RaffleState.running) {
          widget.onStart?.call();
        } else if (state == RaffleState.completed) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('抽奖失败: $e')),
        );
      }
    }
  }
  
  /// 处理手势开始
  void _onPanStart(DragStartDetails details) {
    if (!_isRaffling) return;
    
    final localPosition = details.localPosition;
    _controller.addScratchPoint(localPosition);
  }
  
  /// 处理手势更新
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isRaffling) return;
    
    final localPosition = details.localPosition;
    _controller.addScratchPoint(localPosition);
  }
  
  /// 处理手势结束
  void _onPanEnd(DragEndDetails details) {
    // 手势结束时不需要特殊处理
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 刮刮卡区域
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.config.borderRadius),
            child: _buildScratchCard(),
          ),
        ),
        
        // 进度条
        if (widget.showProgress && _isRaffling) ...[
          SizedBox(height: widget.config.margin.top / 2),
          _buildProgressBar(),
        ],
        
        // 开始按钮
        if (widget.showStartButton) ...[
          SizedBox(height: widget.config.margin.top),
          _buildStartButton(),
        ],
      ],
    );
  }
  
  /// 构建刮刮卡
  Widget _buildScratchCard() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Stack(
        children: [
          // 底层内容（中奖结果）
          _buildCardContent(),
          
          // 刮开涂层
          if (_isRaffling || _scratchedPoints.isNotEmpty)
            _buildScratchLayer(),
        ],
      ),
    );
  }
  
  /// 构建卡片内容
  Widget _buildCardContent() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.config.primaryColor.withOpacity(0.8),
            widget.config.primaryColor,
          ],
        ),
      ),
      child: _winnerItem != null 
          ? _buildWinnerContent(_winnerItem!) 
          : _buildPlaceholderContent(),
    );
  }
  
  /// 构建中奖内容
  Widget _buildWinnerContent(RaffleItem item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 恭喜文字
        Text(
          '恭喜中奖！',
          style: TextStyle(
            fontSize: widget.config.fontSize * 1.2,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 16),
        
        // 奖品图片
        if (item.imageUrl != null)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.card_giftcard,
                    size: 40,
                    color: widget.config.primaryColor,
                  );
                },
              ),
            ),
          ),
        
        SizedBox(height: 12),
        
        // 奖品名称
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.name,
            style: TextStyle(
              fontSize: widget.config.fontSize,
              fontWeight: FontWeight.bold,
              color: widget.config.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  /// 构建占位内容
  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            size: 60,
            color: Colors.white.withOpacity(0.8),
          ),
          SizedBox(height: 16),
          Text(
            '神秘奖品',
            style: TextStyle(
              fontSize: widget.config.fontSize * 1.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建刮开涂层
  Widget _buildScratchLayer() {
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: ScratchLayerPainter(
        scratchedPoints: _scratchedPoints,
        brushSize: widget.brushSize,
        scratchColor: widget.scratchColor,
        scratchText: widget.scratchText,
        textStyle: TextStyle(
          fontSize: widget.config.fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  /// 构建进度条
  Widget _buildProgressBar() {
    return Container(
      width: widget.width * 0.8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          Container(
            width: widget.width * 0.8 * _currentProgress,
            height: 8,
            decoration: BoxDecoration(
              color: widget.config.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Center(
            child: Text(
              '${(_currentProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _currentProgress > 0.5 ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ],
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
        child: Text(
          _isRaffling ? '请刮开涂层' : widget.startButtonText,
          style: TextStyle(
            fontSize: widget.config.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 刮开涂层绘制器
class ScratchLayerPainter extends CustomPainter {
  final List<Offset> scratchedPoints;
  final double brushSize;
  final Color scratchColor;
  final String scratchText;
  final TextStyle textStyle;
  
  ScratchLayerPainter({
    required this.scratchedPoints,
    required this.brushSize,
    required this.scratchColor,
    required this.scratchText,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制涂层背景
    final backgroundPaint = Paint()
      ..color = scratchColor
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );
    
    // 绘制涂层文字
    final textPainter = TextPainter(
      text: TextSpan(text: scratchText, style: textStyle),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );
    
    textPainter.paint(canvas, textOffset);
    
    // 绘制刮开区域（使用混合模式清除涂层）
    if (scratchedPoints.isNotEmpty) {
      final scratchPaint = Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.fill;
      
      for (final point in scratchedPoints) {
        canvas.drawCircle(point, brushSize / 2, scratchPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}