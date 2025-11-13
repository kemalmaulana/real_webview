#include "include/real_webview/real_webview_plugin.h"
#include "include/real_webview/webview2_manager.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <map>

namespace real_webview {

class RealWebviewPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar);
  virtual ~RealWebviewPlugin();

  RealWebviewPlugin(const RealWebviewPlugin&) = delete;
  RealWebviewPlugin& operator=(const RealWebviewPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::PluginRegistrarWindows* registrar_;
  std::map<int, std::unique_ptr<WebView2Manager>> webview_managers_;
};

// static
void RealWebviewPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "real_webview",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<RealWebviewPlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

RealWebviewPlugin::RealWebviewPlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar) {}

RealWebviewPlugin::~RealWebviewPlugin() {}

void RealWebviewPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {

  if (method_call.method_name() == "getPlatformVersion") {
    std::ostringstream version_stream;
    version_stream << "Windows";
    result->Success(flutter::EncodableValue(version_stream.str()));
    return;
  }

  if (method_call.method_name() == "create") {
    // Create new WebView instance
    auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto view_id_it = arguments->find(flutter::EncodableValue("viewId"));
      if (view_id_it != arguments->end()) {
        auto view_id = std::get<int>(view_id_it->second);

        // Get parent window handle
        HWND hwnd = registrar_->GetView()->GetNativeWindow();

        // Create WebView2Manager
        auto manager = std::make_unique<WebView2Manager>(
            view_id,
            registrar_->messenger(),
            hwnd);

        // Initialize with params
        std::map<std::string, flutter::EncodableValue> params;
        for (const auto& pair : *arguments) {
          auto key = std::get<std::string>(pair.first);
          params[key] = pair.second;
        }
        manager->Initialize(params);

        webview_managers_[view_id] = std::move(manager);
        result->Success(flutter::EncodableValue(true));
        return;
      }
    }
    result->Error("INVALID_ARGS", "Invalid arguments");
    return;
  }

  result->NotImplemented();
}

}  // namespace real_webview

void RealWebviewPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  real_webview::RealWebviewPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
