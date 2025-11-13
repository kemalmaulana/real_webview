#include "include/real_webview/real_webview_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "real_webview_plugin.h"

void RealWebviewPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  real_webview::RealWebviewPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
