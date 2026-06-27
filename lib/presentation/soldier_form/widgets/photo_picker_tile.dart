import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../services/image_storage_service.dart';

/// A circular avatar that lets the user pick (and persist) a profile photo.
class PhotoPickerTile extends ConsumerWidget {
  const PhotoPickerTile({
    super.key,
    required this.photoPath,
    required this.onChanged,
    this.heroTag = 'profile-photo',
  });

  final String? photoPath;
  final ValueChanged<String?> onChanged;
  final String heroTag;

  Future<void> _pick(WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final storage = ref.read(imageStorageServiceProvider);
    final saved =
        await storage.savePickedImage(picked.path, prefix: 'profile');
    onChanged(saved);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();

    return Column(
      children: [
        Hero(
          tag: heroTag,
          child: GestureDetector(
            onTap: () => _pick(ref),
            child: CircleAvatar(
              radius: 64,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              backgroundImage:
                  hasPhoto ? FileImage(File(photoPath!)) : null,
              child: hasPhoto
                  ? null
                  : Icon(
                      Icons.add_a_photo_outlined,
                      size: AppSizes.iconLg,
                      color: theme.colorScheme.primary,
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        TextButton(
          onPressed: () => _pick(ref),
          child: Text(
            hasPhoto ? AppStrings.onbChangePhoto : AppStrings.onbAddPhoto,
          ),
        ),
        if (hasPhoto)
          TextButton(
            onPressed: () => onChanged(null),
            child: Text(
              AppStrings.persBackgroundRemove,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}
