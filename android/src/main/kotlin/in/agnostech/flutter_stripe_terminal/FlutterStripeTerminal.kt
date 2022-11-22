package `in`.agnostech.flutter_stripe_terminal
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.stripe.stripeterminal.Terminal
import com.stripe.stripeterminal.external.callable.*
import com.stripe.stripeterminal.external.models.*
import com.stripe.stripeterminal.log.LogLevel
import io.flutter.plugin.common.MethodChannel

class FlutterStripeTerminal {
    companion object {
        lateinit var serverUrl: String
        lateinit var authToken: String
        lateinit var context: Context
        var simulated: Boolean = false
        var availableReadersList: List<Reader>? = null
        var flutterStripeTerminalEventHandler: FlutterStripeTerminalEventHandler? = null
        var cancelDiscovery: Cancelable? = null;


        // Choose the level of messages that should be logged to your console
        val logLevel = LogLevel.VERBOSE

        // Create your token provider.
        val tokenProvider = TokenProvider()


        fun setConnectionTokenParams(
            serverUrl: String,
            authToken: String,
            result: MethodChannel.Result
        ) {
            this.serverUrl = serverUrl
            this.authToken = authToken
            result.success(true)
        }

        fun disconnectReader(result: MethodChannel.Result) {

            val terminal = Terminal.getInstance()

            if(terminal.connectionStatus.toString() == "CONNECTED") {
                cancelDiscovery?.cancel(object : Callback {
                    override fun onFailure(e: TerminalException) {
                        Handler(Looper.getMainLooper()).post {
                        }
                    }

                    override fun onSuccess() {
                        Handler(Looper.getMainLooper()).post {
                        }
                    }

                })
                Terminal.getInstance().disconnectReader(object : Callback {
                    override fun onFailure(e: TerminalException) {
                        Handler(Looper.getMainLooper()).post {
                            result.error(e.errorCode.toLogString(), e.message, null)
                        }
                    }

                    override fun onSuccess() {
                        Handler(Looper.getMainLooper()).post {
                            result.success(true)
                        }
                    }

                })
            }
        }

        fun searchForReaders(simulated: Boolean, result: MethodChannel.Result) {

            val config = DiscoveryConfiguration(
              //  timeout= 40,
                discoveryMethod = DiscoveryMethod.BLUETOOTH_SCAN,
                isSimulated = simulated,
            )

            if (Terminal.isInitialized()) {

                cancelDiscovery = Terminal.getInstance().discoverReaders(
                    config,
                    flutterStripeTerminalEventHandler!!.getDiscoveryListener(),
                    object : Callback {
                        override fun onSuccess() {
                            Handler(Looper.getMainLooper()).post {
                                result.success(true)
                            }
                        }

                        override fun onFailure(e: TerminalException) {
                            Handler(Looper.getMainLooper()).post {
                                result.error(e.errorCode.toLogString(), e.message, null)
                            }
                        }
                    })
            } else {
            }

        }

        fun connectToReader(
            readerSerialNumber: String,
            locationId: String,
            result: MethodChannel.Result
        ) {
            val terminal = Terminal.getInstance()
            if(terminal.connectionStatus.toString() == "NOT_CONNECTED") {

                val reader = availableReadersList!!.filter {
                    it.serialNumber == readerSerialNumber
                }

                if (reader.isNotEmpty()) {
                    Terminal.getInstance().connectBluetoothReader(reader[0],
                        ConnectionConfiguration.BluetoothConnectionConfiguration(locationId),
                        flutterStripeTerminalEventHandler!!.getBluetoothReaderListener(),
                        object : ReaderCallback {
                            override fun onFailure(e: TerminalException) {
                                Handler(Looper.getMainLooper()).post {
                                    result.error(e.errorCode.toLogString(), e.message, null)
                                }
                            }

                            override fun onSuccess(reader: Reader) {
                                Handler(Looper.getMainLooper()).post {
                                    result.success(true)
                                }
                            }
                        })
                }
            }
        }


        fun connectionStatus(result: MethodChannel.Result){
            val terminal = Terminal.getInstance()
                result.success(terminal.connectionStatus.toString())


        }

        fun updateReader(result: MethodChannel.Result){
            val terminal = Terminal.getInstance()

            if(terminal.connectionStatus.toString() == "CONNECTED") {

              terminal.installAvailableUpdate()
                result.success(true)
            }
        }

        fun checkUpdateReader(result: MethodChannel.Result){
            val terminal = Terminal.getInstance()
            if(terminal.connectionStatus.toString() == "CONNECTED") {

            }
        }

        fun processPayment(clientSecret: String, result: MethodChannel.Result) {
            val terminal = Terminal.getInstance()

            terminal.retrievePaymentIntent(clientSecret, object : PaymentIntentCallback {
                override fun onFailure(e: TerminalException) {
                    Handler(Looper.getMainLooper()).post {
                        result.error(e.errorCode.toLogString(), e.message, null)
                    }
                }

                override fun onSuccess(paymentIntent: PaymentIntent) {
                    Handler(Looper.getMainLooper()).post {
                        terminal.collectPaymentMethod(
                            paymentIntent,
                            object : PaymentIntentCallback {
                                override fun onFailure(e: TerminalException) {
                                    Handler(Looper.getMainLooper()).post {
                                        result.error(e.errorCode.toLogString(), e.message, null)
                                    }
                                }

                                override fun onSuccess(paymentIntent: PaymentIntent) {
                                    terminal.processPayment(
                                        paymentIntent,
                                        object : PaymentIntentCallback {
                                            override fun onFailure(e: TerminalException) {
                                                Handler(Looper.getMainLooper()).post {
                                                    result.error(
                                                        e.errorCode.toLogString(),
                                                        e.message,
                                                        null
                                                    )
                                                }
                                            }

                                            override fun onSuccess(paymentIntent: PaymentIntent) {
                                                Handler(Looper.getMainLooper()).post {
                                                    result.success(
                                                        mapOf(
                                                            "paymentIntentId" to paymentIntent.id
                                                        )
                                                    )
                                                }
                                            }
                                        })
                                }
                            })
                    }
                }
            })
        }
    }
}
