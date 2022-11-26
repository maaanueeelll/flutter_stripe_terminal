//
//  FlutterStripeTerminalEventHandler.swift
//  flutter_stripe_terminal
//
//  Created by Vishal Dubey on 03/12/21.
//

import Foundation
import Flutter
import StripeTerminal

class FlutterStripeTerminalEventHandler: NSObject, FlutterStreamHandler, DiscoveryDelegate, TerminalDelegate, BluetoothReaderDelegate, ReconnectionDelegate {
    
    
    static let shared = FlutterStripeTerminalEventHandler()
    var eventSink: FlutterEventSink?
    
    func terminal(_ terminal: Terminal, didStartReaderReconnect cancelable: Cancelable) {
        eventSink!([
            "readerReconnectionStatus": "READER_RECONNECTION"
        ])
    }
    
    func terminalDidSucceedReaderReconnect(_ terminal: Terminal) {
        eventSink!([
            "readerReconnectionStatus": "READER_RECONNECTION_SUCCEDED"
        ])
    }
    
    func terminalDidFailReaderReconnect(_ terminal: Terminal) {
        eventSink!([
            "readerReconnectionStatus": "READER_RECONNECTION_FAILED"
        ])
    }
    
    
    func reader(_ reader: Reader, didReportAvailableUpdate update: ReaderSoftwareUpdate) {
        eventSink!([
            "readerUpdateStatus": "UPDATE_AVAILABLE"
        ])
    }
    
    func reader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: Cancelable?) {
        eventSink!([
            "readerUpdateStatus": "STARTING_UPDATE_INSTALLATION"
        ])
    }
    
    func reader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
        
        eventSink!([
            "readerUpdateStatus": "SOFTWARE_UPDATE_IN_PROGRESS",
            //"readerProgressStatus": progress
        ])
        eventSink!([
            // "readerUpdateStatus": "SOFTWARE_UPDATE_IN_PROGRESS",
            "readerProgressStatus": progress
        ])
    }
    
    func reader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        eventSink!([
            "readerUpdateStatus": "FINISHED_UPDATE_INSTALLATION"
        ])
    }
    
    func reader(_ reader: Reader, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        print("IMPUT EVENT")
        print(Terminal.stringFromReaderInputOptions(inputOptions))
      
        switch Terminal.stringFromReaderInputOptions(inputOptions)
        {
      
            
        case "Insert / Tap":
            eventSink!([
                // "readerEvent": Terminal.stringFromReaderDisplayMessage(displayMessage)
                "readerEvent": "INSERT_CARD"
            ])
        default:
            break
            
        }
    }
    
    func reader(_ reader: Reader, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        print("DISPLAY EVENT")
        print(Terminal.stringFromReaderDisplayMessage(displayMessage))
        switch Terminal.stringFromReaderDisplayMessage(displayMessage)
        {
        case "Remove Card":
            eventSink!([
                // "readerEvent": Terminal.stringFromReaderDisplayMessage(displayMessage)
                "readerEvent": "REMOVE_CARD"
            ])
            
        case "Insert / Tap":
            eventSink!([
                // "readerEvent": Terminal.stringFromReaderDisplayMessage(displayMessage)
                "readerEvent": "INSERT_CARD"
            ])
        default:
            break
            
        }
        
        
    }
    
    func reader(_ reader: Reader, didReportBatteryLevel batteryLevel: Float, status: BatteryStatus, isCharging: Bool) {
        eventSink!([
            "readerEvent": "LOW_BATTERY"
        ])
    }
    
    func reader(_ reader: Reader, didReportReaderEvent event: ReaderEvent , info: [AnyHashable : Any]?) {
        print("REPORT REDADER EVENT")
        print(Terminal.stringFromReaderEvent(event))
        switch Terminal.stringFromReaderEvent(event){
            
        case "Card Inserted":
            eventSink!([
                "readerEvent": "CARD_INSERTED"
            ])
        case "Card Removed":
            eventSink!([
                "readerEvent": "CARD_REMOVED"
            ])
        default:
            break
        }
        
        
        
    }
    
    func terminal(_ terminal: Terminal, didChangePaymentStatus status: PaymentStatus) {
        print("PAYMENT STATUS")
        print(Terminal.stringFromPaymentStatus(status))
        eventSink!([
            "readerPaymentStatus": Terminal.stringFromPaymentStatus(status)
        ])
    }
    
    func terminal(_ terminal: Terminal, didChangeConnectionStatus status: ConnectionStatus) {
        print("CONNECTION STSTUS")
        print(Terminal.stringFromConnectionStatus(status))
        eventSink!([
            "readerConnectionStatus": Terminal.stringFromConnectionStatus(status)
        ])
    }
    
    func terminal(_ terminal: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
        eventSink!([
            "readerConnectionStatus": "DISCONNECTED"
        ])
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        Terminal.setTokenProvider(APIClient.shared)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
    
    func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        FlutterStripeTerminal.shared.availableReaders = readers
        eventSink!([
            "deviceList": readers.map{
                reader in
                return [
                    "serialNumber": reader.serialNumber,
                    "deviceName": Terminal.stringFromDeviceType(reader.deviceType)
                ]
            }
        ])
    }
    
}
