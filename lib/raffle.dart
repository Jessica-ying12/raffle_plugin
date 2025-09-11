
import 'raffle_platform_interface.dart';

class Raffle {
  Future<String?> getPlatformVersion() {
    return RafflePlatform.instance.getPlatformVersion();
  }
}
