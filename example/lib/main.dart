import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_stripe_terminal/flutter_stripe_terminal.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

final DOMAIN = 'https://wholedata.io';
final SERIAL = 'WPC323211067225';
//final SERIAL = '';
final LOCATION = 'tml_E3xJlw22PhZZ6J';
bool _updateAvailable = false;
bool _isConnected = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  checkPermission();

  List<Reader> readers = [];

  FlutterStripeTerminal.setConnectionTokenParams(serverUrl: '${DOMAIN}/appcomande/connection-token/', authToken: '', requestType: 'GET')
      .then((value) async {
    FlutterStripeTerminal.startTerminalEventStream();
  }).then((value) async {
    FlutterStripeTerminal.searchForReaders(simulated: false);
  }).then((value) async {
    FlutterStripeTerminal.readersList.listen((List<Reader> readersList) async {
      readers = readersList;

      for (var element in readers) {
        if (!_isConnected) {
          if (element.serialNumber == SERIAL) {
            bool? check = await FlutterStripeTerminal.connectToReader(SERIAL, 'tml_E3xJlw22PhZZ6J');
            if (check!) {
              FlutterStripeTerminal.connectionStatus().then((value) {
                print('BOOL ${value}');
                switch (value) {
                  case 'connected':
                    _isConnected = true;
                    break;
                  case 'not_connected':
                    _isConnected = false;
                    break;
                  case 'connceting':
                    _isConnected = false;
                    break;
                  default:
                }
              });
            }
          }
        }
      }
    });
  }).catchError((error) => print(error));

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

Future<bool> initiatePayment() async {
  final url = Uri.parse("${DOMAIN}/appcomande/payment-intent-test/");
  final response = await http.post(url, body: {'amount': '40'});

  final intent = await FlutterStripeTerminal.processPayment(jsonDecode(response.body)['client_secret']);
  print(intent);

  return true;
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
    // checkPermission();
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
  bool _showLoader = false;
  double _progress = 0.0;
  String _textToDisplayLoader = 'Attendere..';
  List<Reader> readers = [];

  @override
  void initState() {
    super.initState();

    // FlutterStripeTerminal.readerConnectionStatus.listen((ReaderConnectionStatus connectionStatus) {
    //   print(connectionStatus);
    //   switch (connectionStatus.index) {
    //     case 0:
    //       _isConnected = true;
    //       setState(() {});
    //       break;
    //   }
    // });

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
          //  _updateAvailable = true;
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
        case 10:
          _textToDisplayLoader = '';
          _showLoader = false;
          setState(() {});
          break;
        case 11:
          _textToDisplayLoader = 'Controllare il lettore..';
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
      // _showLoader = true;
      setState(() {});
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
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: readers.length,
                    itemBuilder: (context, position) {
                      if (readers.isEmpty) {
                        return Center(
                          child: Text('No devices found'),
                        );
                      } else {
                        return ListTile(
                          onTap: () async {
                            await FlutterStripeTerminal.connectToReader(readers[position].serialNumber, LOCATION);
                          },
                          title: Text(readers[position].deviceName),
                        );
                      }
                    },
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(5),
                        child: ElevatedButton(
                            onPressed: () async {
                              FlutterStripeTerminal.searchForReaders(simulated: false);
                              FlutterStripeTerminal.readersList.listen((List<Reader> readersList) async {
                                readers = readersList;

                                for (var element in readers) {
                                  if (!_isConnected) {
                                    if (element.serialNumber == SERIAL) {
                                      bool? check = await FlutterStripeTerminal.connectToReader(SERIAL, 'tml_E3xJlw22PhZZ6J');
                                      if (check!) {
                                        FlutterStripeTerminal.connectionStatus().then((value) {
                                          print('BOOL ${value}');
                                          switch (value) {
                                            case 'connected':
                                              _isConnected = true;
                                              break;
                                            case 'not_connected':
                                              _isConnected = false;
                                              break;
                                            case 'connceting':
                                              _isConnected = false;
                                              break;
                                            default:
                                          }
                                        });
                                      }
                                    }
                                  }
                                }
                                setState(() {});
                              });
                            },
                            child: Text('Search reader')),
                      ),
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
                              onPressed: () async {
                                bool check = await initiatePayment();

                                if (check) {
                                  setState(() {
                                    _showLoader = false;
                                    _textToDisplayLoader = '';
                                  });
                                }
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
