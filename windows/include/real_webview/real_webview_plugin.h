#ifndef FLUTTER_PLUGIN_REAL_WEBVIEW_PLUGIN_H_
#define FLUTTER_PLUGIN_REAL_WEBVIEW_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <map>

namespace real_webview {

// Forward declaration
class WebView2Manager;

class RealWebviewPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~RealWebviewPlugin();

  // Disallow copy and assign.
  RealWebviewPlugin(const RealWebviewPlugin&) = delete;
  RealWebviewPlugin& operator=(const RealWebviewPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_;
  std::map<int, std::unique_ptr<WebView2Manager>> webview_managers_;
};

}  // namespace real_webview

#endif  // FLUTTER_PLUGIN_REAL_WEBVIEW_PLUGIN_H_
