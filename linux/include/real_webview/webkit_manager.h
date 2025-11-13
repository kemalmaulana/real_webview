#ifndef FLUTTER_PLUGIN_WEBKIT_MANAGER_H_
#define FLUTTER_PLUGIN_WEBKIT_MANAGER_H_

#include <flutter_linux/flutter_linux.h>
#include <webkit2/webkit2.h>
#include <gtk/gtk.h>
#include <map>
#include <string>
#include <functional>

namespace real_webview {

class WebKitManager {
 public:
  WebKitManager(int view_id, FlBinaryMessenger* messenger);
  ~WebKitManager();

  // WebView operations
  GtkWidget* Initialize(FlValue* params);
  void LoadUrl(const char* url, FlValue* headers);
  void Reload();
  void GoBack();
  void GoForward();
  bool CanGoBack();
  bool CanGoForward();
  const char* GetUrl();
  const char* GetTitle();
  void EvaluateJavascript(const char* source,
                         std::function<void(const char*, const char*)> callback);
  void AddUserScript(const char* source, int injection_time);
  void SetSettings(FlValue* settings);
  void StopLoading();

  GtkWidget* GetWebView() { return GTK_WIDGET(webview_); }

 private:
  // GTK/WebKit callbacks
  static void OnLoadChanged(WebKitWebView* web_view,
                           WebKitLoadEvent load_event,
                           gpointer user_data);
  static gboolean OnLoadFailed(WebKitWebView* web_view,
                              WebKitLoadEvent load_event,
                              gchar* failing_uri,
                              GError* error,
                              gpointer user_data);
  static void OnUriChanged(WebKitWebView* web_view,
                          GParamSpec* pspec,
                          gpointer user_data);
  static void OnTitleChanged(WebKitWebView* web_view,
                            GParamSpec* pspec,
                            gpointer user_data);
  static void OnEstimatedProgressChanged(WebKitWebView* web_view,
                                        GParamSpec* pspec,
                                        gpointer user_data);
  static void OnJavascriptFinished(GObject* object,
                                  GAsyncResult* result,
                                  gpointer user_data);

  // Helper methods
  void SendEvent(const char* event_name, FlValue* data);
  void SetupCallbacks();
  void ApplySettings(FlValue* settings);

  int view_id_;
  WebKitWebView* webview_;
  WebKitUserContentManager* content_manager_;
  FlMethodChannel* channel_;
  FlBinaryMessenger* messenger_;
  std::string current_url_;
  bool is_initialized_;
};

}  // namespace real_webview

#endif  // FLUTTER_PLUGIN_WEBKIT_MANAGER_H_
