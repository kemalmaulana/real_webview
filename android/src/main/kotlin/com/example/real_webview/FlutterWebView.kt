package com.example.real_webview

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.os.Build
import android.view.View
import android.webkit.*
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.ByteArrayOutputStream

class FlutterWebView(
    context: Context,
    private val viewId: Int,
    creationParams: Map<String, Any>?,
    messenger: BinaryMessenger
) : PlatformView, MethodChannel.MethodCallHandler {

    private val webView: WebView = WebView(context)
    private val methodChannel: MethodChannel =
        MethodChannel(messenger, "real_webview_$viewId")

    init {
        methodChannel.setMethodCallHandler(this)
        setupWebView(creationParams)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun setupWebView(params: Map<String, Any>?) {
        // Apply settings
        val settings = webView.settings

        // Default Chrome-like settings
        settings.javaScriptEnabled = true
        settings.domStorageEnabled = true
        settings.databaseEnabled = true
        settings.setSupportZoom(true)
        settings.builtInZoomControls = true
        settings.displayZoomControls = false
        settings.useWideViewPort = true
        settings.loadWithOverviewMode = true
        settings.mediaPlaybackRequiresUserGesture = false

        // Enable DRM content support
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            settings.safeBrowsingEnabled = true
        }

        // Mixed content mode (default to never allow for security)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            settings.mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
        }

        // Cache settings
        settings.cacheMode = WebSettings.LOAD_DEFAULT
        settings.setAppCacheEnabled(true)

        // Hardware acceleration
        webView.setLayerType(View.LAYER_TYPE_HARDWARE, null)

        // Apply initial settings if provided
        params?.get("initialSettings")?.let { settingsMap ->
            applySettings(settingsMap as Map<String, Any>)

            // Enable automatic DRM if configured
            val drmConfig = (settingsMap as? Map<String, Any>)?.get("drmConfiguration") as? Map<String, Any>
            if (drmConfig != null) {
                val autoDetect = (drmConfig["customData"] as? Map<String, Any>)?.get("autoDetect") as? Boolean
                if (autoDetect == true) {
                    // Enable automatic DRM handling like Chrome
                    DRMMediaHandler.enableAutoDRM(webView)
                }
            }
        }

        // Set WebView clients
        webView.webViewClient = RealWebViewClient(methodChannel)
        webView.webChromeClient = RealWebChromeClient(methodChannel)

        // Add JavaScript interface for communication
        webView.addJavascriptInterface(
            JavaScriptBridge(methodChannel),
            "FlutterWebView"
        )

        // Load initial URL or data
        params?.get("initialUrl")?.let { url ->
            webView.loadUrl(url as String)
        }

        params?.get("initialData")?.let { data ->
            webView.loadData(
                data as String,
                "text/html",
                "UTF-8"
            )
        }
    }

    private fun applySettings(settingsMap: Map<String, Any>) {
        val settings = webView.settings

        settingsMap["javaScriptEnabled"]?.let {
            settings.javaScriptEnabled = it as Boolean
        }

        settingsMap["domStorageEnabled"]?.let {
            settings.domStorageEnabled = it as Boolean
        }

        settingsMap["databaseEnabled"]?.let {
            settings.databaseEnabled = it as Boolean
        }

        settingsMap["userAgent"]?.let {
            settings.userAgentString = it as String
        }

        settingsMap["supportZoom"]?.let {
            settings.setSupportZoom(it as Boolean)
        }

        settingsMap["mediaPlaybackRequiresUserGesture"]?.let {
            settings.mediaPlaybackRequiresUserGesture = it as Boolean
        }

        settingsMap["cacheEnabled"]?.let {
            settings.setAppCacheEnabled(it as Boolean)
        }

        settingsMap["cacheMode"]?.let {
            val mode = when ((it as Int)) {
                0 -> WebSettings.LOAD_DEFAULT
                1 -> WebSettings.LOAD_CACHE_ELSE_NETWORK
                2 -> WebSettings.LOAD_NO_CACHE
                3 -> WebSettings.LOAD_CACHE_ONLY
                else -> WebSettings.LOAD_DEFAULT
            }
            settings.cacheMode = mode
        }

        settingsMap["allowFileAccess"]?.let {
            settings.allowFileAccess = it as Boolean
        }

        settingsMap["allowContentAccess"]?.let {
            settings.allowContentAccess = it as Boolean
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
            settingsMap["allowFileAccessFromFileURLs"]?.let {
                settings.allowFileAccessFromFileURLs = it as Boolean
            }

            settingsMap["allowUniversalAccessFromFileURLs"]?.let {
                settings.allowUniversalAccessFromFileURLs = it as Boolean
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            settingsMap["mixedContentMode"]?.let {
                val mode = when ((it as Int)) {
                    0 -> WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                    1 -> WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
                    2 -> WebSettings.MIXED_CONTENT_NEVER_ALLOW
                    else -> WebSettings.MIXED_CONTENT_NEVER_ALLOW
                }
                settings.mixedContentMode = mode
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            settingsMap["safeBrowsingEnabled"]?.let {
                settings.safeBrowsingEnabled = it as Boolean
            }
        }

        settingsMap["textZoom"]?.let {
            settings.textZoom = (it as Int)
        }

        settingsMap["minimumFontSize"]?.let {
            settings.minimumFontSize = (it as Int)
        }

        settingsMap["useWideViewPort"]?.let {
            settings.useWideViewPort = it as Boolean
        }

        settingsMap["loadWithOverviewMode"]?.let {
            settings.loadWithOverviewMode = it as Boolean
        }

        settingsMap["builtInZoomControls"]?.let {
            settings.builtInZoomControls = it as Boolean
        }

        settingsMap["displayZoomControls"]?.let {
            settings.displayZoomControls = it as Boolean
        }

        settingsMap["hardwareAcceleration"]?.let {
            if (it as Boolean) {
                webView.setLayerType(View.LAYER_TYPE_HARDWARE, null)
            } else {
                webView.setLayerType(View.LAYER_TYPE_SOFTWARE, null)
            }
        }

        settingsMap["transparentBackground"]?.let {
            if (it as Boolean) {
                webView.setBackgroundColor(0x00000000)
            }
        }
    }

    override fun getView(): View = webView

    override fun dispose() {
        webView.destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> {
                val url = call.argument<String>("url")
                val headers = call.argument<Map<String, String>>("headers")
                if (url != null) {
                    if (headers != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        webView.loadUrl(url, headers)
                    } else {
                        webView.loadUrl(url)
                    }
                    result.success(null)
                } else {
                    result.error("INVALID_URL", "URL is required", null)
                }
            }
            "loadData" -> {
                val data = call.argument<String>("data")
                val mimeType = call.argument<String>("mimeType") ?: "text/html"
                val encoding = call.argument<String>("encoding") ?: "UTF-8"
                val baseUrl = call.argument<String>("baseUrl")
                if (data != null) {
                    if (baseUrl != null) {
                        webView.loadDataWithBaseURL(baseUrl, data, mimeType, encoding, null)
                    } else {
                        webView.loadData(data, mimeType, encoding)
                    }
                    result.success(null)
                } else {
                    result.error("INVALID_DATA", "Data is required", null)
                }
            }
            "reload" -> {
                webView.reload()
                result.success(null)
            }
            "goBack" -> {
                webView.goBack()
                result.success(null)
            }
            "goForward" -> {
                webView.goForward()
                result.success(null)
            }
            "canGoBack" -> {
                result.success(webView.canGoBack())
            }
            "canGoForward" -> {
                result.success(webView.canGoForward())
            }
            "getUrl" -> {
                result.success(webView.url)
            }
            "getTitle" -> {
                result.success(webView.title)
            }
            "evaluateJavascript" -> {
                val source = call.argument<String>("source")
                if (source != null) {
                    webView.evaluateJavascript(source) { value ->
                        result.success(value)
                    }
                } else {
                    result.error("INVALID_SOURCE", "JavaScript source is required", null)
                }
            }
            "stopLoading" -> {
                webView.stopLoading()
                result.success(null)
            }
            "clearCache" -> {
                webView.clearCache(true)
                result.success(null)
            }
            "clearHistory" -> {
                webView.clearHistory()
                result.success(null)
            }
            "takeScreenshot" -> {
                try {
                    webView.isDrawingCacheEnabled = true
                    val bitmap = Bitmap.createBitmap(
                        webView.drawingCache
                    )
                    webView.isDrawingCacheEnabled = false

                    val stream = ByteArrayOutputStream()
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    val byteArray = stream.toByteArray()
                    bitmap.recycle()

                    result.success(byteArray)
                } catch (e: Exception) {
                    result.error("SCREENSHOT_ERROR", e.message, null)
                }
            }
            "getSettings" -> {
                result.success(getCurrentSettings())
            }
            "setSettings" -> {
                call.arguments?.let { args ->
                    applySettings(args as Map<String, Any>)
                    result.success(null)
                } ?: result.error("INVALID_SETTINGS", "Settings are required", null)
            }
            "zoomIn" -> {
                webView.zoomIn()
                result.success(null)
            }
            "zoomOut" -> {
                webView.zoomOut()
                result.success(null)
            }
            "setZoomScale" -> {
                val scale = call.argument<Double>("scale")
                if (scale != null) {
                    webView.setInitialScale((scale * 100).toInt())
                    result.success(null)
                } else {
                    result.error("INVALID_SCALE", "Scale is required", null)
                }
            }
            "getZoomScale" -> {
                result.success(webView.scale.toDouble())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getCurrentSettings(): Map<String, Any> {
        val settings = webView.settings
        return mapOf(
            "javaScriptEnabled" to settings.javaScriptEnabled,
            "domStorageEnabled" to settings.domStorageEnabled,
            "databaseEnabled" to settings.databaseEnabled,
            "userAgent" to (settings.userAgentString ?: ""),
            "supportZoom" to settings.supportZoom(),
            "cacheEnabled" to settings.appCacheEnabled,
            "textZoom" to settings.textZoom
        )
    }
}

// JavaScript Bridge for communication
class JavaScriptBridge(private val methodChannel: MethodChannel) {
    @JavascriptInterface
    fun postMessage(message: String) {
        methodChannel.invokeMethod("onJavaScriptMessage", message)
    }
}
