package `in`.edu.iiitnr.campus_mobile

import android.app.Notification
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

/**
 * Listens for incoming email/SMS notifications (e.g., Gmail, Outlook, Messages)
 * containing a Northstar verification code and forwards the 6-digit OTP to Flutter.
 * Requires the user to enable Notification Access for Northstar in Android Settings.
 */
class OtpNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val OTP_MAX_AGE_MS = 180_000L
        private val CONTEXT_REGEX = Regex(
            pattern = "verification\\s+code|northstar|\\botp\\b",
            option = RegexOption.IGNORE_CASE,
        )
        private val CODE_REGEX = Regex("\\b(\\d{6})\\b")

        private val mainHandler = Handler(Looper.getMainLooper())
        private val lock = Any()

        @Volatile
        var eventSink: EventChannel.EventSink? = null

        private var lastOtp: String? = null
        private var lastTimestampMs: Long = 0L

        fun consumeLatestOtp(): String? = synchronized(lock) {
            val otp = lastOtp ?: return null
            if (System.currentTimeMillis() - lastTimestampMs > OTP_MAX_AGE_MS) {
                lastOtp = null
                lastTimestampMs = 0L
                return null
            }
            lastOtp = null
            lastTimestampMs = 0L
            otp
        }

        internal fun extractOtpFromTexts(texts: List<String>): String? {
            val combined = texts.joinToString("\n").trim()
            if (combined.isEmpty()) return null
            if (!CONTEXT_REGEX.containsMatchIn(combined)) return null
            return CODE_REGEX.find(combined)?.groupValues?.getOrNull(1)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val notification = sbn?.notification ?: return
        if (sbn.packageName == applicationContext.packageName) return

        val extras = notification.extras ?: return
        val texts = mutableListOf<String>()

        listOf(
            Notification.EXTRA_TITLE,
            Notification.EXTRA_TEXT,
            Notification.EXTRA_BIG_TEXT,
            Notification.EXTRA_SUB_TEXT,
            Notification.EXTRA_SUMMARY_TEXT,
        ).forEach { key ->
            extras.getCharSequence(key)?.toString()?.takeIf { it.isNotBlank() }?.let(texts::add)
        }

        extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)?.forEach { line ->
            line?.toString()?.takeIf { it.isNotBlank() }?.let(texts::add)
        }

        val otp = extractOtpFromTexts(texts) ?: return

        synchronized(lock) {
            lastOtp = otp
            lastTimestampMs = System.currentTimeMillis()
        }

        mainHandler.post {
            eventSink?.success(otp)
        }
    }
}
