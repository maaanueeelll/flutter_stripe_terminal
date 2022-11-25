import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_stripe_terminal/flutter_stripe_terminal.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

final DOMAIN = 'https://wholedata.io';
final SERIAL = 'WPC323211067225';

final LOCATION = 'tml_E3xJlw22PhZZ6J';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

void initiatePayment() async {
  final url = Uri.parse("${DOMAIN}/appcomande/payment-intent-test/");
  final response = await http.post(url, body: {'amount': '40'});

  final intent = await FlutterStripeTerminal.processPayment(jsonDecode(response.body)['client_secret']);
  print(intent);
}

void checkPermission() async {
  var status = await Permission.location.status;

  if (status.isGranted) {
  } else {
    Map<Permission, PermissionStatus> status = await [Permission.location].request();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    checkPermission();
    return MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool _updateAvailable = false;
  bool _isConnected = false;
  bool _showLoader = false;
  double _progress = 0.0;
  String _textToDisplayLoader = 'Attendere..';
  List<Reader> readers = [];

  @override
  void initState() {
    super.initState();

    FlutterStripeTerminal.setConnectionTokenParams(serverUrl: '${DOMAIN}/appcomande/connection-token/', authToken: '', requestType: 'GET')
        .then((value) async {
          FlutterStripeTerminal.startTerminalEventStream();
        })
        .then((value) async {
          FlutterStripeTerminal.searchForReaders(simulated: false);
        })
        .then((value) async {})
        .catchError((error) => print(error));

    FlutterStripeTerminal.readersList.listen((List<Reader> readersList) {
      setState(() {
        readers = readersList;
      });
      for (var element in readers) {
        if (!_isConnected) {
          if (element.serialNumber == SERIAL) {
            FlutterStripeTerminal.connectToReader(SERIAL, 'tml_E3xJlw22PhZZ6J');
          }
        }
      }
    });

    FlutterStripeTerminal.readerConnectionStatus.listen((ReaderConnectionStatus connectionStatus) {
      switch (connectionStatus.index) {
        case 0:
          _isConnected = true;
          setState(() {});
          break;
      }
    });

    FlutterStripeTerminal.readerPaymentStatus.listen((ReaderPaymentStatus paymentStatus) {
      print('INDEX ${paymentStatus.index}');
      print(paymentStatus.name);

      switch (paymentStatus.index) {
        case 1:
          _textToDisplayLoader = '';
          _showLoader = false;
          setState(() {});
          break;
        case 2:
          _textToDisplayLoader = 'Avvicinare la carta..';
          _showLoader = true;
          setState(() {});
          break;
        case 3:
          _textToDisplayLoader = 'Pagamento in corso..';
          _showLoader = true;
          setState(() {});
          break;
      }
    });

    FlutterStripeTerminal.readerUpdateStatus.listen((ReaderUpdateStatus updateStatus) {
      switch (updateStatus.index) {
        case 0:
          _updateAvailable = true;
          setState(() {});
          break;
        case 1:
          _showLoader = true;
          setState(() {});
          break;
        case 2:
          break;
        case 3:
          _showLoader = false;
          setState(() {});
          break;
      }
    });

    FlutterStripeTerminal.readerProgressUpdate.listen((double progress) {
      _progress = progress * 100;
      _textToDisplayLoader = 'Updating reader, do not exit\n${_progress.round()}%';
      setState(() {});
    });

    FlutterStripeTerminal.readerEvent.listen((ReaderEvent readerEvent) {
      print('INDEX ${readerEvent.index}');

      print(readerEvent.name);
      switch (readerEvent.index) {
        case 2:
          _textToDisplayLoader = 'Inserire di nuovo la carta..';
          _showLoader = true;
          setState(() {});
          break;
        case 3:
          _textToDisplayLoader = 'Inserire carta..';
          _showLoader = true;
          setState(() {});
          break;
        case 4:
          _textToDisplayLoader = 'Inserire la carta..';
          _showLoader = true;
          setState(() {});
          break;
        case 6:
          _textToDisplayLoader = 'Rimuovere la carta..';
          _showLoader = true;
          setState(() {});
          break;
        default:
          _textToDisplayLoader = '';
          _showLoader = false;
          setState(() {});
          break;
      }
    });

    FlutterStripeTerminal.readerInputEvent.listen((String readerInputEvent) {
      // print(readerInputEvent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Terminal'),
        actions: [IconButton(onPressed: (() => setState(() {})), icon: Icon(Icons.refresh_rounded))],
      ),
      body: _showLoader
          ? Dialog(
              // The background color
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    // The loading indicator
                    CircularProgressIndicator(
                        // color: greenLogo,
                        ),
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      _textToDisplayLoader,
                      textAlign: TextAlign.center,
                      //    style: TextStyle(color: greyLogo),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            )
          : readers.length == 0
              ? Center(
                  child: Text('No devices found'),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: readers.length,
                        itemBuilder: (context, position) {
                          return ListTile(
                            onTap: () async {
                              await FlutterStripeTerminal.connectToReader(readers[position].serialNumber, LOCATION);
                            },
                            title: Text(readers[position].deviceName),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_updateAvailable && _isConnected)
                            Padding(
                              padding: EdgeInsets.all(5),
                              child: ElevatedButton(
                                  onPressed: () async {
                                    await FlutterStripeTerminal.updateReader();
                                  },
                                  child: Text('Update reader')),
                            ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: ElevatedButton(
                                onPressed: () async {
                                  String? conn = await FlutterStripeTerminal.connectionStatus();
                                  print(conn);
                                },
                                child: Text('Check connection')),
                          ),
                          //  Padding(
                          //    padding: EdgeInsets.all(5),
                          //    child: ElevatedButton(onPressed: () {}, child: Text('Check update')),
                          //  ),
                          if (_isConnected)
                            Padding(
                              padding: EdgeInsets.all(5),
                              child: ElevatedButton(
                                  onPressed: () async {
                                    await FlutterStripeTerminal.disconnectReader();
                                  },
                                  child: Text('Disconnect')),
                            ),
                          if (_isConnected)
                            Padding(
                              padding: EdgeInsets.all(5),
                              child: ElevatedButton(
                                  onPressed: () {
                                    initiatePayment();
                                  },
                                  child: Text('Initiate payment')),
                            ),
                        ],
                      ),
                    )
                  ],
                ),
    );
  }
}

Dialog CustomLoader(String action) {
  return Dialog(
    // The background color
    backgroundColor: Colors.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 15,
          ),
          // The loading indicator
          CircularProgressIndicator(
              // color: greenLogo,
              ),
          const SizedBox(
            height: 15,
          ),
          Text(
            action,
            //    style: TextStyle(color: greyLogo),
          ),
          const SizedBox(
            height: 15,
          ),
        ],
      ),
    ),
  );
}
