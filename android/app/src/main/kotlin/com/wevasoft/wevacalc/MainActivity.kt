package com.wevasoft.wevacalc

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.wevasoft.wevacalc/night_mode",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setApplicationNightMode" -> {
                    // O sistema persiste a preferência por app e a aplica também na
                    // splash screen das próximas inicializações. Sem efeito < API 31,
                    // onde a splash segue apenas o dark mode do sistema.
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val dark = call.argument<Boolean>("dark") == true
                        val uiModeManager =
                            getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
                        uiModeManager.setApplicationNightMode(
                            if (dark) UiModeManager.MODE_NIGHT_YES
                            else UiModeManager.MODE_NIGHT_NO,
                        )
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
