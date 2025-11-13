//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <real_webview/real_webview_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) real_webview_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "RealWebviewPlugin");
  real_webview_plugin_register_with_registrar(real_webview_registrar);
}
