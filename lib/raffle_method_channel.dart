import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'raffle_platform_interface.dart';

/// An implementation of [RafflePlatform] that uses method channels.
class MethodChannelRaffle extends RafflePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('raffle');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
