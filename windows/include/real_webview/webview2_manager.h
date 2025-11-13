#ifndef WEBVIEW2_MANAGER_H_
#define WEBVIEW2_MANAGER_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>
#include <memory>
#include <string>
#include <map>

namespace real_webview {

class WebView2Manager {
 public:
  WebView2Manager(int view_id,
                  flutter::BinaryMessenger* messenger,
                  HWND parent_window);
  ~WebView2Manager();

  // Initialize WebView2
  void Initialize(const std::map<std::string, flutter::EncodableValue>& params);

  // Navigation
  void LoadUrl(const std::string& url,
               const std::map<std::string, std::string>* headers);
  void LoadData(const std::string& data,
                const std::string& mime_type,
                const std::string& encoding);
  void Reload();
  void GoBack();
  void GoForward();
  bool CanGoBack();
  bool CanGoForward();

  // JavaScript
  void EvaluateJavascript(const std::string& source,
                          std::function<void(std::string)> callback);
  void InjectJavascript(const std::string& source);

  // Settings
  void SetSettings(const flutter::EncodableMap& settings);

  // Window operations
  void SetBounds(int x, int y, int width, int height);
  void SetVisible(bool visible);

  // Getters
  std::string GetUrl();
  std::string GetTitle();

 private:
  void SetupMessageHandlers();
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SendEvent(const std::string& event_name,
                 const flutter::EncodableValue& data);

  int view_id_;
  HWND parent_window_;
  HWND webview_window_;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  flutter::BinaryMessenger* messenger_;

  std::string current_url_;
  std::string current_title_;
  bool is_initialized_;
};

}  // namespace real_webview

#endif  // WEBVIEW2_MANAGER_H_
