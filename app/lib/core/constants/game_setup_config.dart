import '../../l10n/app_localizations.dart';

class GameSetupConfig {
  GameSetupConfig._();

  static const List<String> defaultCategories = [
    'social',
    'party',
    'food',
    'embarrassing',
  ];

  static const List<String> freeCategories = [
    'social',
    'party',
    'food',
    'embarrassing',
  ];

  static const List<String> premiumCategories = [
    'relationships',
    'confessions',
    'risk',
    'moral_gray',
    'deep',
    'sexual',
  ];

  static const List<String> allCategories = [
    'social',
    'party',
    'food',
    'embarrassing',
    'relationships',
    'confessions',
    'risk',
    'moral_gray',
    'deep',
    'sexual',
  ];

  static bool canStartGame({
    required List<String> categories,
    required String? selectedPackId,
  }) {
    return categories.isNotEmpty || selectedPackId != null;
  }

  static String categoryLabel(AppLocalizations l10n, String category) {
    return switch (category) {
      'social' => l10n.catSocial,
      'party' => l10n.catParty,
      'food' => l10n.catFood,
      'embarrassing' => l10n.catEmbarrassing,
      'relationships' => l10n.catRelationships,
      'confessions' => l10n.catConfessions,
      'risk' => l10n.catRisk,
      'moral_gray' => l10n.catMoralGray,
      'deep' => l10n.catDeep,
      'sexual' => l10n.catSexual,
      _ => category,
    };
  }

  static String categoryDescription(AppLocalizations l10n, String category) {
    return switch (category) {
      'social' => l10n.catDescSocial,
      'party' => l10n.catDescParty,
      'food' => l10n.catDescFood,
      'embarrassing' => l10n.catDescEmbarrassing,
      'relationships' => l10n.catDescRelationships,
      'confessions' => l10n.catDescConfessions,
      'risk' => l10n.catDescRisk,
      'moral_gray' => l10n.catDescMoralGray,
      'deep' => l10n.catDescDeep,
      'sexual' => l10n.catDescSexual,
      _ => '',
    };
  }

  static String? categoryDescriptionMessage(
    AppLocalizations l10n,
    String category,
  ) {
    final description = categoryDescription(l10n, category);
    if (description.isEmpty) return null;
    final label = categoryLabel(l10n, category);
    return '$label: $description';
  }
}
