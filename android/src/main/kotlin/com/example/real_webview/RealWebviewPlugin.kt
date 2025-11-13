package com.example.real_webview

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/** RealWebviewPlugin */
class RealWebviewPlugin : FlutterPlugin {
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding = binding

        // Register platform view
        binding.platformViewRegistry.registerViewFactory(
            "real_webview",
            WebViewFactory(binding)
        )

        // Register cookie manager
        val cookieManager = RealCookieManager(binding.binaryMessenger)
        cookieManager.register()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Cleanup if needed
    }
}

class WebViewFactory(private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        return FlutterWebView(context, viewId, creationParams, flutterPluginBinding.binaryMessenger)
    }
}
