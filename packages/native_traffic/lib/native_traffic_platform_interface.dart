import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_traffic_method_channel.dart';

abstract class NativeTrafficPlatform extends PlatformInterface {
  /// Constructs a NativeTrafficPlatform.
  NativeTrafficPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeTrafficPlatform _instance = MethodChannelNativeTraffic();

  /// The default instance of [NativeTrafficPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeTraffic].
  static NativeTrafficPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeTrafficPlatform] when
  /// they register themselves.
  static set instance(NativeTrafficPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<int?> getTotalRxBytes() {
    throw UnimplementedError('getTotalRxBytes() has not been implemented.');
  }

  Future<int?> getTotalTxBytes() {
    throw UnimplementedError('getTotalTxBytes() has not been implemented.');
  }
}
