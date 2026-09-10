import 'package:flutter_test/flutter_test.dart';
import 'package:native_traffic/native_traffic.dart';
import 'package:native_traffic/native_traffic_platform_interface.dart';
import 'package:native_traffic/native_traffic_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeTrafficPlatform
    with MockPlatformInterfaceMixin
    implements NativeTrafficPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeTrafficPlatform initialPlatform = NativeTrafficPlatform.instance;

  test('$MethodChannelNativeTraffic is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeTraffic>());
  });

  test('getPlatformVersion', () async {
    NativeTraffic nativeTrafficPlugin = NativeTraffic();
    MockNativeTrafficPlatform fakePlatform = MockNativeTrafficPlatform();
    NativeTrafficPlatform.instance = fakePlatform;

    expect(await nativeTrafficPlugin.getPlatformVersion(), '42');
  });
}
