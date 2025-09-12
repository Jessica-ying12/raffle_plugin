import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:raffle/models/raffle_state.dart';
import '../controllers/golden_egg_raffle_controller.dart';
import '../models/raffle_item.dart';
import '../models/raffle_result.dart';
import '../models/raffle_config.dart';

/// 砸金蛋抽奖模块
/// 
/// 本模块实现了一个交互式的砸金蛋抽奖游戏UI组件，用户通过敲击金蛋获得抽奖结果。
/// 主要特点：
/// - 支持自定义敲击次数和动画效果
/// - 提供震动和破裂视觉反馈
/// - 可配置外观和交互行为
/// - 支持抽奖结果回调

/// 砸金蛋抽奖组件
/// 
/// 一个交互式的砸金蛋抽奖游戏UI组件，用户通过敲击金蛋获得抽奖结果。
/// 组件内部使用[GoldenEggRaffleController]管理抽奖逻辑和动画状态。
/// 
/// 主要功能：
/// - 显示一个可交互的金蛋图形
/// - 响应用户敲击并提供视觉和触觉反馈
/// - 在达到指定敲击次数后显示破裂效果和抽奖结果
/// - 支持自定义外观和行为
class GoldenEggRaffleWidget extends StatefulWidget {
  /// 抽奖配置
  final RaffleConfig config;
  
  /// 抽奖项目列表
  final List<RaffleItem> items;
  
  /// 最大敲击次数
  final int maxTaps;
  
  /// 金蛋大小
  final double eggSize;
  
  /// 抽奖结果回调
  final Function(RaffleResult)? onResult;
  
  /// 敲击回调
  final Function(int tapCount, int maxTaps)? onTap;
  
  /// 破裂回调
  final VoidCallback? onBreak;
  
  /// 自定义金蛋颜色
  final Color? eggColor;
  
  /// 自定义破裂颜色
  final Color? crackColor;
  
  /// 是否显示敲击提示
  final bool showTapHint;
  
  /// 是否显示进度条
  final bool showProgress;

  /// 创建砸金蛋抽奖组件
  /// 
  /// [config] 抽奖配置，控制抽奖行为和动画效果
  /// [items] 抽奖项目列表，包含可能的奖品信息
  /// [maxTaps] 破裂金蛋所需的最大敲击次数，默认为10次
  /// [eggSize] 金蛋显示的大小，默认为200.0像素
  /// [onResult] 抽奖结果回调，当金蛋破裂并产生结果时触发
  /// [onTap] 敲击回调，提供当前敲击次数和最大敲击次数
  /// [onBreak] 破裂回调，当金蛋破裂时触发
  /// [eggColor] 自定义金蛋颜色，默认为金色
  /// [crackColor] 自定义破裂纹路颜色，默认为深棕色
  /// [showTapHint] 是否显示敲击提示文本，默认为true
  /// [showProgress] 是否显示敲击进度条，默认为true
  const GoldenEggRaffleWidget({
    Key? key,
    required this.config,
    required this.items,
    this.maxTaps = 10,
    this.eggSize = 200.0,
    this.onResult,
    this.onTap,
    this.onBreak,
    this.eggColor,
    this.crackColor,
    this.showTapHint = true,
    this.showProgress = true,
  }) : super(key: key);

  @override
  State<GoldenEggRaffleWidget> createState() => _GoldenEggRaffleWidgetState();
}

