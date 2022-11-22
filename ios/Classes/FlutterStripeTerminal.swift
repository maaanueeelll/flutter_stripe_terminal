//
//  FlutterStripeTerminal.swift
//  flutter_stripe_terminal
//
//  Created by Vishal Dubey on 03/12/21.
//

import Foundation
import StripeTerminal
import Flutter

class FlutterStripeTerminal {
    static let shared = FlutterStripeTerminal()
    
    var serverUrl: String?
    var authToken: String?
    var requestType: String?
    var availableReaders: [Reader]?
    
    func setConnectionTokenParams(serverUrl: String, authToken: String, requestType:String, result: FlutterResult) {
        self.serverUrl = serverUrl
        self.authToken = authToken
        self.requestType = requestType
        result(true)
    }
    
    func searchForReaders(simulated: Bool, result: @escaping FlutterResult) {
        let config = DiscoveryConfiguration(discoveryMethod: DiscoveryMethod.bluetoothScan, simulated: simulated)
        Terminal.shared.discoverReaders(config, delegate: FlutterStripeTerminalEventHandler.shared) { error in
            DispatchQueue.main.async {
                if let error = error {
                    result(error)
                } else {
                    result(true)
                }
            }
        }
    }
    
    func connectToReader(readerSerialNumber: String, locationId: String, result: @escaping FlutterResult) {
        let conn = Terminal.shared.connectedReader
        if conn == nil {
            let selectedReaders = self.availableReaders?.filter { reader in
                return reader.serialNumber == readerSerialNumber
            }
            if (!selectedReaders!.isEmpty) {
                Terminal.shared.connectBluetoothReader(selectedReaders![0], delegate: FlutterStripeTerminalEventHandler.shared, connectionConfig: BluetoothConnectionConfiguration(locationId: locationId, autoReconnectOnUnexpectedDisconnect: true, autoReconnectionDelegate: FlutterStripeTerminalEventHandler.shared)) { _, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            result(error)
                        } else {
                            result(true)
                        }
                    }
                }
            }
        }
    }
    
    func updateReader(result: @escaping FlutterResult) {
        let conn = Terminal.shared.connectedReader
        if conn != nil {
            Terminal.shared.installAvailableUpdate()
        }
    }
    
    
    func connectionsStatus(result: @escaping FlutterResult) {
        
        let conn = Terminal.shared.connectionStatus
        print(conn)
    }

    
    func disconnectReader() {
        Terminal.shared.disconnectReader {error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error disconnection")
                    print(error)
                } else {
                    print("disconnection complete")
                    
                }
            }
            
        }
        
    }
    
    
    func processPayment(clientSecret: String, result: @escaping FlutterResult) {
        let terminal = Terminal.shared
        terminal.retrievePaymentIntent(clientSecret: clientSecret) { retrievedIntent, retrievedError in
            if let retrievedPaymentIntent = retrievedIntent {
                terminal.collectPaymentMethod(retrievedPaymentIntent) { processedIntent, processedError in
                    if let processedPaymentIntent = processedIntent {
                        terminal.processPayment(processedPaymentIntent) {finalIntent, finalError in
                            if let finalPaymentIntent = finalIntent {
                                result([
                                    "paymentIntentId": finalPaymentIntent.stripeId
                                ])
                            } else if let finalError = finalError {
                                DispatchQueue.main.async {
                                    print(finalError)
                                    result(finalError)
                                }
                            }
                        }
                    } else if let processedError = processedError {
                        DispatchQueue.main.async {
                            print(processedError)
                            result(processedError)
                        }
                    }
                }
            } else if let retrievedError = retrievedError {
                DispatchQueue.main.async {
                    print(retrievedError)
                    result(retrievedError)
                }
            }
        }
    }
    
}
