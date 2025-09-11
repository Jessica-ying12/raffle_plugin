import 'package:flutter_test/flutter_test.dart';
import 'package:raffle/raffle.dart';
import 'package:raffle/raffle_platform_interface.dart';
import 'package:raffle/raffle_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockRafflePlatform
    with MockPlatformInterfaceMixin
    implements RafflePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final RafflePlatform initialPlatform = RafflePlatform.instance;

  test('$MethodChannelRaffle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelRaffle>());
  });

  test('getPlatformVersion', () async {
    Raffle rafflePlugin = Raffle();
    MockRafflePlatform fakePlatform = MockRafflePlatform();
    RafflePlatform.instance = fakePlatform;

    expect(await rafflePlugin.getPlatformVersion(), '42');
  });
}
