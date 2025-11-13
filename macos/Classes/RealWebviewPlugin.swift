import FlutterMacOS
import WebKit

public class RealWebviewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "real_webview",
            binaryMessenger: registrar.messenger
        )
        let instance = RealWebviewPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Register platform view factory
        let factory = RealWebViewFactory(messenger: registrar.messenger)
        registrar.register(factory, withId: "real_webview")
        
        // Register cookie manager
        let cookieManagerChannel = FlutterMethodChannel(
            name: "real_webview/cookie_manager",
            binaryMessenger: registrar.messenger
        )
        let cookieManager = RealCookieManager(channel: cookieManagerChannel)
        registrar.addMethodCallDelegate(cookieManager, channel: cookieManagerChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
