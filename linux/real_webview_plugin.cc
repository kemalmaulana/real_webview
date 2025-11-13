#include "include/real_webview/real_webview_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <map>
#include <memory>

#include "real_webview_plugin_private.h"
#include "include/real_webview/webkit_manager.h"
#include "include/real_webview/platform_view_factory.h"

#define REAL_WEBVIEW_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), real_webview_plugin_get_type(), \
                              RealWebviewPlugin))

struct _RealWebviewPlugin {
  GObject parent_instance;
  FlPluginRegistrar* registrar;
  std::map<int, std::unique_ptr<real_webview::WebKitManager>>* webview_managers;
  RealWebviewPlatformViewFactory* platform_view_factory;
};

G_DEFINE_TYPE(RealWebviewPlugin, real_webview_plugin, g_object_get_type())

// Called when a method call is received from Flutter.
static void real_webview_plugin_handle_method_call(
    RealWebviewPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else if (strcmp(method, "create") == 0) {
    // Create new WebView instance
    FlValue* args = fl_method_call_get_args(method_call);

    if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGS", "Invalid arguments", nullptr));
    } else {
      FlValue* view_id_value = fl_value_lookup_string(args, "viewId");

      if (!view_id_value || fl_value_get_type(view_id_value) != FL_VALUE_TYPE_INT) {
        response = FL_METHOD_RESPONSE(fl_method_error_response_new(
            "INVALID_ARGS", "Missing viewId", nullptr));
      } else {
        int view_id = fl_value_get_int(view_id_value);

        // Create WebKitManager
        FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(self->registrar);
        auto manager = std::make_unique<real_webview::WebKitManager>(view_id, messenger);

        // Initialize with parameters
        manager->Initialize(args);

        // Store manager
        (*self->webview_managers)[view_id] = std::move(manager);

        g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
        response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
      }
    }
  } else if (strcmp(method, "dispose") == 0) {
    // Dispose WebView instance
    FlValue* args = fl_method_call_get_args(method_call);

    if (args && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* view_id_value = fl_value_lookup_string(args, "viewId");

      if (view_id_value && fl_value_get_type(view_id_value) == FL_VALUE_TYPE_INT) {
        int view_id = fl_value_get_int(view_id_value);
        self->webview_managers->erase(view_id);
      }
    }

    g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void real_webview_plugin_dispose(GObject* object) {
  RealWebviewPlugin* self = REAL_WEBVIEW_PLUGIN(object);

  // Clean up webview managers
  if (self->webview_managers) {
    delete self->webview_managers;
    self->webview_managers = nullptr;
  }

  // Clean up platform view factory
  if (self->platform_view_factory) {
    g_object_unref(self->platform_view_factory);
    self->platform_view_factory = nullptr;
  }

  G_OBJECT_CLASS(real_webview_plugin_parent_class)->dispose(object);
}

static void real_webview_plugin_class_init(RealWebviewPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = real_webview_plugin_dispose;
}

static void real_webview_plugin_init(RealWebviewPlugin* self) {
  // Initialize webview managers map
  self->webview_managers = new std::map<int, std::unique_ptr<real_webview::WebKitManager>>();
  self->platform_view_factory = nullptr;
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  RealWebviewPlugin* plugin = REAL_WEBVIEW_PLUGIN(user_data);
  real_webview_plugin_handle_method_call(plugin, method_call);
}

void real_webview_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  RealWebviewPlugin* plugin = REAL_WEBVIEW_PLUGIN(
      g_object_new(real_webview_plugin_get_type(), nullptr));

  // Store registrar
  plugin->registrar = registrar;

  // Create platform view factory
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  plugin->platform_view_factory = real_webview_platform_view_factory_new(messenger);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(messenger,
                            "real_webview",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
