package com.alihaidar.money_scribe

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * The fingerprint dialog of the app lock needs a FragmentActivity.
 *
 * In the production build the window is secure: the app is blank in the list of
 * recent apps and cannot be captured by a screenshot or a screen recording.
 * Staging builds stay open to capture, so the screens can be checked.
 */
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (BuildConfig.SECURE_WINDOW) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }
}
