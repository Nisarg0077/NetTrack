
import 'native_traffic_platform_interface.dart';

class NativeTraffic {
  Future<String?> getPlatformVersion() {
    return NativeTrafficPlatform.instance.getPlatformVersion();
  }

  Future<int?> getTotalRxBytes() {
    return NativeTrafficPlatform.instance.getTotalRxBytes();
  }

  Future<int?> getTotalTxBytes() {
    return NativeTrafficPlatform.instance.getTotalTxBytes();
  }
}
