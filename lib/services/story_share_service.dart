import 'package:flutter/services.dart';

/// Posts a rendered story image straight into the Instagram Stories composer,
/// bypassing the system share sheet.
///
/// Backed by a small platform channel (ADD_TO_STORY intent on Android, the
/// `instagram-stories://` scheme plus pasteboard on iOS) rather than a plugin,
/// so it needs no Facebook SDK and no extra runtime permissions.
class StoryShareService {
  const StoryShareService();

  /// Meta (Facebook) App ID, required by Instagram for story sharing since
  /// January 2023. Register an app at https://developers.facebook.com and put
  /// its ID here — while this is empty the direct-to-Stories path is skipped
  /// and the caller falls back to the system share sheet, because Instagram
  /// would otherwise open only to say sharing is unsupported.
  static const String metaAppId = '';

  static const MethodChannel _channel =
      MethodChannel('com.virabyan.mnac/story_share');

  /// Whether a Meta App ID has been configured. Without one the direct share
  /// cannot work, so callers should not attempt it.
  bool get isConfigured => metaAppId.isNotEmpty;

  /// Whether Instagram is installed and its story composer is reachable.
  Future<bool> isInstagramAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isInstagramInstalled') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Opens the Instagram Stories composer with [imagePath] as the background.
  ///
  /// Returns false when Instagram is missing, unreachable, or no App ID is
  /// configured — the caller is expected to fall back to the share sheet
  /// rather than leaving the user with nothing.
  Future<bool> shareToInstagramStory(String imagePath) async {
    if (!isConfigured) return false;
    try {
      final ok = await _channel.invokeMethod<bool>(
        'shareToInstagramStory',
        {'imagePath': imagePath, 'appId': metaAppId},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
