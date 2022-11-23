import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_stripe_terminal/flutter_stripe_terminal.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

void initiatePayment() async {
  final url = Uri.parse("https://wholedata.io/appcomande/payment-intent-test/");
  final response = await http.post(url, body: {'amount': '1'});

  final intentId = await FlutterStripeTerminal.processPayment(jsonDecode(response.body)['client_secret']);
  print(intentId);
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
  bool _isupdating = false;
  double _progress = 0.0;
  List<Reader> readers = [];

  @override
  void initState() {
    super.initState();

    FlutterStripeTerminal.setConnectionTokenParams(serverUrl: 'https://wholedata.io/appcomande/connection-token/', authToken: '', requestType: 'GET')
        .then((value) => FlutterStripeTerminal.startTerminalEventStream())
        .then((value) => FlutterStripeTerminal.searchForReaders(simulated: false))
        .catchError((error) => print(error));

    FlutterStripeTerminal.readersList.listen((List<Reader> readersList) {
      setState(() {
        readers = readersList;
      });
    });

    FlutterStripeTerminal.readerConnectionStatus.listen((ReaderConnectionStatus connectionStatus) {
      print(connectionStatus);
    });

    FlutterStripeTerminal.readerPaymentStatus.listen((ReaderPaymentStatus paymentStatus) {
      print(paymentStatus);
    });

    FlutterStripeTerminal.readerUpdateStatus.listen((ReaderUpdateStatus updateStatus) {
      switch (updateStatus.index) {
        case 0:
          _updateAvailable = true;
          setState(() {});
          break;
        case 1:
          print('Starting update reader');
          _isupdating = true;
          setState(() {});
          break;
        case 2:
          break;
        case 3:
          print('UPdate Finished');
          _isupdating = false;
          setState(() {});
          break;
      }
    });

    FlutterStripeTerminal.readerProgressUpdate.listen((double progress) {
      _progress = progress * 100;
      _progress = _progress;
      setState(() {});
    });

    FlutterStripeTerminal.readerEvent.listen((ReaderEvent readerEvent) {
      print(readerEvent);
    });

    FlutterStripeTerminal.readerInputEvent.listen((String readerInputEvent) {
      print(readerInputEvent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Terminal'),
        actions: [IconButton(onPressed: (() => setState(() {})), icon: Icon(Icons.refresh_rounded))],
      ),
      body: _isupdating
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
                      'Updating reader, do not exit\n${_progress.round()}%',
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
                              await FlutterStripeTerminal.connectToReader(readers[position].serialNumber, "tml_E3RA4QYozwFugz");
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
                          if (_updateAvailable)
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
                                onPressed: () {
                                  FlutterStripeTerminal.connectionStatus();
                                },
                                child: Text('Check connection')),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: ElevatedButton(onPressed: () {}, child: Text('Check update')),
                          ),
                          Padding(
                            padding: EdgeInsets.all(5),
                            child: ElevatedButton(
                                onPressed: () async {
                                  await FlutterStripeTerminal.disconnectReader();
                                },
                                child: Text('Disconnect')),
                          ),
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
