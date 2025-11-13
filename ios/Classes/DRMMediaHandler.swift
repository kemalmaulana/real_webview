import Foundation
import WebKit
import AVFoundation

/// Handles automatic DRM detection and configuration for iOS
/// Mimics Safari's automatic FairPlay handling
class DRMMediaHandler {

    /// Enable automatic DRM support in WKWebView
    static func enableAutoDRM(webView: WKWebView) {
        // Inject JavaScript for EME support
        injectEMESupport(webView: webView)

        // Configure for FairPlay
        configureFairPlaySupport(webView: webView)
    }

    /// Inject JavaScript to enable EME automatically
    private static func injectEMESupport(webView: WKWebView) {
        let emeScript = """
        (function() {
            // EME (Encrypted Media Extensions) Auto-Configuration for iOS/Safari
            console.log('[RealWebView] Enabling automatic FairPlay DRM support');

            // Store original requestMediaKeySystemAccess
            const originalRequestMediaKeySystemAccess = navigator.requestMediaKeySystemAccess;

            // Override to add automatic configuration
            if (navigator.requestMediaKeySystemAccess) {
                navigator.requestMediaKeySystemAccess = function(keySystem, supportedConfigurations) {
                    console.log('[RealWebView] DRM requested:', keySystem);

                    // Auto-configure for FairPlay
                    let enhancedConfigs = supportedConfigurations;

                    // If no configurations provided, use defaults for FairPlay
                    if (!enhancedConfigs || enhancedConfigs.length === 0) {
                        enhancedConfigs = [{
                            initDataTypes: ['skd', 'sinf'],
                            audioCapabilities: [
                                { contentType: 'audio/mp4; codecs="mp4a.40.2"' },
                                { contentType: 'audio/mp4; codecs="ac-3"' },
                                { contentType: 'audio/mp4; codecs="ec-3"' }
                            ],
                            videoCapabilities: [
                                { contentType: 'video/mp4; codecs="avc1.42E01E"' },
                                { contentType: 'video/mp4; codecs="avc1.4d401e"' },
                                { contentType: 'video/mp4; codecs="hvc1.1.6.L93.B0"' },
                                { contentType: 'video/mp4; codecs="hev1.1.6.L93.B0"' }
                            ],
                            distinctiveIdentifier: 'not-allowed',
                            persistentState: 'optional',
                            sessionTypes: ['temporary']
                        }];
                    }

                    return originalRequestMediaKeySystemAccess.call(navigator, keySystem, enhancedConfigs);
                };
            }

            // Auto-handle WebKit Encrypted Media
            if (window.WebKitMediaKeys) {
                console.log('[RealWebView] WebKit Media Keys API detected');

                // Monitor all video elements
                document.addEventListener('DOMContentLoaded', function() {
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
                    console.log('[RealWebView] Setting up media element for FairPlay');

                    // Allow inline playback
                    mediaElement.setAttribute('playsinline', '');
                    mediaElement.setAttribute('webkit-playsinline', '');

                    // Handle WebKit needkey event (legacy)
                    mediaElement.addEventListener('webkitneedkey', function(event) {
                        console.log('[RealWebView] WebKit need key event');
                        handleWebKitNeedKey(event, mediaElement);
                    });

                    // Handle modern encrypted event
                    mediaElement.addEventListener('encrypted', function(event) {
                        console.log('[RealWebView] Encrypted media detected');
                        handleEncrypted(event, mediaElement);
                    });
                }

                function handleWebKitNeedKey(event, mediaElement) {
                    // Extract content ID from initData
                    const initData = event.initData;
                    if (!initData) return;

                    // Try FairPlay
                    const keySystem = 'com.apple.fps.1_0';

                    if (window.WebKitMediaKeys.isTypeSupported(keySystem, 'video/mp4')) {
                        console.log('[RealWebView] FairPlay supported');

                        const mediaKeys = new window.WebKitMediaKeys(keySystem);
                        mediaElement.webkitSetMediaKeys(mediaKeys);

                        const keySession = mediaKeys.createSession('video/mp4', initData);

                        // The session will automatically handle license requests
                        // for properly configured FairPlay streams
                    }
                }

                function handleEncrypted(event, mediaElement) {
                    const keySystem = 'com.apple.fps.1_0';

                    navigator.requestMediaKeySystemAccess(keySystem, [{
                        initDataTypes: [event.initDataType || 'skd'],
                        audioCapabilities: [{ contentType: 'audio/mp4; codecs="mp4a.40.2"' }],
                        videoCapabilities: [{ contentType: 'video/mp4; codecs="avc1.42E01E"' }]
                    }])
                    .then(function(keySystemAccess) {
                        return keySystemAccess.createMediaKeys();
                    })
                    .then(function(mediaKeys) {
                        return mediaElement.setMediaKeys(mediaKeys);
                    })
                    .then(function() {
                        const session = mediaElement.mediaKeys.createSession();
                        return session.generateRequest(
                            event.initDataType,
                            event.initData
                        );
                    })
                    .catch(function(error) {
                        console.error('[RealWebView] FairPlay setup error:', error);
                    });
                }
            }

            // Handle HLS with FairPlay automatically
            if (window.MediaSource || window.WebKitMediaSource) {
                console.log('[RealWebView] Media Source Extensions available');
            }

            console.log('[RealWebView] Auto-FairPlay support enabled');
        })();
        """

        let userScript = WKUserScript(
            source: emeScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        webView.configuration.userContentController.addUserScript(userScript)
    }

    /// Configure FairPlay support
    private static func configureFairPlaySupport(webView: WKWebView) {
        // Enable media playback without user interaction
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []

        // Enable PiP if available
        if #available(iOS 14.0, *) {
            webView.configuration.allowsPictureInPictureMediaPlayback = true
        }

        // Enable AirPlay
        webView.configuration.allowsAirPlayForMediaPlayback = true
    }

    /// Check if URL is for HLS stream
    static func isHLSStream(url: String) -> Bool {
        return url.contains(".m3u8") || url.contains("/playlist.m3u8")
    }

    /// Check if URL is for DASH stream
    static func isDASHStream(url: String) -> Bool {
        return url.contains(".mpd") || url.contains("/manifest.mpd")
    }
}
