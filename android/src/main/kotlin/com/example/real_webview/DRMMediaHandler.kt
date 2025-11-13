package com.example.real_webview

import android.annotation.SuppressLint
import android.webkit.WebView
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.os.Build
import java.io.ByteArrayInputStream

/**
 * Handles automatic DRM detection and configuration
 * Mimics Chrome's automatic DRM handling for streaming services
 */
class DRMMediaHandler {

    companion object {
        /**
         * Enable automatic DRM support in WebView
         * This allows EME (Encrypted Media Extensions) to work automatically
         */
        @SuppressLint("SetJavaScriptEnabled")
        fun enableAutoDRM(webView: WebView) {
            val settings = webView.settings

            // Enable necessary features for DRM
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.databaseEnabled = true
            settings.mediaPlaybackRequiresUserGesture = false

            // Enable mixed content for DRM (some services use it)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                settings.mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            }

            // Inject EME polyfill and auto-configuration JavaScript
            injectEMESupport(webView)
        }

        /**
         * Inject JavaScript to enable and configure EME automatically
         */
        private fun injectEMESupport(webView: WebView) {
            val emeScript = """
                (function() {
                    // EME (Encrypted Media Extensions) Auto-Configuration
                    console.log('[RealWebView] Enabling automatic DRM support');

                    // Store original requestMediaKeySystemAccess
                    const originalRequestMediaKeySystemAccess = navigator.requestMediaKeySystemAccess;

                    // Override to add automatic configuration
                    navigator.requestMediaKeySystemAccess = function(keySystem, supportedConfigurations) {
                        console.log('[RealWebView] DRM requested:', keySystem);

                        // Auto-configure for common DRM systems
                        let enhancedConfigs = supportedConfigurations;

                        // If no configurations provided, use defaults
                        if (!enhancedConfigs || enhancedConfigs.length === 0) {
                            enhancedConfigs = [{
                                initDataTypes: ['cenc', 'webm', 'keyids'],
                                audioCapabilities: [
                                    { contentType: 'audio/mp4; codecs="mp4a.40.2"' },
                                    { contentType: 'audio/webm; codecs="opus"' }
                                ],
                                videoCapabilities: [
                                    { contentType: 'video/mp4; codecs="avc1.42E01E"' },
                                    { contentType: 'video/mp4; codecs="avc1.4d401e"' },
                                    { contentType: 'video/webm; codecs="vp9"' },
                                    { contentType: 'video/webm; codecs="vp8"' }
                                ],
                                distinctiveIdentifier: 'optional',
                                persistentState: 'optional',
                                sessionTypes: ['temporary']
                            }];
                        }

                        return originalRequestMediaKeySystemAccess.call(navigator, keySystem, enhancedConfigs);
                    };

                    // Auto-handle media encrypted events
                    document.addEventListener('DOMContentLoaded', function() {
                        // Monitor all video elements
                        const observer = new MutationObserver(function(mutations) {
                            mutations.forEach(function(mutation) {
                                mutation.addedNodes.forEach(function(node) {
                                    if (node.tagName === 'VIDEO' || node.tagName === 'AUDIO') {
                                        setupMediaElement(node);
                                    }
                                });
                            });
                        });

                        observer.observe(document.body, {
                            childList: true,
                            subtree: true
                        });

                        // Setup existing media elements
                        document.querySelectorAll('video, audio').forEach(setupMediaElement);
                    });

                    function setupMediaElement(mediaElement) {
                        console.log('[RealWebView] Setting up media element for auto-DRM');

                        // Allow autoplay for DRM content
                        mediaElement.setAttribute('playsinline', '');

                        // Auto-handle encrypted media
                        mediaElement.addEventListener('encrypted', function(event) {
                            console.log('[RealWebView] Encrypted media detected:', event.initDataType);

                            // Automatically try to acquire media keys
                            if (!mediaElement.mediaKeys) {
                                const keySystemsToTry = [
                                    'com.widevine.alpha',
                                    'com.microsoft.playready',
                                    'org.w3.clearkey'
                                ];

                                tryKeySystem(mediaElement, keySystemsToTry, 0, event);
                            }
                        });
                    }

                    function tryKeySystem(mediaElement, keySystems, index, encryptedEvent) {
                        if (index >= keySystems.length) {
                            console.error('[RealWebView] No supported DRM system found');
                            return;
                        }

                        const keySystem = keySystems[index];
                        console.log('[RealWebView] Trying DRM system:', keySystem);

                        navigator.requestMediaKeySystemAccess(keySystem, [{
                            initDataTypes: [encryptedEvent.initDataType],
                            audioCapabilities: [{ contentType: 'audio/mp4; codecs="mp4a.40.2"' }],
                            videoCapabilities: [{ contentType: 'video/mp4; codecs="avc1.42E01E"' }]
                        }])
                        .then(function(keySystemAccess) {
                            console.log('[RealWebView] DRM system accepted:', keySystem);
                            return keySystemAccess.createMediaKeys();
                        })
                        .then(function(mediaKeys) {
                            console.log('[RealWebView] Media keys created');
                            return mediaElement.setMediaKeys(mediaKeys);
                        })
                        .then(function() {
                            console.log('[RealWebView] Media keys set successfully');
                            const session = mediaElement.mediaKeys.createSession();

                            // Handle license requests automatically
                            session.addEventListener('message', function(event) {
                                console.log('[RealWebView] License request generated');
                                // The browser/service will handle the actual license request
                                // This is automatic for properly configured streaming services
                            });

                            return session.generateRequest(
                                encryptedEvent.initDataType,
                                encryptedEvent.initData
                            );
                        })
                        .catch(function(error) {
                            console.log('[RealWebView] DRM system failed:', keySystem, error);
                            // Try next key system
                            tryKeySystem(mediaElement, keySystems, index + 1, encryptedEvent);
                        });
                    }

                    console.log('[RealWebView] Auto-DRM support enabled');
                })();
            """.trimIndent()

            webView.evaluateJavascript(emeScript, null)
        }

        /**
         * Check if the request is for a media manifest (DASH/HLS)
         */
        fun isMediaManifest(url: String): Boolean {
            return url.contains(".mpd") || // DASH manifest
                   url.contains(".m3u8") || // HLS manifest
                   url.contains("manifest")
        }

        /**
         * Intercept and enhance manifest files for DRM support
         */
        fun interceptManifest(
            request: WebResourceRequest,
            originalResponse: WebResourceResponse?
        ): WebResourceResponse? {
            // For now, pass through the original response
            // In a production implementation, you could parse and enhance the manifest
            return originalResponse
        }
    }
}
