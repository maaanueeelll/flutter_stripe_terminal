//
//  FlutterStripeTerminalChannelHandler.swift
//  flutter_stripe_terminal
//
//  Created by Vishal Dubey on 03/12/21.
//

import Flutter

public func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String : Any?] else {
        result(FlutterError(code: "NO_ARGUMENTS_PROVIDED", message: "No arguments were provided. If this call uses no arguments, provide an empty Map<String, Object>.", details: nil))
        return
    }
    
    switch(call.method) {
    case "setConnectionTokenParams":
        FlutterStripeTerminal.shared.setConnectionTokenParams(serverUrl: arguments["serverUrl"] as! String, authToken: arguments["authToken"] as! String, requestType: arguments["requestType"] as! String,  result: result)
    case "searchForReaders":
        FlutterStripeTerminal.shared.searchForReaders(simulated: arguments["simulated"] as! Bool,result: result)
    case "connectToReader":
        FlutterStripeTerminal.shared.connectToReader(readerSerialNumber: arguments["readerSerialNumber"] as! String, locationId: arguments["locationId"] as! String, result: result)
    case "processPayment":
        FlutterStripeTerminal.shared.processPayment(clientSecret: arguments["clientSecret"] as! String, result: result)
    case "updateReader":
        FlutterStripeTerminal.shared.updateReader(result: result)
    case "connectionStatus":
        FlutterStripeTerminal.shared.connectionsStatus(result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
}
