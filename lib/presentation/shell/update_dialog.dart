import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../services/app_update_service.dart';

/// What the user did with the update dialog.
enum UpdateChoice { update, later }

/// Offers [update]. A required one cannot be closed: "Update" takes the user
/// to the store and the dialog stays for when they come back, so the future
/// never completes. An optional one closes with the user's choice; "Update"
/// is left to the caller, so it runs once the dialog is gone.
Future<UpdateChoice> showUpdateDialog(
  BuildContext context, {
  required AppUpdate update,
  required Future<void> Function() onUpdate,
}) async {
  final message = update.messages[AppStrings.language.id] ??
      (update.required ? AppStrings.updateRequiredBody : AppStrings.updateBody);

  final choice = await showDialog<UpdateChoice>(
    context: context,
    barrierDismissible: !update.required,
    builder: (context) => PopScope(
      canPop: !update.required,
      child: AlertDialog(
        icon: const Icon(Icons.system_update_rounded),
        title: Text(
          update.required
              ? AppStrings.updateRequiredTitle
              : AppStrings.updateTitle,
        ),
        content: Text(message),
        actions: [
          if (!update.required)
            TextButton(
              onPressed: () => Navigator.of(context).pop(UpdateChoice.later),
              child: Text(AppStrings.updateLater),
            ),
          FilledButton(
            onPressed: update.required
                ? onUpdate
                : () => Navigator.of(context).pop(UpdateChoice.update),
            child: Text(AppStrings.updateNow),
          ),
        ],
      ),
    ),
  );
  // Closed by tapping outside or "back": the same as "later".
  return choice ?? UpdateChoice.later;
}
