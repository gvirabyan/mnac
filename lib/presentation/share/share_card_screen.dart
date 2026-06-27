import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../domain/entities/service_progress.dart';
import '../../domain/entities/soldier_profile.dart';
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
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await captureBoundaryToPng(_boundaryKey);
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
                  child: FittedBox(
                    fit: BoxFit.contain,
                    // The boundary wraps the natural-size card so it is captured
                    // at full resolution regardless of the preview scaling.
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
              const SizedBox(height: AppSizes.lg),
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
