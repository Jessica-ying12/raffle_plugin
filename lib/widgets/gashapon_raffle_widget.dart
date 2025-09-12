import 'dart:math';
import 'package:flutter/material.dart';
import '../controllers/gashapon_raffle_controller.dart';
import '../models/raffle_result.dart';

/// 扭蛋机抽奖组件
class GashaponRaffleWidget extends StatefulWidget {
  /// 抽奖控制器
  final GashaponRaffleController controller;
  
  /// 扭蛋机颜色
  final Color machineColor;
  
  /// 扭蛋机边框颜色
  final Color machineBorderColor;
  
  /// 背景颜色
  final Color backgroundColor;
  
  /// 结果回调
  final Function(RaffleResult)? onResult;
  
  /// 状态变化回调
  final Function(String)? onStateChanged;
  
  const GashaponRaffleWidget({
    Key? key,
    required this.controller,
    this.machineColor = const Color(0xFF4A90E2),
    this.machineBorderColor = const Color(0xFF2E5C8A),
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.onResult,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<GashaponRaffleWidget> createState() => _GashaponRaffleWidgetState();
}

class _GashaponRaffleWidgetState extends State<GashaponRaffleWidget>
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
    return Container(
      color: widget.backgroundColor,
      child: Column(
        children: [
          // 扭蛋机区域
          Expanded(
            flex: 3,
            child: _buildGashaponMachine(),
          ),
          
          // 控制按钮区域
          Expanded(
            flex: 1,
            child: _buildControlArea(),
          ),
        ],
      ),
    );
  }
  
  /// 构建扭蛋机
  Widget _buildGashaponMachine() {
    return Stack(
      children: [
        // 扭蛋机主体
        _buildMachineBody(),
        
        // 掉落的扭蛋
        _buildFallingEgg(),
        
        // 粒子效果（可选）
        if (widget.controller.showParticles)
          _buildParticleEffect(),
      ],
    );
  }
  
  /// 构建扭蛋机主体
  Widget _buildMachineBody() {
    return Center(
      child: Container(
        width: 280,
        height: 400,
        child: CustomPaint(
          painter: GashaponMachinePainter(
            machineColor: widget.machineColor,
            borderColor: widget.machineBorderColor,
          ),
        ),
      ),
    );
  }
  
