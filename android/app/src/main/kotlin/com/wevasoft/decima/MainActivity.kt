package com.wevasoft.decima

import android.app.UiModeManager
import android.content.Context
import android.os.Build
import android.view.View
import android.view.ViewGroup
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * A primeira tecla física tira a janela do touch mode, e a partir daí o
     * Android desenha o realce de foco padrão na view focada. Como a
     * `FlutterView` ocupa a tela inteira, o realce vira uma moldura na borda do
     * app (verde no One UI). O feedback de foco do app é o glow do botão
     * equivalente no keypad — o realce do sistema só polui a tela.
     */
    override fun onStart() {
        super.onStart()
        disableDefaultFocusHighlight(window.decorView)
    }

    /** `defaultFocusHighlightEnabled` existe da API 26 em diante; abaixo disso
     * o framework não desenha o realce e não há o que desligar. */
    private fun disableDefaultFocusHighlight(view: View) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        view.defaultFocusHighlightEnabled = false
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                disableDefaultFocusHighlight(view.getChildAt(index))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.wevasoft.decima/night_mode",
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
