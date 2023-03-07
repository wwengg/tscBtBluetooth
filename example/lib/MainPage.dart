import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:tsc_bt_bluetooth/tsc_bt_bluetooth.dart';

import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';
import './ChatPage.dart';
import './BackgroundCollectingTask.dart';
import './BackgroundCollectedPage.dart';

// import './helpers/LineChart.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  BackgroundCollectingTask _collectingTask;

  bool _autoAcceptPairingRequests = false;

  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await TscBtBluetooth.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TSC Bt Bluetooth'),
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            Divider(),
            ListTile(title: Text('General $_platformVersion\n')),
            SwitchListTile(
              title: const Text('蓝牙开关'),
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value)
                    await FlutterBluetoothSerial.instance.requestEnable();
                  else
                    await FlutterBluetoothSerial.instance.requestDisable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
            ),
            // ListTile(
            //   title: const Text('蓝牙状态'),
            //   subtitle: Text(_bluetoothState.toString()),
            //   trailing: RaisedButton(
            //     child: const Text('设置'),
            //     onPressed: () {
            //       FlutterBluetoothSerial.instance.openSettings();
            //     },
            //   ),
            // ),
            ListTile(
              title: const Text('本机地址'),
              subtitle: Text(_address),
            ),
            ListTile(
              title: const Text('本机蓝牙名称'),
              subtitle: Text(_name),
              onLongPress: null,
            ),
            ListTile(
              title: _discoverableTimeoutSecondsLeft == 0
                  ? const Text("Discoverable")
                  : Text(
                      "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
              subtitle: const Text("PsychoX-Luna"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _discoverableTimeoutSecondsLeft != 0,
                    onChanged: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      print('Discoverable requested');
                      final int timeout = await FlutterBluetoothSerial.instance
                          .requestDiscoverable(60);
                      if (timeout < 0) {
                        print('Discoverable mode denied');
                      } else {
                        print(
                            'Discoverable mode acquired for $timeout seconds');
                      }
                      setState(() {
                        _discoverableTimeoutTimer?.cancel();
                        _discoverableTimeoutSecondsLeft = timeout;
                        _discoverableTimeoutTimer =
                            Timer.periodic(Duration(seconds: 1), (Timer timer) {
                          setState(() {
                            if (_discoverableTimeoutSecondsLeft < 0) {
                              FlutterBluetoothSerial.instance.isDiscoverable
                                  .then((isDiscoverable) {
                                if (isDiscoverable) {
                                  print(
                                      "Discoverable after timeout... might be infinity timeout :F");
                                  _discoverableTimeoutSecondsLeft += 1;
                                }
                              });
                              timer.cancel();
                              _discoverableTimeoutSecondsLeft = 0;
                            } else {
                              _discoverableTimeoutSecondsLeft -= 1;
                            }
                          });
                        });
                      });
                    },
                  )
                ],
              ),
            ),
            Divider(),
            ListTile(title: const Text('Devices discovery and connection')),
            SwitchListTile(
              title: const Text('Auto-try specific pin when pairing'),
              subtitle: const Text('Pin 0000'),
              value: _autoAcceptPairingRequests,
              onChanged: (bool value) {
                setState(() {
                  _autoAcceptPairingRequests = value;
                });
                if (value) {
                  FlutterBluetoothSerial.instance.setPairingRequestHandler(
                      (BluetoothPairingRequest request) {
                    print("Trying to auto-pair with Pin 0000");
                    if (request.pairingVariant == PairingVariant.Pin) {
                      return Future.value("0000");
                    }
                    return null;
                  });
                } else {
                  FlutterBluetoothSerial.instance
                      .setPairingRequestHandler(null);
                }
              },
            ),
            // ListTile(
            //   title: RaisedButton(
            //       child: const Text('查找BLE蓝牙设备'),
            //       onPressed: () async {
            //         final BluetoothDevice selectedDevice =
            //             await Navigator.of(context).push(
            //           MaterialPageRoute(
            //             builder: (context) {
            //               return DiscoveryPage();
            //             },
            //           ),
            //         );

            //         if (selectedDevice != null) {
            //           print('Discovery -> selected ' + selectedDevice.address);
            //         } else {
            //           print('Discovery -> no device selected');
            //         }
            //       }),
            // ),
            // ListTile(
            //   title: RaisedButton(
            //     child: const Text('选择BT蓝牙设备'),
            //     onPressed: () async {
            //       final BluetoothDevice selectedDevice =
            //           await Navigator.of(context).push(
            //         MaterialPageRoute(
            //           builder: (context) {
            //             return SelectBondedDevicePage(checkAvailability: false);
            //           },
            //         ),
            //       );

            //       if (selectedDevice != null) {
            //         print('Connect -> selected ' + selectedDevice.address);
            //         _startChat(context, selectedDevice);
            //       } else {
            //         print('Connect -> no device selected');
            //       }
            //     },
            //   ),
            // ),
//            Divider(),
//            ListTile(title: const Text('Multiple connections example')),
//            ListTile(
//              title: RaisedButton(
//                child: ((_collectingTask != null && _collectingTask.inProgress)
//                    ? const Text('Disconnect and stop background collecting')
//                    : const Text('Connect to start background collecting')),
//                onPressed: () async {
//                  if (_collectingTask != null && _collectingTask.inProgress) {
//                    await _collectingTask.cancel();
//                    setState(() {
//                      /* Update for `_collectingTask.inProgress` */
//                    });
//                  } else {
//                    final BluetoothDevice selectedDevice =
//                    await Navigator.of(context).push(
//                      MaterialPageRoute(
//                        builder: (context) {
//                          return SelectBondedDevicePage(
//                              checkAvailability: false);
//                        },
//                      ),
//                    );
//
//                    if (selectedDevice != null) {
//                      await _startBackgroundTask(context, selectedDevice);
//                      setState(() {
//                        /* Update for `_collectingTask.inProgress` */
//                      });
//                    }
//                  }
//                },
//              ),
//            ),
//            ListTile(
//              title: RaisedButton(
//                child: const Text('View background collected data'),
//                onPressed: (_collectingTask != null)
//                    ? () {
//                  Navigator.of(context).push(
//                    MaterialPageRoute(
//                      builder: (context) {
//                        return ScopedModel<BackgroundCollectingTask>(
//                          model: _collectingTask,
//                          child: BackgroundCollectedPage(),
//                        );
//                      },
//                    ),
//                  );
//                }
//                    : null,
//              ),
//            ),
          ],
        ),
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }

  Future<void> _startBackgroundTask(
    BuildContext context,
    BluetoothDevice server,
  ) async {
    try {
      _collectingTask = await BackgroundCollectingTask.connect(server);
      await _collectingTask.start();
    } catch (ex) {
      if (_collectingTask != null) {
        _collectingTask.cancel();
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error occured while connecting'),
            content: Text("${ex.toString()}"),
            actions: <Widget>[
              // new FlatButton(
              //   child: new Text("Close"),
              //   onPressed: () {
              //     Navigator.of(context).pop();
              //   },
              // ),
            ],
          );
        },
      );
    }
  }
}
