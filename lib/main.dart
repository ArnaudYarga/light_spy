import 'dart:async';
import 'package:flutter/material.dart';
import 'package:light/light.dart';
import 'package:udp/udp.dart';
import 'package:spy/services/notification.dart';

enum LightState {
  ON,
  OFF,
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Light _light;
  int i = 0;
  int _lightPower = 0;
  double _threshold = 5.0;
  LightState _lightState;

  bool _isTransmitter = true;
  bool _broadcastLightOn = false;
  bool _isReceiver = false;
  BatteryNotification notification;
  static const _PAYLOAD = "0X0X0";
  UDP _sender, _receiver;

  Future<void> _init() async {
    if (_sender == null) {
      UDP sender = await UDP.bind(
        Endpoint.any(
          port: Port(8887),
        ),
      );
      sender.socket.broadcastEnabled = true;
      setState(() {
        _sender = sender;
      });
    }
  }

  @override
  void initState() {
    notification = BatteryNotification();
    _light = new Light();
    _light.lightSensorStream.listen(_handleBatteryState);
    super.initState();
  }

  void listenForBroadCast() {
    UDP.bind(Endpoint.any(port: Port(8889))).then((receiver) {
      receiver.listen((datagram) {
        String str = String.fromCharCodes(datagram.data);
        if (str == _PAYLOAD) {
          print("ALERT!!!!");
          notification.show();
        }
        setState(() => _receiver = receiver);
      });
    });
  }

  void sendBroadcast() async {
    if (_sender != null && _isTransmitter) {
      var dataLength = await _sender.send(
        _PAYLOAD.codeUnits,
        Endpoint.broadcast(
          port: Port(8889),
        ),
      );
      print("$dataLength bytes sent.");
    }
  }

  void _handleBatteryState(int luxValue) async {
    LightState newState =
        luxValue < _threshold ? LightState.OFF : LightState.ON;

    //when it is called the first time
    if (_lightState == null) {
      _lightState = newState;
      _lightPower = luxValue;
      return;
    }

    //when there is no state change
    if (_lightState == newState) {
      setState(() {
        _lightPower = luxValue;
      });
      return;
    }

    //when there is a state change
    setState(() {
      _lightState = newState;
      _lightPower = luxValue;
    });
    if ((newState == LightState.ON && _broadcastLightOn) ||
        (newState == LightState.OFF && !_broadcastLightOn)) {
      sendBroadcast();
    }
  }

  @override
  void dispose() {
    if (_sender != null) {
      _sender.close();
    }
    if (_receiver != null) {
      _receiver.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init(),
      builder: (_, __) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        drawer: drawer(),
        body: Center(
          child: Center(
            child: Container(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                  Image.asset(
                    _lightState == LightState.OFF
                        ? "images/light_off.png"
                        : "images/light_on.png",
                    width: 200,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text("Light : $_lightPower"),
                ])),
          ),
        ),
      ),
    );
  }

  Widget drawer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95,
      color: Colors.white.withOpacity(0.9),
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 30,
            ),
            Text(
              "CONFIG",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 20,
              ),
            ),
            SizedBox(
              height: 60,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Transmitter"),
                Switch(
                  value: _isTransmitter,
                  onChanged: (value) => setState(
                    () => _isTransmitter = value,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Notify when light : "),
                OutlineButton(
                  child: Text(
                    _broadcastLightOn ? "ON" : "OFF",
                  ),
                  onPressed: _isTransmitter
                      ? () =>
                          setState(() => _broadcastLightOn = !_broadcastLightOn)
                      : null,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Receiver"),
                Switch(
                  value: _isReceiver,
                  onChanged: (value) {
                    if (value) {
                      listenForBroadCast();
                    } else if (_receiver != null) {
                      _receiver.close();
                    }
                    setState(() => _isReceiver = value);
                  },
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text("Threshold :"),
                Slider(
                  min: 0.0,
                  max: 100.0,
                  divisions: 100,
                  label: "${_threshold.round()}",
                  value: _threshold,
                  onChanged: (double val) {
                    setState(() => _threshold = val);
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