  /// 构建掉落的扭蛋
  Widget _buildFallingEgg() {
    return StreamBuilder<bool>(
      stream: widget.controller.eggVisibilityStream,
      initialData: false,
      builder: (context, visibilitySnapshot) {
        if (!visibilitySnapshot.data!) {
          return const SizedBox();
        }
        
        return StreamBuilder<Offset>(
          stream: widget.controller.eggPositionStream,
          initialData: const Offset(0, 0),
          builder: (context, positionSnapshot) {
            return StreamBuilder<double>(
              stream: widget.controller.eggRotationStream,
              initialData: 0.0,
              builder: (context, rotationSnapshot) {
                return StreamBuilder<Color>(
                  stream: widget.controller.eggColorStream,
                  initialData: Colors.blue,
                  builder: (context, colorSnapshot) {
                    final position = positionSnapshot.data ?? const Offset(0, 0);
                    final rotation = rotationSnapshot.data ?? 0.0;
                    final color = colorSnapshot.data ?? Colors.blue;
                    
                    return Positioned(
                      left: MediaQuery.of(context).size.width / 2 - widget.controller.eggSize / 2,
                      top: 120 + position.dy,
                      child: Transform.rotate(
                        angle: rotation,
                        child: _buildEgg(color),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  
  /// 构建扭蛋
  Widget _buildEgg(Color color) {
    return Container(
      width: widget.controller.eggSize,
      height: widget.controller.eggSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.8),
            color,
            color.withOpacity(0.6),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.controller.eggSize * 0.6,
          height: widget.controller.eggSize * 0.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
          ),
          child: Center(
            child: Icon(
              Icons.star,
              color: Colors.white.withOpacity(0.8),
              size: widget.controller.eggSize * 0.3,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建粒子效果
  Widget _buildParticleEffect() {
    return StreamBuilder<bool>(
      stream: widget.controller.eggVisibilityStream,
      initialData: false,
      builder: (context, snapshot) {
        if (!snapshot.data! || widget.controller.state.toString() != 'RaffleState.completed') {
          return const SizedBox();
        }
        
        return Positioned.fill(
          child: CustomPaint(
            painter: ParticleEffectPainter(),
          ),
        );
      },
    );
  }
  
  /// 构建控制区域
  Widget _buildControlArea() {
    return Container(
      padding: const EdgeInsets.all(8), // 减小内边距
      child: Column(
        mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
        children: [
          // 状态信息
          _buildStatusInfo(),
          
          const SizedBox(height: 8), // 减小间距
          
          // 控制按钮
          _buildControlButtons(),
        ],
      ),
    );
  }
  
  /// 构建状态信息
  Widget _buildStatusInfo() {
    return StreamBuilder<String>(
      stream: widget.controller.stateStream.map((state) => state.toString().split('.').last),
      initialData: 'idle',
      builder: (context, snapshot) {
        final state = snapshot.data ?? 'idle';
        final statusText = widget.controller.getStatusDescription();
        
        Color statusColor;
        switch (state) {
          case 'idle':
            statusColor = Colors.grey;
            break;
          case 'running':
            statusColor = Colors.blue;
            break;
          case 'completed':
            statusColor = Colors.green;
            break;
          default:
            statusColor = Colors.red;
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 减小内边距
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 14, // 减小字体大小
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // 添加溢出处理
            maxLines: 2, // 限制最大行数
          ),
        );
      },
    );
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
          mainAxisSize: MainAxisSize.min, // 设置为min以避免溢出
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 开始扭蛋按钮
            Flexible(
              child: ElevatedButton(
                onPressed: state == 'idle' ? () => widget.controller.triggerDrop() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 减小内边距
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  '开始扭蛋',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // 减小字体大小
                ),
              ),
            ),
            
            // 预览按钮
            Flexible(
              child: ElevatedButton(
                onPressed: state == 'idle' ? () => widget.controller.previewDrop() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '预览',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            
            // 重置按钮
            Flexible(
              child: ElevatedButton(
                onPressed: state != 'running' ? () => widget.controller.reset() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  '重置',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

/// 扭蛋机绘制器
class GashaponMachinePainter extends CustomPainter {
  final Color machineColor;
  final Color borderColor;
  
  GashaponMachinePainter({
    required this.machineColor,
    required this.borderColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = borderColor;
    
    // 绘制扭蛋机主体
    final machineRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.2, size.width, size.height * 0.8),
      const Radius.circular(20),
    );
    
    paint.color = machineColor;
    canvas.drawRRect(machineRect, paint);
    canvas.drawRRect(machineRect, borderPaint);
    
    // 绘制透明窗口
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.3,
        size.width * 0.8,
        size.height * 0.4,
      ),
      const Radius.circular(15),
    );
    
    paint.color = Colors.white.withOpacity(0.3);
    canvas.drawRRect(windowRect, paint);
    
    paint.color = Colors.white.withOpacity(0.1);
    borderPaint.color = Colors.white.withOpacity(0.5);
    canvas.drawRRect(windowRect, borderPaint);
    
    // 绘制出口
    final outletRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.4,
        size.height * 0.75,
        size.width * 0.2,
        size.height * 0.1,
      ),
      const Radius.circular(10),
    );
    
    paint.color = Colors.black.withOpacity(0.8);
    canvas.drawRRect(outletRect, paint);
    
    // 绘制顶部装饰
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, 0, size.width * 0.6, size.height * 0.25),
      const Radius.circular(15),
    );
    
    paint.color = machineColor.withOpacity(0.8);
    canvas.drawRRect(topRect, paint);
    canvas.drawRRect(topRect, borderPaint);
    
    // 绘制装饰灯
    paint.color = Colors.yellow;
    for (int i = 0; i < 3; i++) {
      final lightX = size.width * (0.3 + i * 0.2);
      final lightY = size.height * 0.12;
      canvas.drawCircle(Offset(lightX, lightY), 8, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 粒子效果绘制器
class ParticleEffectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final random = Random();
    
    // 绘制随机粒子
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      
      paint.color = Colors.yellow.withOpacity(random.nextDouble() * 0.8 + 0.2);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}