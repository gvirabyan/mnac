import '../../core/l10n/app_strings.dart';
import '../../domain/entities/milestone.dart';

/// The words shown for a milestone: the catalogue's translations, or the
/// user's own title for one they added.
extension MilestoneText on Milestone {
  String get displayTitle => title ?? AppStrings.milestoneTitle(id);

  String get displayMessage => kind == MilestoneKind.custom
      ? AppStrings.customMilestoneMessage
      : AppStrings.milestoneMessage(id);
}
