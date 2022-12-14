import 'dart:async';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe_terminal/reader.dart';
import 'package:flutter_stripe_terminal/utils.dart';
import 'package:rxdart/subjects.dart';

export 'package:flutter_stripe_terminal/utils.dart';
export 'package:flutter_stripe_terminal/reader.dart';

class FlutterStripeTerminal {
  static const MethodChannel _channel = const MethodChannel('flutter_stripe_terminal/methods');

  static const EventChannel _eventChannel = const EventChannel('flutter_stripe_terminal/events');

  static BehaviorSubject<ReaderConnectionStatus> readerConnectionStatus = BehaviorSubject<ReaderConnectionStatus>();
  static BehaviorSubject<ReaderPaymentStatus> readerPaymentStatus = BehaviorSubject<ReaderPaymentStatus>();
  static BehaviorSubject<ReaderUpdateStatus> readerUpdateStatus = BehaviorSubject<ReaderUpdateStatus>();
  static BehaviorSubject<ReaderEvent> readerEvent = BehaviorSubject<ReaderEvent>();
  static BehaviorSubject<String> readerInputEvent = BehaviorSubject<String>();
  static BehaviorSubject<double> readerProgressUpdate = BehaviorSubject<double>();
  static BehaviorSubject<List<Reader>> readersList = BehaviorSubject<List<Reader>>();

  static Future<T?> _invokeMethod<T>(
    String method, {
    Map<String, Object> arguments = const {},
  }) {
    return _channel.invokeMethod<T>(method, arguments);
  }

  static Future<bool?> setConnectionTokenParams({required String serverUrl, required String authToken, required String requestType}) async {
    return _invokeMethod<bool>("setConnectionTokenParams", arguments: {"serverUrl": serverUrl, "authToken": authToken, "requestType": requestType});
  }

  static Future<bool?> searchForReaders({required bool simulated}) async {
    return _invokeMethod<bool>("searchForReaders", arguments: {"simulated": simulated});
  }

  static Future<String?> connectionStatus() async {
    return _invokeMethod<String>("connectionStatus");
  }

  static Future<bool?> connectToReader(String readerSerialNumber, String locationId) async {
    return _invokeMethod<bool>("connectToReader", arguments: {"readerSerialNumber": readerSerialNumber, "locationId": locationId});
  }

  static Future<Map<String, String>> processPayment(String clientSecret) async {
    return Map<String, String>.from(await _invokeMethod('processPayment', arguments: {"clientSecret": clientSecret}));
  }

  static Future<bool?> disconnectReader() async {
    return _invokeMethod<bool>("disconnectReader");
  }

  static Future<bool?> updateReader() async {
    return _invokeMethod<bool>("updateReader");
  }

  static void startTerminalEventStream() {
    _eventChannel.receiveBroadcastStream().listen((event) {
      final eventData = Map<String, dynamic>.from(event);
      print('EVENT DATA ${eventData}');
      final eventKey = eventData.keys.first;
      switch (eventKey) {
        case "readerConnectionStatus":
          readerConnectionStatus.add(EnumToString.fromString<ReaderConnectionStatus>(ReaderConnectionStatus.values, eventData[eventKey])!);
          break;
        case "readerPaymentStatus":
          readerPaymentStatus.add(EnumToString.fromString(ReaderPaymentStatus.values, eventData[eventKey])!);
          break;
        case "readerUpdateStatus":
          readerUpdateStatus.add(EnumToString.fromString(ReaderUpdateStatus.values, eventData[eventKey])!);
          break;
        case "readerProgressStatus":
          readerProgressUpdate.add(eventData[eventKey]);
          break;
        case "readerEvent":
          readerEvent.add(EnumToString.fromString(ReaderEvent.values, eventData[eventKey])!);
          break;
        case "readerInputEvent":
          readerInputEvent.add(eventData[eventKey]);
          break;
        case "deviceList":
          readersList.add(List<Reader>.from(eventData[eventKey].map((reader) => Reader.fromJson(Map<String, String>.from(reader)))).toList());
          break;
      }
    });
  }

  void dispose() {
    readerConnectionStatus.close();
    readerPaymentStatus.close();
    readerUpdateStatus.close();
    readerEvent.close();
    readersList.close();
    readerInputEvent.close();
  }
}
