
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TscBtBluetooth {
  static const MethodChannel _channel =
      const MethodChannel('tsc_bt_bluetooth');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String?> openPort(String address) async {
    final String? res = await _channel.invokeMethod('openPort',{"address": address});
    return res;
  }

  static Future<String?> closePort() async {
    final String? res = await _channel.invokeMethod('closePort');
    return res;
  }

  static Future<String?> setup(int width,int height,int speed,int density,int distance,int offset) async {
    final String? res = await _channel.invokeMethod('setup',{"width":width,"height":height,"speed":speed,"density":density,"distance":distance,"offset":offset});
    return res;
  }

  static Future<String?> clearBuffer() async {
    final String? res = await _channel.invokeMethod('clearBuffer');
    return res;
  }

  static Future<String?> printLabel(int num) async {
    final String? res = await _channel.invokeMethod('printLabel',{"num":num});
    return res;
  }
  static Future<String?> printerfont(int x,int y,String size,String content) async {
    final String? res = await _channel.invokeMethod('printerfont',{"x":x,"y":y,"size":size,"content":content});
    return res;
  }
  static Future<String?> sendBitmapResize(int x,int y,String path,int width,int height) async {
    final String? res = await _channel.invokeMethod('sendBitmapResize',{"x":x,"y":y,"path":path,"width":width,"height":height});
    return res;
  }
  static Future<String?> sendCommand(String command) async {
    final String? res = await _channel.invokeMethod('sendCommand',{"command":command});
    return res;
  }
}
