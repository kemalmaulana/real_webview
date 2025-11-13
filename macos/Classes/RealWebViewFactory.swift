import FlutterMacOS
import WebKit

class RealWebViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return RealWebView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class RealWebView: NSObject, FlutterPlatformView {
    private let webView: WKWebView
    private let channel: FlutterMethodChannel
    private let viewId: Int64
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger
    ) {
        self.viewId = viewId
        
        // Create configuration
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        configuration.allowsAirPlayForMediaPlayback = true
        
        // Create webview
        webView = WKWebView(frame: frame, configuration: configuration)
        
        // Create method channel
        let channelName = "real_webview_\(viewId)"
        channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: messenger
        )
        
        super.init()
        
        // Set delegates
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Setup method channel
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handle(call, result: result)
        }
        
        // Parse arguments and load initial content
        if let arguments = args as? [String: Any] {
            if let initialUrl = arguments["initialUrl"] as? String {
                if let url = URL(string: initialUrl) {
                    webView.load(URLRequest(url: url))
                }
            }
            
            if let initialData = arguments["initialData"] as? String {
                webView.loadHTMLString(initialData, baseURL: nil)
            }
            
            if let settings = arguments["initialSettings"] as? [String: Any] {
                applySettings(settings)
            }
        }
    }
    
    func view() -> NSView {
        return webView
    }
    
    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadUrl":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String,
               let url = URL(string: urlString) {
                webView.load(URLRequest(url: url))
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
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
                        result(FlutterError(code: "JS_ERROR", message: error.localizedDescription, details: nil))
                    } else {
                        result(value)
                    }
                }
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
            
        case "addUserScript":
            if let args = call.arguments as? [String: Any],
               let source = args["source"] as? String {
                let injectionTime: WKUserScriptInjectionTime = 
                    (args["injectionTime"] as? Int == 0) ? .atDocumentStart : .atDocumentEnd
                let script = WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: true)
                webView.configuration.userContentController.addUserScript(script)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
            
        case "setSettings":
            if let args = call.arguments as? [String: Any] {
                applySettings(args)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func applySettings(_ settings: [String: Any]) {
        if let javaScriptEnabled = settings["javaScriptEnabled"] as? Bool {
            webView.configuration.preferences.javaScriptEnabled = javaScriptEnabled
        }
        
        if let userAgent = settings["userAgent"] as? String {
            webView.customUserAgent = userAgent
        }
    }
}

// MARK: - WKNavigationDelegate
extension RealWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        channel.invokeMethod("onLoadStart", arguments: webView.url?.absoluteString ?? "")
        channel.invokeMethod("onProgressChanged", arguments: 0)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        channel.invokeMethod("onLoadStop", arguments: webView.url?.absoluteString ?? "")
        channel.invokeMethod("onProgressChanged", arguments: 100)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let errorData: [String: Any] = [
            "code": (error as NSError).code,
            "description": error.localizedDescription,
            "url": webView.url?.absoluteString ?? ""
        ]
        channel.invokeMethod("onLoadError", arguments: errorData)
    }
}

// MARK: - WKUIDelegate
extension RealWebView: WKUIDelegate {
    // Handle JavaScript alerts, confirms, etc.
}
