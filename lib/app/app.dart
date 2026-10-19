import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_language.dart';
import '../core/l10n/app_strings.dart';
import '../presentation/shared/state/settings_controller.dart';
import '../presentation/shared/state/theme_providers.dart';
import 'router/app_router.dart';

/// Root application widget: wires the chosen language, the reactive theme,
/// and the startup gate.
class DepiTunApp extends ConsumerWidget {
  const DepiTunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language =
        ref.watch(settingsControllerProvider.select((s) => s.language));

    // Screens read their text from AppStrings, which no widget depends on,
    // so a language switch rebuilds the whole tree in place — open screens
    // and their state stay where they are.
    ref.listen(settingsControllerProvider.select((s) => s.language),
        (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _rebuildAll(context as Element);
      });
    });

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(lightThemeProvider),
      darkTheme: ref.watch(darkThemeProvider),
      themeMode: ref.watch(themeModeProvider),
      locale: language.locale,
      supportedLocales: [for (final l in AppLanguage.values) l.locale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Sits above every route so ad diagnostics stay visible during launch
      // and over a full-screen ad. No-op unless kAdDebugToasts is on.
      home: const RootGate(),
    );
  }
}

void _rebuildAll(Element root) {
  void mark(Element e) {
    e.markNeedsBuild();
    e.visitChildren(mark);
  }

  root.visitChildren(mark);
}
