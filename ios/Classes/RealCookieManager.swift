import Flutter
import WebKit

class RealCookieManager: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel
    private let cookieStore: WKHTTPCookieStore

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        self.cookieStore = WKWebsiteDataStore.default().httpCookieStore
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        // This is handled in RealWebviewPlugin.swift
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setCookie":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String,
               let cookieData = args["cookie"] as? [String: Any] {
                setCookie(url: url, cookieData: cookieData, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "URL and cookie are required", details: nil))
            }

        case "setCookies":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String,
               let cookies = args["cookies"] as? [[String: Any]] {
                setCookies(url: url, cookies: cookies, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "URL and cookies are required", details: nil))
            }

        case "getCookies":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String {
                getCookies(url: url, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "URL is required", details: nil))
            }

        case "getCookie":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String,
               let name = args["name"] as? String {
                getCookie(url: url, name: name, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "URL and name are required", details: nil))
            }

        case "deleteCookie":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String,
               let name = args["name"] as? String {
                deleteCookie(url: url, name: name, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "URL and name are required", details: nil))
            }

        case "deleteCookies":
            if let args = call.arguments as? [String: Any],
               let url = args["url"] as? String {
                deleteCookies(url: url, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "URL is required", details: nil))
            }

        case "deleteAllCookies":
            deleteAllCookies(result: result)

        case "getAllCookies":
            getAllCookies(result: result)

        case "flush":
            // iOS automatically persists cookies
            result(nil)

        case "hasCookies":
            hasCookies(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func setCookie(url: String, cookieData: [String: Any], result: @escaping FlutterResult) {
        guard let cookie = createHTTPCookie(url: url, data: cookieData) else {
            result(FlutterError(code: "INVALID_COOKIE", message: "Cookie name and value are required", details: nil))
            return
        }

        cookieStore.setCookie(cookie) {
            result(nil)
        }
    }

    private func setCookies(url: String, cookies: [[String: Any]], result: @escaping FlutterResult) {
        var httpCookies: [HTTPCookie] = []

        for cookieData in cookies {
            if let cookie = createHTTPCookie(url: url, data: cookieData) {
                httpCookies.append(cookie)
            }
        }

        let group = DispatchGroup()

        for cookie in httpCookies {
            group.enter()
            cookieStore.setCookie(cookie) {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            result(nil)
        }
    }

    private func getCookies(url: String, result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            guard let urlObj = URL(string: url) else {
                result([])
                return
            }

            let filteredCookies = cookies.filter { cookie in
                self.cookieMatchesURL(cookie: cookie, url: urlObj)
            }

            let cookieData = filteredCookies.map { self.cookieToMap($0) }
            result(cookieData)
        }
    }

    private func getCookie(url: String, name: String, result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            guard let urlObj = URL(string: url) else {
                result(nil)
                return
            }

            let cookie = cookies.first { cookie in
                cookie.name == name && self.cookieMatchesURL(cookie: cookie, url: urlObj)
            }

            if let cookie = cookie {
                result(self.cookieToMap(cookie))
            } else {
                result(nil)
            }
        }
    }

    private func deleteCookie(url: String, name: String, result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            guard let urlObj = URL(string: url) else {
                result(nil)
                return
            }

            let cookiesToDelete = cookies.filter { cookie in
                cookie.name == name && self.cookieMatchesURL(cookie: cookie, url: urlObj)
            }

            let group = DispatchGroup()

            for cookie in cookiesToDelete {
                group.enter()
                self.cookieStore.delete(cookie) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                result(nil)
            }
        }
    }

    private func deleteCookies(url: String, result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            guard let urlObj = URL(string: url) else {
                result(nil)
                return
            }

            let cookiesToDelete = cookies.filter { cookie in
                self.cookieMatchesURL(cookie: cookie, url: urlObj)
            }

            let group = DispatchGroup()

            for cookie in cookiesToDelete {
                group.enter()
                self.cookieStore.delete(cookie) {
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                result(nil)
            }
        }
    }

    private func deleteAllCookies(result: @escaping FlutterResult) {
        let dataStore = WKWebsiteDataStore.default()
        dataStore.removeData(
            ofTypes: [WKWebsiteDataTypeCookies],
            modifiedSince: Date(timeIntervalSince1970: 0)
        ) {
            result(nil)
        }
    }

    private func getAllCookies(result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            let cookieData = cookies.map { self.cookieToMap($0) }
            result(cookieData)
        }
    }

    private func hasCookies(result: @escaping FlutterResult) {
        cookieStore.getAllCookies { cookies in
            result(!cookies.isEmpty)
        }
    }

    // Helper methods
    private func createHTTPCookie(url: String, data: [String: Any]) -> HTTPCookie? {
        guard let name = data["name"] as? String,
              let value = data["value"] as? String,
              let urlObj = URL(string: url) else {
            return nil
        }

        var properties: [HTTPCookiePropertyKey: Any] = [
            .name: name,
            .value: value,
            .path: data["path"] as? String ?? "/",
            .domain: data["domain"] as? String ?? urlObj.host ?? ""
        ]

        if let expiresDate = data["expiresDate"] as? Int64 {
            properties[.expires] = Date(timeIntervalSince1970: TimeInterval(expiresDate) / 1000.0)
        }

        if let maxAge = data["maxAge"] as? Int {
            properties[.maximumAge] = String(maxAge)
        }

        if let isSecure = data["isSecure"] as? Bool, isSecure {
            properties[.secure] = "TRUE"
        }

        if let isHttpOnly = data["isHttpOnly"] as? Bool, isHttpOnly {
            properties[.httpOnly] = "TRUE"
        }

        if let sameSite = data["sameSite"] as? Int {
            switch sameSite {
            case 1:
                properties[.sameSitePolicy] = "Lax"
            case 2:
                properties[.sameSitePolicy] = "Strict"
            default:
                properties[.sameSitePolicy] = "None"
            }
        }

        return HTTPCookie(properties: properties)
    }

    private func cookieToMap(_ cookie: HTTPCookie) -> [String: Any] {
        var sameSite = 0
        if let sameSiteValue = cookie.sameSitePolicy?.rawValue {
            if sameSiteValue == "Lax" {
                sameSite = 1
            } else if sameSiteValue == "Strict" {
                sameSite = 2
            }
        }

        return [
            "name": cookie.name,
            "value": cookie.value,
            "domain": cookie.domain,
            "path": cookie.path,
            "expiresDate": cookie.expiresDate?.timeIntervalSince1970 != nil
                ? Int64((cookie.expiresDate?.timeIntervalSince1970 ?? 0) * 1000)
                : NSNull(),
            "isSecure": cookie.isSecure,
            "isHttpOnly": cookie.isHTTPOnly,
            "sameSite": sameSite
        ]
    }

    private func cookieMatchesURL(cookie: HTTPCookie, url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }

        // Check domain match
        let domain = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
        let hostMatch = host == domain || host.hasSuffix("." + domain)

        // Check path match
        let pathMatch = url.path.hasPrefix(cookie.path)

        return hostMatch && pathMatch
    }
}
