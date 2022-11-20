import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter_stripe_terminal/flutter_stripe_terminal.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Reader> readers = [];

  @override
  void initState() {
    super.initState();
    FlutterStripeTerminal.setConnectionTokenParams(serverUrl: 'https://wholedata.io/appcomande/connection-token/', authToken: '', requestType: 'GET')
        .then((value) => FlutterStripeTerminal.startTerminalEventStream())
        .then((value) => FlutterStripeTerminal.searchForReaders(simulated: true))
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
      print(updateStatus);
    });

    FlutterStripeTerminal.readerEvent.listen((ReaderEvent readerEvent) {
      print(readerEvent);
    });

    FlutterStripeTerminal.readerInputEvent.listen((String readerInputEvent) {
      print(readerInputEvent);
    });
  }

  void initiatePayment() async {
    final url = Uri.parse("https://wholedata.io/appcomande/payment-intent-test/");
    final response = await http.post(url, body: {'amount': '1'});

    print(response.statusCode);
    print(response.body);

    String intentId = await FlutterStripeTerminal.processPayment(jsonDecode(response.body)['client_secret']);

    print(intentId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Stripe Terminal'),
          ),
          body: readers.length == 0
              ? Center(
                  child: Text('No devices found'),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(5),
                          child: ElevatedButton(
                              onPressed: () {
                                FlutterStripeTerminal.updateReader();
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
                          child: ElevatedButton(onPressed: () {}, child: Text('Dsconnect')),
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
                    ListView.builder(
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
                    )
                  ],
                )),
    );
  }
}
