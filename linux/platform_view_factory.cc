#include "include/real_webview/platform_view_factory.h"
#include "include/real_webview/webkit_manager.h"

#include <map>
#include <memory>

struct _RealWebviewPlatformViewFactory {
  GObject parent_instance;
  FlBinaryMessenger* messenger;
  std::map<int, std::unique_ptr<real_webview::WebKitManager>>* managers;
};

G_DEFINE_TYPE(RealWebviewPlatformViewFactory,
              real_webview_platform_view_factory,
              G_TYPE_OBJECT)

static void real_webview_platform_view_factory_dispose(GObject* object) {
  RealWebviewPlatformViewFactory* self =
      REAL_WEBVIEW_PLATFORM_VIEW_FACTORY(object);

  if (self->managers) {
    delete self->managers;
    self->managers = nullptr;
  }

  G_OBJECT_CLASS(real_webview_platform_view_factory_parent_class)->dispose(object);
}

static void real_webview_platform_view_factory_class_init(
    RealWebviewPlatformViewFactoryClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = real_webview_platform_view_factory_dispose;
}

static void real_webview_platform_view_factory_init(
    RealWebviewPlatformViewFactory* self) {
  self->managers = new std::map<int, std::unique_ptr<real_webview::WebKitManager>>();
}

RealWebviewPlatformViewFactory* real_webview_platform_view_factory_new(
    FlBinaryMessenger* messenger) {
  RealWebviewPlatformViewFactory* factory =
      REAL_WEBVIEW_PLATFORM_VIEW_FACTORY(g_object_new(
          REAL_WEBVIEW_TYPE_PLATFORM_VIEW_FACTORY, nullptr));

  factory->messenger = messenger;

  return factory;
}

GtkWidget* real_webview_platform_view_factory_create(
    RealWebviewPlatformViewFactory* factory,
    int view_id,
    FlValue* params) {

  // Create WebKitManager
  auto manager = std::make_unique<real_webview::WebKitManager>(
      view_id, factory->messenger);

  // Initialize and get the WebView widget
  GtkWidget* webview = manager->Initialize(params);

  // Store the manager
  (*factory->managers)[view_id] = std::move(manager);

  return webview;
}
