package com.example.real_webview

import android.graphics.Bitmap
import android.net.http.SslError
import android.webkit.*
import io.flutter.plugin.common.MethodChannel

class RealWebViewClient(private val methodChannel: MethodChannel) : WebViewClient() {

    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        url?.let {
            methodChannel.invokeMethod("onLoadStart", it)
            methodChannel.invokeMethod("onUrlChanged", it)
        }
    }

    override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        url?.let {
            methodChannel.invokeMethod("onLoadStop", it)
        }
    }

    override fun onReceivedError(
        view: WebView?,
        request: WebResourceRequest?,
        error: WebResourceError?
    ) {
        super.onReceivedError(view, request, error)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
            val errorMap = mapOf(
                "code" to error?.errorCode,
                "description" to error?.description.toString(),
                "url" to request?.url.toString()
            )
            methodChannel.invokeMethod("onLoadError", errorMap)
        }
    }

    override fun onReceivedHttpError(
        view: WebView?,
        request: WebResourceRequest?,
        errorResponse: WebResourceResponse?
    ) {
        super.onReceivedHttpError(view, request, errorResponse)
        val errorMap = mapOf(
            "code" to errorResponse?.statusCode,
            "description" to errorResponse?.reasonPhrase,
            "url" to request?.url.toString()
        )
        methodChannel.invokeMethod("onLoadError", errorMap)
    }

    override fun onReceivedSslError(
        view: WebView?,
        handler: SslErrorHandler?,
        error: SslError?
    ) {
        // For production, you should implement proper SSL error handling
        // For now, we'll cancel the request
        handler?.cancel()
        val errorMap = mapOf(
            "code" to error?.primaryError,
            "description" to "SSL Error: ${error?.toString()}",
            "url" to error?.url
        )
        methodChannel.invokeMethod("onLoadError", errorMap)
    }

    override fun shouldOverrideUrlLoading(
        view: WebView?,
        request: WebResourceRequest?
    ): Boolean {
        // Allow WebView to handle all URLs
        return false
    }

    override fun onLoadResource(view: WebView?, url: String?) {
        super.onLoadResource(view, url)
        // Can be used for tracking resource loading
    }
}

class RealWebChromeClient(private val methodChannel: MethodChannel) : WebChromeClient() {

    override fun onProgressChanged(view: WebView?, newProgress: Int) {
        super.onProgressChanged(view, newProgress)
        methodChannel.invokeMethod("onProgressChanged", newProgress)
    }

    override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
        consoleMessage?.let {
            val messageMap = mapOf(
                "message" to it.message(),
                "level" to when (it.messageLevel()) {
                    ConsoleMessage.MessageLevel.LOG -> 0
                    ConsoleMessage.MessageLevel.DEBUG -> 1
                    ConsoleMessage.MessageLevel.TIP -> 2
                    ConsoleMessage.MessageLevel.WARNING -> 3
                    ConsoleMessage.MessageLevel.ERROR -> 4
                    else -> 0
                },
                "sourceId" to it.sourceId(),
                "lineNumber" to it.lineNumber()
            )
            methodChannel.invokeMethod("onConsoleMessage", messageMap)
        }
        return true
    }

    override fun onReceivedTitle(view: WebView?, title: String?) {
        super.onReceivedTitle(view, title)
        // Can notify Flutter about title changes if needed
    }

    override fun onReceivedIcon(view: WebView?, icon: Bitmap?) {
        super.onReceivedIcon(view, icon)
        // Can notify Flutter about favicon changes if needed
    }

    override fun onJsAlert(
        view: WebView?,
        url: String?,
        message: String?,
        result: JsResult?
    ): Boolean {
        // Handle JavaScript alerts - for now use default behavior
        return false
    }

    override fun onJsConfirm(
        view: WebView?,
        url: String?,
        message: String?,
        result: JsResult?
    ): Boolean {
        // Handle JavaScript confirms - for now use default behavior
        return false
    }

    override fun onJsPrompt(
        view: WebView?,
        url: String?,
        message: String?,
        defaultValue: String?,
        result: JsPromptResult?
    ): Boolean {
        // Handle JavaScript prompts - for now use default behavior
        return false
    }
}
