#ifndef FLUTTER_PLUGIN_PLATFORM_VIEW_FACTORY_H_
#define FLUTTER_PLUGIN_PLATFORM_VIEW_FACTORY_H_

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include "webkit_manager.h"

G_BEGIN_DECLS

#define REAL_WEBVIEW_TYPE_PLATFORM_VIEW_FACTORY \
    (real_webview_platform_view_factory_get_type())

G_DECLARE_FINAL_TYPE(RealWebviewPlatformViewFactory,
                     real_webview_platform_view_factory,
                     REAL_WEBVIEW,
                     PLATFORM_VIEW_FACTORY,
                     GObject)

RealWebviewPlatformViewFactory* real_webview_platform_view_factory_new(
    FlBinaryMessenger* messenger);

GtkWidget* real_webview_platform_view_factory_create(
    RealWebviewPlatformViewFactory* factory,
    int view_id,
    FlValue* params);

G_END_DECLS

#endif  // FLUTTER_PLUGIN_PLATFORM_VIEW_FACTORY_H_
