import FlutterMacOS
import WebKit

class RealCookieManager: NSObject, FlutterPlugin {
    private let channel: FlutterMethodChannel
    private let cookieStore: WKHTTPCookieStore
    
    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.cookieStore = WKWebsiteDataStore.default().httpCookieStore
        super.init()
    }
    
    static func register(with registrar: FlutterPluginRegistrar) {
        // Registration handled by main plugin
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setCookie":
            guard let args = call.arguments as? [String: Any],
                  let urlString = args["url"] as? String,
                  let cookieData = args["cookie"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            setCookie(url: urlString, cookieData: cookieData, result: result)
            
        case "getCookies":
            guard let args = call.arguments as? [String: Any],
                  let urlString = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            getCookies(url: urlString, result: result)
            
        case "deleteCookie":
            guard let args = call.arguments as? [String: Any],
                  let urlString = args["url"] as? String,
                  let name = args["name"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            deleteCookie(url: urlString, name: name, result: result)
            
        case "deleteAllCookies":
            deleteAllCookies(result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func setCookie(url: String, cookieData: [String: Any], result: @escaping FlutterResult) {
        guard let cookie = createHTTPCookie(url: url, data: cookieData) else {
            result(FlutterError(code: "INVALID_COOKIE", message: "Cannot create cookie", details: nil))
            return
        }
        
        cookieStore.setCookie(cookie) {
            result(true)
        }
    }
    
    private func getCookies(url: String, result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            let filteredCookies = cookies.filter { cookie in
                guard let cookieURL = URL(string: url),
                      let host = cookieURL.host else {
                    return false
                }
                return host.contains(cookie.domain)
            }
            
            let cookiesData = filteredCookies.map { cookie in
                self.cookieToMap(cookie)
            }
            
            result(cookiesData)
        }
    }
    
    private func deleteCookie(url: String, name: String, result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            for cookie in cookies where cookie.name == name {
                self.cookieStore.delete(cookie) {
                    result(true)
                }
                return
            }
            result(false)
        }
    }
    
    private func deleteAllCookies(result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            let group = DispatchGroup()
            
            for cookie in cookies {
                group.enter()
                self.cookieStore.delete(cookie) {
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                result(true)
            }
        }
    }
    
    private func createHTTPCookie(url: String, data: [String: Any]) -> HTTPCookie? {
        guard let name = data["name"] as? String,
              let value = data["value"] as? String else {
            return nil
        }
        
        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .path: data["path"] as? String ?? "/",
        ]
        
        if let domain = data["domain"] as? String {
            properties[.domain] = domain
        } else if let urlObj = URL(string: url), let host = urlObj.host {
            properties[.domain] = host
        }
        
        if let secure = data["isSecure"] as? Bool, secure {
            properties[.secure] = "TRUE"
        }
        
        if let httpOnly = data["isHttpOnly"] as? Bool, httpOnly {
            properties[.init("HttpOnly")] = "TRUE"
        }
        
        if let expiresDate = data["expiresDate"] as? Int {
            properties[.expires] = Date(timeIntervalSince1970: TimeInterval(expiresDate))
        }
        
        return HTTPCookie(properties: properties)
    }
    
    private func cookieToMap(_ cookie: HTTPCookie) -> [String: Any] {
        var map: [String: Any] = [
            "name": cookie.name,
            "value": cookie.value,
            "domain": cookie.domain,
            "path": cookie.path,
            "isSecure": cookie.isSecure,
            "isHttpOnly": cookie.isHTTPOnly
        ]
        
        if let expiresDate = cookie.expiresDate {
            map["expiresDate"] = Int(expiresDate.timeIntervalSince1970)
        }
        
        return map
    }
}
