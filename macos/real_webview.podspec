Pod::Spec.new do |s|
  s.name             = 'real_webview'
  s.version          = '0.0.1'
  s.summary          = 'A Chrome-based WebView plugin for Flutter supporting all platforms.'
  s.description      = <<-DESC
A Chrome-based WebView plugin for Flutter that works on all platforms with DRM support.
Supports macOS with WKWebView and automatic DRM handling.
                       DESC
  s.homepage         = 'https://github.com/yourusername/real_webview'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
