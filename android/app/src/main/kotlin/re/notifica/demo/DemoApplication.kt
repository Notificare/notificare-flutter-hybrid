package re.notifica.demo

import io.flutter.BuildConfig
import io.flutter.app.FlutterApplication
import re.notifica.Notificare
import re.notifica.flutter.NotificareReceiver

class DemoApplication: FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        Notificare.shared().setDebugLogging(BuildConfig.DEBUG)
        Notificare.shared().launch(this)
        Notificare.shared().createDefaultChannel()
        Notificare.shared().intentReceiver = NotificareReceiver::class.java
        Notificare.shared().smallIcon = R.drawable.ic_stat_notify_msg
    }
}
