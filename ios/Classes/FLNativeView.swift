import Flutter
import UIKit
import WebKit

class FLNativeView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var webView: WKWebView!
    private var methodChannel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView()
        methodChannel = FlutterMethodChannel(
            name: "real_webview_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        createWebView(frame: frame, arguments: args)
        methodChannel.setMethodCallHandler(handle)
    }

    func view() -> UIView {
        return _view
    }

    private func createWebView(frame: CGRect, arguments args: Any?) {
        let configuration = WKWebViewConfiguration()

        // Enable JavaScript
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        configuration.preferences = preferences

        // Enable media playback
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Enable DRM (FairPlay)
        if #available(iOS 14.0, *) {
            configuration.upgradeKnownHostsToHTTPS = true
        }

        // Apply initial settings if provided
        if let params = args as? [String: Any],
           let initialSettings = params["initialSettings"] as? [String: Any] {
            applySettings(to: configuration, settings: initialSettings)

            // Enable automatic DRM if configured
            if let drmConfig = initialSettings["drmConfiguration"] as? [String: Any],
               let customData = drmConfig["customData"] as? [String: Any],
               let autoDetect = customData["autoDetect"] as? Bool,
               autoDetect {
                // Will enable auto-DRM after WebView creation
            }
        }

        webView = WKWebView(frame: frame, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self

        // Enable automatic DRM if configured
        if let params = args as? [String: Any],
           let initialSettings = params["initialSettings"] as? [String: Any],
           let drmConfig = initialSettings["drmConfiguration"] as? [String: Any],
           let customData = drmConfig["customData"] as? [String: Any],
           let autoDetect = customData["autoDetect"] as? Bool,
           autoDetect {
            DRMMediaHandler.enableAutoDRM(webView: webView)
        }

        // Enable scroll bounce
        webView.scrollView.bounces = true

        // Configure for Chrome-like behavior
        webView.allowsBackForwardNavigationGestures = true

        _view.addSubview(webView)

        // Auto layout
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: _view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: _view.trailingAnchor)
        ])

        // Load initial URL or data
        if let params = args as? [String: Any] {
            if let initialUrl = params["initialUrl"] as? String,
               let url = URL(string: initialUrl) {
                let request = URLRequest(url: url)
                webView.load(request)
            } else if let initialData = params["initialData"] as? String {
                webView.loadHTMLString(initialData, baseURL: nil)
            }
        }

        // Add observer for URL changes
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
    }

    private func applySettings(to configuration: WKWebViewConfiguration, settings: [String: Any]) {
        let preferences = WKPreferences()

        if let javaScriptEnabled = settings["javaScriptEnabled"] as? Bool {
            preferences.javaScriptEnabled = javaScriptEnabled
        }

        configuration.preferences = preferences

        if let mediaPlaybackRequiresUserGesture = settings["mediaPlaybackRequiresUserGesture"] as? Bool {
            if mediaPlaybackRequiresUserGesture {
                configuration.mediaTypesRequiringUserActionForPlayback = .all
            } else {
                configuration.mediaTypesRequiringUserActionForPlayback = []
            }
        }

        if let allowFileAccessFromFileURLs = settings["allowFileAccessFromFileURLs"] as? Bool {
            configuration.setValue(allowFileAccessFromFileURLs, forKey: "allowUniversalAccessFromFileURLs")
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == #keyPath(WKWebView.url) {
            if let url = webView.url?.absoluteString {
                methodChannel.invokeMethod("onUrlChanged", arguments: url)
            }
        } else if keyPath == #keyPath(WKWebView.estimatedProgress) {
            let progress = Int(webView.estimatedProgress * 100)
            methodChannel.invokeMethod("onProgressChanged", arguments: progress)
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadUrl":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String,
               let url = URL(string: urlString) {
                var request = URLRequest(url: url)
                if let headers = args["headers"] as? [String: String] {
                    for (key, value) in headers {
                        request.setValue(value, forHTTPHeaderField: key)
                    }
                }
                webView.load(request)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_URL", message: "URL is required", details: nil))
            }

        case "loadData":
            if let args = call.arguments as? [String: Any],
               let data = args["data"] as? String {
                let baseUrlString = args["baseUrl"] as? String
                let baseUrl = baseUrlString != nil ? URL(string: baseUrlString!) : nil
                webView.loadHTMLString(data, baseURL: baseUrl)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_DATA", message: "Data is required", details: nil))
            }

        case "reload":
            webView.reload()
            result(nil)

        case "goBack":
            webView.goBack()
            result(nil)

        case "goForward":
            webView.goForward()
            result(nil)

        case "canGoBack":
            result(webView.canGoBack)

        case "canGoForward":
            result(webView.canGoForward)

        case "getUrl":
            result(webView.url?.absoluteString)

        case "getTitle":
            result(webView.title)

        case "evaluateJavascript":
            if let args = call.arguments as? [String: Any],
               let source = args["source"] as? String {
                webView.evaluateJavaScript(source) { (value, error) in
                    if let error = error {
                        result(FlutterError(
                            code: "JAVASCRIPT_ERROR",
                            message: error.localizedDescription,
                            details: nil
                        ))
                    } else {
                        result(value)
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_SOURCE", message: "JavaScript source is required", details: nil))
            }

        case "stopLoading":
            webView.stopLoading()
            result(nil)

        case "clearCache":
            let dataStore = WKWebsiteDataStore.default()
            dataStore.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: Date(timeIntervalSince1970: 0)
            ) {
                result(nil)
            }

        case "clearHistory":
            let dataStore = WKWebsiteDataStore.default()
            dataStore.removeData(
                ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache],
                modifiedSince: Date(timeIntervalSince1970: 0)
            ) {
                result(nil)
            }

        case "takeScreenshot":
            if #available(iOS 11.0, *) {
                let config = WKSnapshotConfiguration()
                webView.takeSnapshot(with: config) { image, error in
                    if let image = image,
                       let data = image.pngData() {
                        result(FlutterStandardTypedData(bytes: data))
                    } else {
                        result(FlutterError(
                            code: "SCREENSHOT_ERROR",
                            message: error?.localizedDescription ?? "Unknown error",
                            details: nil
                        ))
                    }
                }
            } else {
                result(FlutterError(code: "UNSUPPORTED", message: "Screenshot not supported on iOS < 11", details: nil))
            }

        case "getSettings":
            result(getCurrentSettings())

        case "setSettings":
            // Settings would need to be applied at initialization
            result(nil)

        case "zoomIn":
            webView.scrollView.zoomScale += 0.1
            result(nil)

        case "zoomOut":
            webView.scrollView.zoomScale -= 0.1
            result(nil)

        case "setZoomScale":
            if let args = call.arguments as? [String: Any],
               let scale = args["scale"] as? Double {
                webView.scrollView.zoomScale = CGFloat(scale)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_SCALE", message: "Scale is required", details: nil))
            }

        case "getZoomScale":
            result(Double(webView.scrollView.zoomScale))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getCurrentSettings() -> [String: Any] {
        return [
            "javaScriptEnabled": webView.configuration.preferences.javaScriptEnabled,
            "userAgent": webView.customUserAgent ?? "",
            "allowsInlineMediaPlayback": webView.configuration.allowsInlineMediaPlayback
        ]
    }

    deinit {
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.url))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
    }
}

// MARK: - WKNavigationDelegate
extension FLNativeView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            methodChannel.invokeMethod("onLoadStart", arguments: url)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            methodChannel.invokeMethod("onLoadStop", arguments: url)
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        let errorMap: [String: Any] = [
            "code": (error as NSError).code,
            "description": error.localizedDescription,
            "url": webView.url?.absoluteString ?? ""
        ]
        methodChannel.invokeMethod("onLoadError", arguments: errorMap)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        let errorMap: [String: Any] = [
            "code": (error as NSError).code,
            "description": error.localizedDescription,
            "url": webView.url?.absoluteString ?? ""
        ]
        methodChannel.invokeMethod("onLoadError", arguments: errorMap)
    }
}

// MARK: - WKUIDelegate
extension FLNativeView: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping () -> Void
    ) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler()
        })

        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        } else {
            completionHandler()
        }
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })

        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        } else {
            completionHandler(false)
        }
    }
}
