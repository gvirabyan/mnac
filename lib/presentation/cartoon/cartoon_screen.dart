import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/l10n/app_strings.dart';
import '../../services/cartoon_avatar_service.dart';
import '../../services/image_storage_service.dart';
import '../shared/state/soldiers_controller.dart';
import '../shared/widgets/gradient_scaffold.dart';
import '../shared/widgets/primary_button.dart';

/// Turns a photo (the active soldier's by default) into a cartoon of the same
/// shot, shows it next to the original and lets the user keep it as the
/// soldier's photo or share it.
class CartoonScreen extends ConsumerStatefulWidget {
  const CartoonScreen({super.key});

  @override
  ConsumerState<CartoonScreen> createState() => _CartoonScreenState();
}

class _CartoonScreenState extends ConsumerState<CartoonScreen> {
  String? _sourcePath;
  String? _resultPath;
  bool _showOriginal = false;
  bool _busy = false;

  /// Files created here that end up unused — results never applied and
  /// photos picked only to be converted — removed on exit so abandoned
  /// attempts don't pile up in the documents directory.
  final List<String> _discarded = [];

  @override
  void initState() {
    super.initState();
    final photo = ref.read(activeSoldierProvider)?.photoPath;
    if (photo != null && File(photo).existsSync()) _sourcePath = photo;
  }

  @override
  void dispose() {
    final storage = ref.read(imageStorageServiceProvider);
    for (final path in _discarded) {
      storage.deleteIfExists(path);
    }
    super.dispose();
  }

  void _dropResult() {
    final result = _resultPath;
    if (result != null) _discarded.add(result);
    _resultPath = null;
    _showOriginal = false;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (picked == null) return;
    final saved = await ref
        .read(imageStorageServiceProvider)
        .savePickedImage(picked.path, prefix: 'photo');
    // Only a result ever becomes the soldier's photo, never a picked source.
    _discarded.add(saved);
    if (!mounted) return;
    setState(() {
      _dropResult();
      _sourcePath = saved;
    });
  }

  Future<void> _generate() async {
    final source = _sourcePath;
    if (source == null || _busy) return;

    // The photo leaves the device here, so ask every time.
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.cartoonTitle),
        content: Text(AppStrings.cartoonConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppStrings.cartoonContinue),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final result =
          await ref.read(cartoonAvatarServiceProvider).cartoonize(source);
      if (!mounted) {
        _discarded.add(result);
        return;
      }
      setState(() {
        _dropResult();
        _resultPath = result;
      });
    } on CartoonAvatarException catch (e) {
      debugPrint('$e');
      if (!mounted) return;
      final message = switch (e.failure) {
        CartoonFailure.network => AppStrings.cartoonFailedNetwork,
        CartoonFailure.rejected => AppStrings.cartoonFailedRejected,
        CartoonFailure.other => AppStrings.cartoonFailedOther,
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _apply() async {
    final result = _resultPath;
    final soldier = ref.read(activeSoldierProvider);
    if (result == null || soldier == null) return;
    await ref
        .read(soldiersControllerProvider.notifier)
        .addOrUpdate(soldier.copyWith(photoPath: result));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.cartoonApplied)),
    );
    Navigator.of(context).pop();
  }

  Future<void> _share() async {
    final result = _resultPath;
    if (result == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(result)], subject: AppStrings.appName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasResult = _resultPath != null;
    final shown = hasResult && !_showOriginal ? _resultPath : _sourcePath;

    return GradientScaffold(
      appBar: AppBar(title: Text(AppStrings.cartoonTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: shown == null
                      ? _EmptyPreview(onPick: _busy ? null : _pickPhoto)
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                              child: Image.file(
                                File(shown),
                                key: ValueKey(shown),
                                fit: BoxFit.contain,
                              ),
                            ),
                            if (_busy) const _GeneratingOverlay(),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              if (hasResult && !_busy) ...[
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: Text(AppStrings.cartoonOriginal),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text(AppStrings.cartoonResult),
                    ),
                  ],
                  selected: {_showOriginal},
                  onSelectionChanged: (value) =>
                      setState(() => _showOriginal = value.first),
                ),
                const SizedBox(height: AppSizes.md),
                PrimaryButton(
                  label: AppStrings.cartoonSetAsPhoto,
                  icon: Icons.check_rounded,
                  onPressed: _apply,
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _share,
                        icon: const Icon(Icons.ios_share_rounded,
                            size: AppSizes.iconSm),
                        label: Text(AppStrings.shareTitle),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.refresh_rounded,
                            size: AppSizes.iconSm),
                        label: Text(AppStrings.cartoonRetry),
                      ),
                    ),
                  ],
                ),
              ] else if (_busy)
                Text(
                  AppStrings.cartoonGenerating,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                )
              else if (_sourcePath != null) ...[
                PrimaryButton(
                  label: AppStrings.cartoonMake,
                  icon: Icons.auto_awesome_rounded,
                  onPressed: _generate,
                ),
                const SizedBox(height: AppSizes.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined,
                        size: AppSizes.iconSm),
                    label: Text(AppStrings.cartoonOtherPhoto),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.onPick});

  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome_rounded,
          size: AppSizes.xxxl,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          AppStrings.cartoonHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSizes.lg),
        PrimaryButton(
          label: AppStrings.cartoonPickPhoto,
          icon: Icons.photo_library_outlined,
          expand: false,
          onPressed: onPick,
        ),
      ],
    );
  }
}

class _GeneratingOverlay extends StatelessWidget {
  const _GeneratingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: const ColoredBox(
          color: Colors.black45,
          child: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
