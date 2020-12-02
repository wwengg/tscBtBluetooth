import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsc_bt_bluetooth/tsc_bt_bluetooth.dart';

void main() {
  const MethodChannel channel = MethodChannel('tsc_bt_bluetooth');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await TscBtBluetooth.platformVersion, '42');
  });
}