/// 砸金蛋抽奖组件状态类
/// 
/// 管理砸金蛋组件的内部状态和动画效果，包括：
/// - 控制器初始化和生命周期管理
/// - 敲击事件处理和状态更新
/// - 动画效果和视觉反馈
/// - 抽奖结果处理
class _GoldenEggRaffleWidgetState extends State<GoldenEggRaffleWidget>
    with TickerProviderStateMixin {
  late GoldenEggRaffleController _controller;
  
  /// 当前敲击次数
  int _currentTapCount = 0;
  
  /// 是否已破裂
  bool _isBroken = false;
  
  /// 震动偏移
  Offset _shakeOffset = Offset.zero;
  
  /// 破裂进度
  double _crackProgress = 0.0;
  
  /// 抽奖结果
  RaffleResult? _result;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  /// 初始化控制器和事件监听
  /// 
  /// 创建[GoldenEggRaffleController]实例并设置各种事件监听：
  /// - 敲击次数变化监听
  /// - 破裂状态变化监听
  /// - 震动偏移变化监听
  /// - 破裂进度变化监听
  /// - 抽奖结果监听
  void _initializeController() {
    _controller = GoldenEggRaffleController(
      config: widget.config,
      items: widget.items,
      maxTaps: widget.maxTaps,
    );
    
    _controller.initializeAnimations(this);
    
    // 监听敲击次数变化
    _controller.tapCountStream.listen((tapCount) {
      setState(() {
        _currentTapCount = tapCount;
      });
      widget.onTap?.call(tapCount, widget.maxTaps);
    });
    
    // 监听破裂状态变化
    _controller.brokenStateStream.listen((isBroken) {
      setState(() {
        _isBroken = isBroken;
      });
      if (isBroken) {
        widget.onBreak?.call();
      }
    });
    
    // 监听震动偏移变化
    _controller.shakeOffsetStream.listen((offset) {
      setState(() {
        _shakeOffset = offset;
      });
    });
    
    // 监听破裂进度变化
    _controller.crackProgressStream.listen((progress) {
      setState(() {
        _crackProgress = progress;
      });
    });
    
    // 监听抽奖结果
    _controller.resultStream.listen((result) {
      setState(() {
        _result = result;
      });
      widget.onResult?.call(result);
    });
  }

  /// 开始抽奖
  /// 
  /// 调用控制器的startRaffle方法开始抽奖流程
  /// 同时触发轻微的触觉反馈，增强用户体验
  /// 
  /// 返回值：异步操作的Future，抽奖开始后解析
  Future<void> _startRaffle() async {
    HapticFeedback.lightImpact();
    await _controller.startRaffle();
  }

  /// 敲击金蛋
  /// 
  /// 用户交互的主要处理方法，当用户点击金蛋时调用
  /// 1. 检查金蛋是否已破裂，如已破裂则不执行任何操作
  /// 2. 触发中等强度的触觉反馈，模拟敲击感
  /// 3. 调用控制器的tapEgg方法处理敲击逻辑
  /// 
  /// 返回值：异步操作的Future，敲击动画完成后解析
  Future<void> _tapEgg() async {
    if (_isBroken) return;
    
    HapticFeedback.mediumImpact();
    _controller.tapEgg();
  }

  /// 重置抽奖
  /// 
  /// 将金蛋状态恢复到初始状态，可用于重新开始抽奖
  /// 1. 调用控制器的reset方法重置内部状态
  /// 2. 清除当前的抽奖结果
  /// 
  /// 该方法通常在用户希望重新抽奖时调用
  void _resetRaffle() {
    setState(() {
      _currentTapCount = 0;
      _isBroken = false;
      _shakeOffset = Offset.zero;
      _crackProgress = 0.0;
      _result = null;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 标题
          Text(
            '砸金蛋抽奖',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 32),
          
          // 进度条
          if (widget.showProgress && !_isBroken)
            _buildProgressBar(),
          
          const SizedBox(height: 24),
          
          // 金蛋区域
          _buildEggArea(),
          
          const SizedBox(height: 32),
          
          // 敲击提示
          if (widget.showTapHint && !_isBroken)
            _buildTapHint(),
          
          // 抽奖结果
          if (_result != null)
            _buildResult(),
          
          const SizedBox(height: 24),
          
          // 控制按钮
          _buildControlButtons(),
        ],
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar() {
    final progress = _currentTapCount / widget.maxTaps;
    
    return Column(
      children: [
        Text(
          '敲击进度: $_currentTapCount/${widget.maxTaps}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFA500),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建金蛋区域
  Widget _buildEggArea() {
    return GestureDetector(
      onTap: _controller.currentState == RaffleState.idle ? _startRaffle : _tapEgg,
      child: Transform.translate(
        offset: _shakeOffset,
        child: Transform.scale(
          scale: _controller.tapScale,
          child: Container(
            width: widget.eggSize,
            height: widget.eggSize * 1.2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 金蛋底色
                _buildEggBase(),
                
                // 破裂纹理
                if (_crackProgress > 0)
                  _buildCrackTexture(),
                
                // 光泽效果
                if (!_isBroken)
                  _buildEggGloss(),
                
                // 破裂后的内容
                if (_isBroken && _result != null)
                  _buildEggContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建金蛋底色
  Widget _buildEggBase() {
    return Container(
      width: widget.eggSize,
      height: widget.eggSize * 1.2,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.2,
          colors: [
            widget.eggColor?.withOpacity(0.9) ?? const Color(0xFFFFD700).withOpacity(0.9),
            widget.eggColor ?? const Color(0xFFFFD700),
            (widget.eggColor ?? const Color(0xFFFFD700)).withOpacity(0.8),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(widget.eggSize * 0.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }

  /// 构建破裂纹理
  Widget _buildCrackTexture() {
    return CustomPaint(
      size: Size(widget.eggSize, widget.eggSize * 1.2),
      painter: CrackPainter(
        progress: _crackProgress,
        crackColor: widget.crackColor ?? Colors.brown[800]!,
      ),
    );
  }

  /// 构建金蛋光泽
  Widget _buildEggGloss() {
    return Positioned(
      top: widget.eggSize * 0.15,
      left: widget.eggSize * 0.2,
      child: Container(
        width: widget.eggSize * 0.3,
        height: widget.eggSize * 0.4,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.6),
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(widget.eggSize * 0.2),
        ),
      ),
    );
  }

  /// 构建金蛋内容
  Widget _buildEggContent() {
    return Container(
      width: widget.eggSize * 0.6,
      height: widget.eggSize * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.eggSize * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard,
            size: widget.eggSize * 0.2,
            color: widget.config.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            _result!.item.name,
            style: TextStyle(
              fontSize: widget.eggSize * 0.06,
              fontWeight: FontWeight.bold,
              color: widget.config.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建敲击提示
  Widget _buildTapHint() {
    return Column(
      mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
      children: [
        Icon(
          Icons.touch_app,
          size: 32,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          _controller.currentState == RaffleState.idle
              ? '点击开始抽奖'
              : '继续敲击金蛋 (${widget.maxTaps - _currentTapCount} 次)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 构建抽奖结果
  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.1),
            const Color(0xFFFFA500).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
        children: [
          Text(
            '🎉 恭喜获得 🎉',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _result!.item.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: widget.config.primaryColor,
            ),
          ),
          if (_result!.item.description != null && _result!.item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _result!.item.description!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
      children: [
        ElevatedButton.icon(
          onPressed: _resetRaffle,
          icon: const Icon(Icons.refresh),
          label: const Text('重新开始'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// 破裂纹理绘制器
class CrackPainter extends CustomPainter {
  final double progress;
  final Color crackColor;
  
  CrackPainter({
    required this.progress,
    required this.crackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    
    final paint = Paint()
      ..color = crackColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;
    
    // 绘制多条裂纹
    final crackCount = (progress * 8).ceil();
    
    for (int i = 0; i < crackCount; i++) {
      final angle = (i * 2 * pi / 8) + (progress * pi / 4);
      final startRadius = maxRadius * 0.3;
      final endRadius = maxRadius * progress;
      
      final start = Offset(
        center.dx + cos(angle) * startRadius,
        center.dy + sin(angle) * startRadius,
      );
      
      final end = Offset(
        center.dx + cos(angle) * endRadius,
        center.dy + sin(angle) * endRadius,
      );
      
      // 主裂纹
      canvas.drawLine(start, end, paint);
      
      // 分支裂纹
      if (progress > 0.5) {
        final branchAngle1 = angle + pi / 6;
        final branchAngle2 = angle - pi / 6;
        final branchLength = endRadius * 0.3;
        
        final branch1End = Offset(
          end.dx + cos(branchAngle1) * branchLength,
          end.dy + sin(branchAngle1) * branchLength,
        );
        
        final branch2End = Offset(
          end.dx + cos(branchAngle2) * branchLength,
          end.dy + sin(branchAngle2) * branchLength,
        );
        
        canvas.drawLine(end, branch1End, paint);
        canvas.drawLine(end, branch2End, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CrackPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.crackColor != crackColor;
  }
}