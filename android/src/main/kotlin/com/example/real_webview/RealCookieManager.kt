package com.example.real_webview

import android.os.Build
import android.webkit.CookieManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class RealCookieManager(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "real_webview/cookie_manager")
    private val cookieManager = CookieManager.getInstance()

    init {
        // Enable cookies
        cookieManager.setAcceptCookie(true)
        // Note: Third-party cookies are enabled per WebView instance in FlutterWebView.kt
    }

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setCookie" -> {
                val url = call.argument<String>("url")
                val cookie = call.argument<Map<String, Any>>("cookie")
                if (url != null && cookie != null) {
                    setCookie(url, cookie, result)
                } else {
                    result.error("INVALID_ARGS", "URL and cookie are required", null)
                }
            }
            "setCookies" -> {
                val url = call.argument<String>("url")
                val cookies = call.argument<List<Map<String, Any>>>("cookies")
                if (url != null && cookies != null) {
                    cookies.forEach { cookie ->
                        setCookie(url, cookie, null)
                    }
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "URL and cookies are required", null)
                }
            }
            "getCookies" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    result.success(getCookies(url))
                } else {
                    result.error("INVALID_ARGS", "URL is required", null)
                }
            }
            "getCookie" -> {
                val url = call.argument<String>("url")
                val name = call.argument<String>("name")
                if (url != null && name != null) {
                    result.success(getCookie(url, name))
                } else {
                    result.error("INVALID_ARGS", "URL and name are required", null)
                }
            }
            "deleteCookie" -> {
                val url = call.argument<String>("url")
                val name = call.argument<String>("name")
                if (url != null && name != null) {
                    deleteCookie(url, name)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "URL and name are required", null)
                }
            }
            "deleteCookies" -> {
                val url = call.argument<String>("url")
                if (url != null) {
                    deleteCookiesForUrl(url)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGS", "URL is required", null)
                }
            }
            "deleteAllCookies" -> {
                deleteAllCookies()
                result.success(null)
            }
            "getAllCookies" -> {
                result.success(getAllCookies())
            }
            "flush" -> {
                flush()
                result.success(null)
            }
            "hasCookies" -> {
                result.success(cookieManager.hasCookies())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun setCookie(url: String, cookie: Map<String, Any>, result: MethodChannel.Result?) {
        val name = cookie["name"] as? String
        val value = cookie["value"] as? String
        val domain = cookie["domain"] as? String
        val path = cookie["path"] as? String ?: "/"
        val expiresDate = cookie["expiresDate"] as? Long
        val maxAge = cookie["maxAge"] as? Int
        val isSecure = cookie["isSecure"] as? Boolean ?: false
        val isHttpOnly = cookie["isHttpOnly"] as? Boolean ?: false
        val sameSite = cookie["sameSite"] as? Int ?: 0

        if (name != null && value != null) {
            val cookieString = buildCookieString(
                name, value, domain, path, expiresDate, maxAge, isSecure, isHttpOnly, sameSite
            )

            cookieManager.setCookie(url, cookieString) {
                flush()
                result?.success(null)
            }
        } else {
            result?.error("INVALID_COOKIE", "Cookie name and value are required", null)
        }
    }

    private fun buildCookieString(
        name: String,
        value: String,
        domain: String?,
        path: String,
        expiresDate: Long?,
        maxAge: Int?,
        isSecure: Boolean,
        isHttpOnly: Boolean,
        sameSite: Int
    ): String {
        val sb = StringBuilder()
        sb.append("$name=$value")

        domain?.let {
            sb.append("; Domain=$it")
        }

        sb.append("; Path=$path")

        expiresDate?.let {
            val date = java.util.Date(it)
            val format = java.text.SimpleDateFormat("EEE, dd MMM yyyy HH:mm:ss zzz", java.util.Locale.US)
            format.timeZone = java.util.TimeZone.getTimeZone("GMT")
            sb.append("; Expires=${format.format(date)}")
        }

        maxAge?.let {
            sb.append("; Max-Age=$it")
        }

        if (isSecure) {
            sb.append("; Secure")
        }

        if (isHttpOnly) {
            sb.append("; HttpOnly")
        }

        when (sameSite) {
            1 -> sb.append("; SameSite=Lax")
            2 -> sb.append("; SameSite=Strict")
            else -> sb.append("; SameSite=None")
        }

        return sb.toString()
    }

    private fun getCookies(url: String): List<Map<String, Any>> {
        val cookieString = cookieManager.getCookie(url) ?: return emptyList()
        return parseCookies(cookieString)
    }

    private fun getCookie(url: String, name: String): Map<String, Any>? {
        val cookies = getCookies(url)
        return cookies.firstOrNull { it["name"] == name }
    }

    private fun parseCookies(cookieString: String): List<Map<String, Any>> {
        val cookies = mutableListOf<Map<String, Any>>()
        val cookiePairs = cookieString.split(";")

        for (pair in cookiePairs) {
            val parts = pair.trim().split("=", limit = 2)
            if (parts.size == 2) {
                cookies.add(
                    mapOf(
                        "name" to parts[0].trim(),
                        "value" to parts[1].trim(),
                        "domain" to "",
                        "path" to "/",
                        "isSecure" to false,
                        "isHttpOnly" to false,
                        "sameSite" to 0
                    )
                )
            }
        }

        return cookies
    }

    private fun deleteCookie(url: String, name: String) {
        val cookieString = "$name=; Max-Age=0"
        cookieManager.setCookie(url, cookieString)
        flush()
    }

    private fun deleteCookiesForUrl(url: String) {
        val cookies = getCookies(url)
        cookies.forEach { cookie ->
            val name = cookie["name"] as String
            deleteCookie(url, name)
        }
    }

    private fun deleteAllCookies() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cookieManager.removeAllCookies { flush() }
        } else {
            @Suppress("DEPRECATION")
            cookieManager.removeAllCookie()
            flush()
        }
    }

    private fun getAllCookies(): List<Map<String, Any>> {
        // Android CookieManager doesn't provide a way to get all cookies across all domains
        // This would require maintaining a separate store or using a different approach
        return emptyList()
    }

    private fun flush() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cookieManager.flush()
        }
    }
}
