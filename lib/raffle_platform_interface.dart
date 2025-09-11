import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'raffle_method_channel.dart';

abstract class RafflePlatform extends PlatformInterface {
  /// Constructs a RafflePlatform.
  RafflePlatform() : super(token: _token);

  static final Object _token = Object();

  static RafflePlatform _instance = MethodChannelRaffle();

  /// The default instance of [RafflePlatform] to use.
  ///
  /// Defaults to [MethodChannelRaffle].
  static RafflePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [RafflePlatform] when
  /// they register themselves.
  static set instance(RafflePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
