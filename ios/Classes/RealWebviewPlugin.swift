import Flutter
import UIKit
import WebKit

public class RealWebviewPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register platform view factory
        let factory = FLNativeViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "real_webview")

        // Register cookie manager
        let cookieManagerChannel = FlutterMethodChannel(
            name: "real_webview/cookie_manager",
            binaryMessenger: registrar.messenger()
        )
        let cookieManager = RealCookieManager(channel: cookieManagerChannel)
        registrar.addMethodCallDelegate(cookieManager, channel: cookieManagerChannel)
    }
}

class FLNativeViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLNativeView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
