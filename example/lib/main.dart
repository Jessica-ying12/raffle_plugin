// 导入必要的包
import 'package:flutter/material.dart'; // Flutter材料设计库
import 'raffle_demo.dart'; // 抽奖演示页面

/// 应用程序入口点
/// 初始化并运行MyApp组件
void main() {
  runApp(const MyApp());
}

/// 应用程序根组件
/// 设置应用程序的主题和初始路由
class MyApp extends StatelessWidget {
  /// 构造函数
  /// @param key 组件键
  const MyApp({super.key});

  /// 构建应用程序界面
  /// @param context 构建上下文
  /// @return 构建的Widget树
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Raffle Demo', // 应用程序标题
      theme: ThemeData(
        primarySwatch: Colors.blue, // 主题颜色
        visualDensity: VisualDensity.adaptivePlatformDensity, // 视觉密度
      ),
      home: const RaffleDemoPage(), // 首页为抽奖演示页面
      debugShowCheckedModeBanner: false, // 隐藏调试标签
    );
  }
}
