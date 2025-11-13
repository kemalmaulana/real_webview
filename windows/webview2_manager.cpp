#include "include/real_webview/webview2_manager.h"
#include <flutter/encodable_value.h>
#include <sstream>

namespace real_webview {

WebView2Manager::WebView2Manager(int view_id,
                                 flutter::BinaryMessenger* messenger,
                                 HWND parent_window)
    : view_id_(view_id),
      messenger_(messenger),
      parent_window_(parent_window),
      webview_window_(nullptr),
      is_initialized_(false) {
  
  std::string channel_name = "real_webview_" + std::to_string(view_id);
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, channel_name, &flutter::StandardMethodCodec::GetInstance());

  SetupMessageHandlers();
}

WebView2Manager::~WebView2Manager() {
  if (webview_window_) {
    DestroyWindow(webview_window_);
  }
}

void WebView2Manager::Initialize(
    const std::map<std::string, flutter::EncodableValue>& params) {
  
  // Create a placeholder window for WebView2
  // In a real implementation, this would initialize WebView2
  // For now, create a simple window as placeholder
  
  webview_window_ = CreateWindowEx(
      0,
      L"STATIC",
      L"WebView2 Placeholder",
      WS_CHILD | WS_VISIBLE,
      0, 0, 800, 600,
      parent_window_,
      nullptr,
      GetModuleHandle(nullptr),
      nullptr);

  if (webview_window_) {
    is_initialized_ = true;
    
    // Extract initial URL if provided
    auto it = params.find("initialUrl");
    if (it != params.end()) {
      auto url_ptr = std::get_if<std::string>(&it->second);
      if (url_ptr) {
        LoadUrl(*url_ptr, nullptr);
      }
    }
  }
}

void WebView2Manager::LoadUrl(
    const std::string& url,
    const std::map<std::string, std::string>* headers) {
  
  current_url_ = url;
  
  // Send load start event
  flutter::EncodableMap event_data;
  event_data[flutter::EncodableValue("url")] = flutter::EncodableValue(url);
  SendEvent("onLoadStart", flutter::EncodableValue(event_data));

  // Simulate load completion after a delay
  // In real implementation, WebView2 would handle this
  flutter::EncodableMap complete_data;
  complete_data[flutter::EncodableValue("url")] = flutter::EncodableValue(url);
  SendEvent("onLoadStop", flutter::EncodableValue(complete_data));
  
  // Send progress
  SendEvent("onProgressChanged", flutter::EncodableValue(100));
}

void WebView2Manager::LoadData(const std::string& data,
                               const std::string& mime_type,
                               const std::string& encoding) {
  // Load HTML data
  current_url_ = "data:text/html," + data;
  SendEvent("onLoadStart", flutter::EncodableValue(current_url_));
  SendEvent("onLoadStop", flutter::EncodableValue(current_url_));
}

void WebView2Manager::Reload() {
  if (!current_url_.empty()) {
    LoadUrl(current_url_, nullptr);
  }
}

void WebView2Manager::GoBack() {
  // Placeholder - would navigate back in history
}

void WebView2Manager::GoForward() {
  // Placeholder - would navigate forward in history
}

bool WebView2Manager::CanGoBack() {
  return false;  // Placeholder
}

bool WebView2Manager::CanGoForward() {
  return false;  // Placeholder
}

void WebView2Manager::EvaluateJavascript(
    const std::string& source,
    std::function<void(std::string)> callback) {
  // Placeholder - would execute JavaScript and return result
  if (callback) {
    callback("null");
  }
}

void WebView2Manager::InjectJavascript(const std::string& source) {
  // Placeholder - would inject JavaScript
}

void WebView2Manager::SetSettings(const flutter::EncodableMap& settings) {
  // Placeholder - would apply WebView2 settings
}

void WebView2Manager::SetBounds(int x, int y, int width, int height) {
  if (webview_window_) {
    SetWindowPos(webview_window_, nullptr, x, y, width, height,
                 SWP_NOZORDER | SWP_NOACTIVATE);
  }
}

void WebView2Manager::SetVisible(bool visible) {
  if (webview_window_) {
    ShowWindow(webview_window_, visible ? SW_SHOW : SW_HIDE);
  }
}

std::string WebView2Manager::GetUrl() {
  return current_url_;
}

std::string WebView2Manager::GetTitle() {
  return current_title_;
}

void WebView2Manager::SetupMessageHandlers() {
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });
}

void WebView2Manager::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto& method = method_call.method_name();

  if (method == "loadUrl") {
    auto args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto url_it = args->find(flutter::EncodableValue("url"));
      if (url_it != args->end()) {
        auto url = std::get<std::string>(url_it->second);
        LoadUrl(url, nullptr);
        result->Success();
        return;
      }
    }
    result->Error("INVALID_ARGS", "URL is required");
  }
  else if (method == "reload") {
    Reload();
    result->Success();
  }
  else if (method == "goBack") {
    GoBack();
    result->Success();
  }
  else if (method == "goForward") {
    GoForward();
    result->Success();
  }
  else if (method == "canGoBack") {
    result->Success(flutter::EncodableValue(CanGoBack()));
  }
  else if (method == "canGoForward") {
    result->Success(flutter::EncodableValue(CanGoForward()));
  }
  else if (method == "getUrl") {
    result->Success(flutter::EncodableValue(GetUrl()));
  }
  else if (method == "getTitle") {
    result->Success(flutter::EncodableValue(GetTitle()));
  }
  else if (method == "evaluateJavascript") {
    auto args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto source_it = args->find(flutter::EncodableValue("source"));
      if (source_it != args->end()) {
        auto source = std::get<std::string>(source_it->second);
        EvaluateJavascript(source, [result = result.get()](std::string res) {
          result->Success(flutter::EncodableValue(res));
        });
        return;
      }
    }
    result->Error("INVALID_ARGS", "Source is required");
  }
  else {
    result->NotImplemented();
  }
}

void WebView2Manager::SendEvent(const std::string& event_name,
                                const flutter::EncodableValue& data) {
  if (channel_) {
    channel_->InvokeMethod(event_name,
                          std::make_unique<flutter::EncodableValue>(data));
  }
}

}  // namespace real_webview
