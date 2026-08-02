import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/service_progress.dart';
import '../../domain/entities/soldier_profile.dart';
import '../../services/story_share_service.dart';
import '../../services/widget_to_image.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/primary_button.dart';
import 'share_card.dart';

/// Shows a preview of the shareable [ShareCard] and lets the user export it as
/// an image via the system share sheet.
///
/// Takes a [ServiceProgress] snapshot captured at open time so the preview does
/// not tick (and stays stable while being captured).
class ShareCardScreen extends StatefulWidget {
  const ShareCardScreen({
    super.key,
    required this.profile,
    required this.progress,
  });

  final SoldierProfile profile;
  final ServiceProgress progress;

  @override
  State<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends State<ShareCardScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  static const _storyShare = StoryShareService();
  bool _busy = false;

  /// Shares through the system sheet (Instagram included, among everything
  /// else that accepts an image).
  Future<void> _share() => _run((path) async {
        final days = widget.progress.daysRemaining < 0
            ? 0
            : widget.progress.daysRemaining;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: AppStrings.shareText(days),
            subject: AppStrings.appName,
          ),
        );
      });

  /// Opens the Instagram Stories composer directly. Falls back to the system
  /// sheet whenever that is not possible — Instagram missing, no Meta App ID
  /// configured — so the button never dead-ends.
  Future<void> _shareToStory() => _run((path) async {
        final opened = await _storyShare.shareToInstagramStory(path);
        if (opened || !mounted) return;
        final days = widget.progress.daysRemaining < 0
            ? 0
            : widget.progress.daysRemaining;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            text: AppStrings.shareText(days),
            subject: AppStrings.appName,
          ),
        );
      });

  /// Captures the card once, then hands the file to [action], with the busy
  /// flag and error reporting shared by both buttons.
  Future<void> _run(Future<void> Function(String path) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(await captureBoundaryToPng(_boundaryKey));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.shareFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text(AppStrings.shareTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  // Rounded only for the preview — the clip sits outside the
                  // boundary, so the captured story image stays full-bleed.
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      // The boundary wraps the natural-size card so it is
                      // captured at full resolution regardless of the preview
                      // scaling.
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: ShareCard(
                          profile: widget.profile,
                          progress: widget.progress,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              // Without a Meta App ID the direct path always falls back to the
              // system sheet, so a button promising "Instagram Stories" would
              // just look broken. Hide it until an ID is configured; it comes
              // back on its own once one is set.
              if (_storyShare.isConfigured) ...[
                PrimaryButton(
                  label: AppStrings.shareToInstagramStory,
                  icon: _busy ? null : Icons.auto_awesome_rounded,
                  onPressed: _busy ? null : _shareToStory,
                ),
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: const Icon(Icons.ios_share_rounded,
                        size: AppSizes.iconSm),
                    label: const Text(AppStrings.shareButton),
                  ),
                ),
              ] else
                PrimaryButton(
                  label: AppStrings.shareButton,
                  icon: _busy ? null : Icons.ios_share_rounded,
                  onPressed: _busy ? null : _share,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
