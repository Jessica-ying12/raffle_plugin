// 导入必要的测试和服务包
import 'package:flutter/services.dart'; // Flutter服务层，用于方法通道
import 'package:flutter_test/flutter_test.dart'; // Flutter测试框架
import 'package:raffle/raffle_method_channel.dart'; // 抽奖插件的方法通道实现

/// 测试入口函数
void main() {
  // 初始化Flutter测试绑定，确保测试环境正确设置
  TestWidgetsFlutterBinding.ensureInitialized();

  // 创建方法通道实现实例
  MethodChannelRaffle platform = MethodChannelRaffle();
  // 定义与原生平台通信的方法通道，与插件中定义的通道名称一致
  const MethodChannel channel = MethodChannel('raffle');

  // 每个测试前的设置
  setUp(() {
    // 为方法通道设置模拟处理器，拦截所有方法调用并返回固定值'42'
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42'; // 所有方法调用都返回'42'作为测试值
      },
    );
  });

  // 每个测试后的清理
  tearDown(() {
    // 清除方法通道的模拟处理器，避免影响其他测试
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  // 测试getPlatformVersion方法是否正确通过方法通道获取值
  test('getPlatformVersion', () async {
    // 验证方法返回值是否为模拟处理器设置的'42'
    expect(await platform.getPlatformVersion(), '42');
  });
}
