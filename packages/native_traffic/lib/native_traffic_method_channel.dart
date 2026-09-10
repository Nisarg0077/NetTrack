import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_traffic_platform_interface.dart';

/// An implementation of [NativeTrafficPlatform] that uses method channels.
class MethodChannelNativeTraffic extends NativeTrafficPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_traffic');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<int?> getTotalRxBytes() async {
    return await methodChannel.invokeMethod<int>('getTotalRxBytes');
  }

  @override
  Future<int?> getTotalTxBytes() async {
    return await methodChannel.invokeMethod<int>('getTotalTxBytes');
  }
}
