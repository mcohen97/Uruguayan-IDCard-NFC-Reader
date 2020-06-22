import 'dart:typed_data';

import 'package:convert/convert.dart';

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform, sleep;

import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion =
      '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  NFCAvailability _availability = NFCAvailability.not_supported;
  NFCTag _tag;
  String _result;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    NFCAvailability availability;
    try {
      availability = await FlutterNfcKit.nfcAvailability;
    } on PlatformException {
      availability = NFCAvailability.not_supported;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      // _platformVersion = platformVersion;
      _availability = availability;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('NFC Flutter Kit Example App'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Running on: $_platformVersion\nNFC: $_availability'),
              RaisedButton(
                onPressed: () async {
                  try {
                    NFCTag tag = await FlutterNfcKit.poll();
                    setState(() {
                      _tag = tag;
                    });
                    await selectIAS();
                    verifyPin();
                  } catch (e) {
                    setState(() {
                      _result = 'error: $e';
                    });
                  }

                  // Pretend that we are working
                  sleep(new Duration(seconds: 1));
                  await FlutterNfcKit.finish(iosAlertMessage: "Finished!");
                },
                child: Text('Read CI'),
              ),
              Text(
                  'ID: ${_tag?.id}\nStandard: ${_tag?.standard}\nType: ${_tag?.type}\nATQA: ${_tag?.atqa}\nSAK: ${_tag?.sak}\nHistorical Bytes: ${_tag?.historicalBytes}\nProtocol Info: ${_tag?.protocolInfo}\nApplication Data: ${_tag?.applicationData}\nHigher Layer Response: ${_tag?.hiLayerResponse}\nManufacturer: ${_tag?.manufacturer}\nSystem Code: ${_tag?.systemCode}\nDSF ID: ${_tag?.dsfId}\nNDEF Available:\nNDEF Type: ${_tag?.type}\nNDEF Writable: \nNDEF Can Make Read Only: \nNDEF Capacity: \n\n Transceive Result:\n$_result'),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> selectIAS() async{
    String CLASS = "00";
    String INSTRUCTION = "A4";
    String PARAM1 = "04";
    String PARAM2 = "00";
    String LC = "0C";
    String LE = "00";

    String dataIN = "A00000001840000001634200"; //IAS AID

    String command = CLASS + INSTRUCTION + PARAM1 + PARAM2 + LC + dataIN + LE;

    Uint8List bytes = hexStringToByteArray(command);

    //Uint8List result = await FlutterNfcKit.transceive<Uint8List>(bytes);
    String result = await FlutterNfcKit.transceive(command);

    print(result);
    return true;

  }

  Future<bool> verifyPin() async{
    String CLASS = "00";
    String INSTRUCTION = "20";
    String PARAM1 = "00";
    String PARAM2 = "11";
    String LC = "0C";
    String LE = "00";

    String dataIN = "313233340000000000000000"; //IAS AID

    String command = CLASS+INSTRUCTION+PARAM1+PARAM2+LC+dataIN+LE;

    Uint8List bytes = hexStringToByteArray(command);

    String result = await FlutterNfcKit.transceive(command);
    print(result);
    return true;
  }

  Uint8List hexStringToByteArray(String s) {
    int len = s.length;
    Uint8List data = Uint8List(len ~/ 2);
    for (int i = 0; i < len; i += 2) {
      int piece= (hex.decode(s.substring(i, i+2))[0] ) ;
      data[i ~/ 2] = piece;
    }
    return data;
  }

}