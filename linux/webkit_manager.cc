#include "include/real_webview/webkit_manager.h"

#include <cstring>
#include <iostream>

namespace real_webview {

// JavaScript callback data structure
struct JavascriptCallbackData {
  std::function<void(const char*, const char*)> callback;
};

WebKitManager::WebKitManager(int view_id, FlBinaryMessenger* messenger)
    : view_id_(view_id),
      webview_(nullptr),
      content_manager_(nullptr),
      channel_(nullptr),
      messenger_(messenger),
      is_initialized_(false) {

  // Create method channel for this webview instance
  std::string channel_name = "real_webview_" + std::to_string(view_id);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel_ = fl_method_channel_new(
      messenger,
      channel_name.c_str(),
      FL_METHOD_CODEC(codec));
}

WebKitManager::~WebKitManager() {
  if (channel_) {
    g_object_unref(channel_);
  }
}

GtkWidget* WebKitManager::Initialize(FlValue* params) {
  if (is_initialized_) {
    return GTK_WIDGET(webview_);
  }

  // Create user content manager
  content_manager_ = webkit_user_content_manager_new();

  // Create WebKit settings
  WebKitSettings* settings = webkit_settings_new();
  webkit_settings_set_enable_javascript(settings, TRUE);
  webkit_settings_set_enable_media_stream(settings, TRUE);
  webkit_settings_set_enable_encrypted_media(settings, TRUE);
  webkit_settings_set_enable_webaudio(settings, TRUE);
  webkit_settings_set_enable_webgl(settings, TRUE);
  webkit_settings_set_hardware_acceleration_policy(
      settings, WEBKIT_HARDWARE_ACCELERATION_POLICY_ALWAYS);

  // Create WebView
  webview_ = WEBKIT_WEB_VIEW(webkit_web_view_new_with_user_content_manager(content_manager_));
  webkit_web_view_set_settings(webview_, settings);

  // Setup callbacks
  SetupCallbacks();

  // Parse initialization parameters
  if (params && fl_value_get_type(params) == FL_VALUE_TYPE_MAP) {
    // Load initial URL if provided
    FlValue* initial_url = fl_value_lookup_string(params, "initialUrl");
    if (initial_url && fl_value_get_type(initial_url) == FL_VALUE_TYPE_STRING) {
      const char* url = fl_value_get_string(initial_url);
      webkit_web_view_load_uri(webview_, url);
    }

    // Load initial HTML if provided
    FlValue* initial_data = fl_value_lookup_string(params, "initialData");
    if (initial_data && fl_value_get_type(initial_data) == FL_VALUE_TYPE_STRING) {
      const char* html = fl_value_get_string(initial_data);
      webkit_web_view_load_html(webview_, html, nullptr);
    }

    // Apply initial settings
    FlValue* initial_settings = fl_value_lookup_string(params, "initialSettings");
    if (initial_settings && fl_value_get_type(initial_settings) == FL_VALUE_TYPE_MAP) {
      ApplySettings(initial_settings);
    }
  }

  is_initialized_ = true;
  g_object_unref(settings);

  return GTK_WIDGET(webview_);
}

void WebKitManager::SetupCallbacks() {
  // Load change events
  g_signal_connect(webview_, "load-changed",
                   G_CALLBACK(OnLoadChanged), this);

  // Load failure events
  g_signal_connect(webview_, "load-failed",
                   G_CALLBACK(OnLoadFailed), this);

  // URL change events
  g_signal_connect(webview_, "notify::uri",
                   G_CALLBACK(OnUriChanged), this);

  // Title change events
  g_signal_connect(webview_, "notify::title",
                   G_CALLBACK(OnTitleChanged), this);

  // Progress change events
  g_signal_connect(webview_, "notify::estimated-load-progress",
                   G_CALLBACK(OnEstimatedProgressChanged), this);
}

void WebKitManager::LoadUrl(const char* url, FlValue* headers) {
  if (!webview_) return;

  current_url_ = url;

  if (headers && fl_value_get_type(headers) == FL_VALUE_TYPE_MAP) {
    // TODO: Implement custom headers support
    // WebKit doesn't directly support custom headers in load_uri
    // Would need to use WebKitURIRequest
  }

  webkit_web_view_load_uri(webview_, url);
}

void WebKitManager::Reload() {
  if (!webview_) return;
  webkit_web_view_reload(webview_);
}

void WebKitManager::GoBack() {
  if (!webview_) return;
  webkit_web_view_go_back(webview_);
}

void WebKitManager::GoForward() {
  if (!webview_) return;
  webkit_web_view_go_forward(webview_);
}

bool WebKitManager::CanGoBack() {
  if (!webview_) return false;
  return webkit_web_view_can_go_back(webview_);
}

bool WebKitManager::CanGoForward() {
  if (!webview_) return false;
  return webkit_web_view_can_go_forward(webview_);
}

const char* WebKitManager::GetUrl() {
  if (!webview_) return "";
  const char* uri = webkit_web_view_get_uri(webview_);
  return uri ? uri : "";
}

const char* WebKitManager::GetTitle() {
  if (!webview_) return "";
  const char* title = webkit_web_view_get_title(webview_);
  return title ? title : "";
}

void WebKitManager::EvaluateJavascript(
    const char* source,
    std::function<void(const char*, const char*)> callback) {
  if (!webview_) {
    callback(nullptr, "WebView not initialized");
    return;
  }

  JavascriptCallbackData* data = new JavascriptCallbackData();
  data->callback = callback;

  webkit_web_view_run_javascript(
      webview_,
      source,
      nullptr,
      OnJavascriptFinished,
      data);
}

void WebKitManager::OnJavascriptFinished(GObject* object,
                                        GAsyncResult* result,
                                        gpointer user_data) {
  JavascriptCallbackData* data = static_cast<JavascriptCallbackData*>(user_data);

  GError* error = nullptr;
  WebKitJavascriptResult* js_result = webkit_web_view_run_javascript_finish(
      WEBKIT_WEB_VIEW(object), result, &error);

  if (error) {
    data->callback(nullptr, error->message);
    g_error_free(error);
  } else if (js_result) {
    JSCValue* value = webkit_javascript_result_get_js_value(js_result);
    g_autofree char* str_value = jsc_value_to_string(value);
    data->callback(str_value, nullptr);
    webkit_javascript_result_unref(js_result);
  } else {
    data->callback(nullptr, "Unknown error");
  }

  delete data;
}

void WebKitManager::AddUserScript(const char* source, int injection_time) {
  if (!content_manager_) return;

  WebKitUserScriptInjectionTime webkit_injection_time =
      (injection_time == 0) ? WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_START
                            : WEBKIT_USER_SCRIPT_INJECT_AT_DOCUMENT_END;

  WebKitUserScript* script = webkit_user_script_new(
      source,
      WEBKIT_USER_CONTENT_INJECT_ALL_FRAMES,
      webkit_injection_time,
      nullptr,
      nullptr);

  webkit_user_content_manager_add_script(content_manager_, script);
  webkit_user_script_unref(script);
}

void WebKitManager::SetSettings(FlValue* settings) {
  if (!webview_) return;
  ApplySettings(settings);
}

void WebKitManager::ApplySettings(FlValue* settings) {
  if (!settings || fl_value_get_type(settings) != FL_VALUE_TYPE_MAP) {
    return;
  }

  WebKitSettings* webkit_settings = webkit_web_view_get_settings(webview_);

  // JavaScript enabled
  FlValue* js_enabled = fl_value_lookup_string(settings, "javaScriptEnabled");
  if (js_enabled && fl_value_get_type(js_enabled) == FL_VALUE_TYPE_BOOL) {
    webkit_settings_set_enable_javascript(
        webkit_settings, fl_value_get_bool(js_enabled));
  }

  // User agent
  FlValue* user_agent = fl_value_lookup_string(settings, "userAgent");
  if (user_agent && fl_value_get_type(user_agent) == FL_VALUE_TYPE_STRING) {
    webkit_settings_set_user_agent(
        webkit_settings, fl_value_get_string(user_agent));
  }

  // Media playback
  FlValue* media_playback = fl_value_lookup_string(settings, "mediaPlaybackRequiresUserGesture");
  if (media_playback && fl_value_get_type(media_playback) == FL_VALUE_TYPE_BOOL) {
    webkit_settings_set_media_playback_requires_user_gesture(
        webkit_settings, fl_value_get_bool(media_playback));
  }

  // Zoom
  FlValue* supports_zoom = fl_value_lookup_string(settings, "supportZoom");
  if (supports_zoom && fl_value_get_type(supports_zoom) == FL_VALUE_TYPE_BOOL) {
    webkit_settings_set_zoom_text_only(
        webkit_settings, !fl_value_get_bool(supports_zoom));
  }
}

void WebKitManager::StopLoading() {
  if (!webview_) return;
  webkit_web_view_stop_loading(webview_);
}

// Callback implementations
void WebKitManager::OnLoadChanged(WebKitWebView* web_view,
                                 WebKitLoadEvent load_event,
                                 gpointer user_data) {
  WebKitManager* manager = static_cast<WebKitManager*>(user_data);

  const char* uri = webkit_web_view_get_uri(web_view);
  g_autoptr(FlValue) url_value = fl_value_new_string(uri ? uri : "");

  switch (load_event) {
    case WEBKIT_LOAD_STARTED:
      manager->SendEvent("onLoadStart", url_value);
      manager->SendEvent("onProgressChanged", fl_value_new_int(0));
      break;

    case WEBKIT_LOAD_COMMITTED:
      // Page committed, navigation confirmed
      break;

    case WEBKIT_LOAD_FINISHED:
      manager->SendEvent("onLoadStop", url_value);
      manager->SendEvent("onProgressChanged", fl_value_new_int(100));
      break;

    default:
      break;
  }
}

gboolean WebKitManager::OnLoadFailed(WebKitWebView* web_view,
                                    WebKitLoadEvent load_event,
                                    gchar* failing_uri,
                                    GError* error,
                                    gpointer user_data) {
  WebKitManager* manager = static_cast<WebKitManager*>(user_data);

  g_autoptr(FlValue) error_map = fl_value_new_map();
  fl_value_set_string_take(error_map, "code", fl_value_new_int(error->code));
  fl_value_set_string_take(error_map, "description", fl_value_new_string(error->message));
  fl_value_set_string_take(error_map, "url", fl_value_new_string(failing_uri));

  manager->SendEvent("onLoadError", error_map);

  return FALSE;  // Allow default error handling
}

void WebKitManager::OnUriChanged(WebKitWebView* web_view,
                                GParamSpec* pspec,
                                gpointer user_data) {
  WebKitManager* manager = static_cast<WebKitManager*>(user_data);
  const char* uri = webkit_web_view_get_uri(web_view);

  if (uri) {
    manager->current_url_ = uri;
    g_autoptr(FlValue) url_value = fl_value_new_string(uri);
    manager->SendEvent("onUrlChanged", url_value);
  }
}

void WebKitManager::OnTitleChanged(WebKitWebView* web_view,
                                  GParamSpec* pspec,
                                  gpointer user_data) {
  WebKitManager* manager = static_cast<WebKitManager*>(user_data);
  const char* title = webkit_web_view_get_title(web_view);

  if (title) {
    g_autoptr(FlValue) title_value = fl_value_new_string(title);
    manager->SendEvent("onTitleChanged", title_value);
  }
}

void WebKitManager::OnEstimatedProgressChanged(WebKitWebView* web_view,
                                              GParamSpec* pspec,
                                              gpointer user_data) {
  WebKitManager* manager = static_cast<WebKitManager*>(user_data);
  gdouble progress = webkit_web_view_get_estimated_load_progress(web_view);

  int progress_percent = static_cast<int>(progress * 100);
  g_autoptr(FlValue) progress_value = fl_value_new_int(progress_percent);
  manager->SendEvent("onProgressChanged", progress_value);
}

void WebKitManager::SendEvent(const char* event_name, FlValue* data) {
  if (!channel_) return;

  fl_method_channel_invoke_method(
      channel_,
      event_name,
      data,
      nullptr,
      nullptr,
      nullptr);
}

}  // namespace real_webview
