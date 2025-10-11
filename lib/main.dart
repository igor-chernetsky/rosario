import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/providers/mypatterns.dart';
import 'package:rosario/providers/version_provider.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/screens/home.dart';
import 'package:rosario/screens/image_import.dart';
import 'package:rosario/screens/select_pattern.dart';
import 'package:rosario/screens/settings.dart';
import 'package:rosario/utils/colors_utils.dart';
import 'package:rosario/widgets/update_dialog.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'data/database_helper.dart';

final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await dbHelper.init();
  FlutterNativeSplash.remove();
  runApp(
    const ProviderScope(child: SagradaApp()),
  );
}

class SagradaApp extends ConsumerStatefulWidget {
  const SagradaApp({super.key});

  @override
  ConsumerState<SagradaApp> createState() => _SagradaAppState();
}

class _SagradaAppState extends ConsumerState<SagradaApp> {
  @override
  void initState() {
    super.initState();
    // Initialize patterns and check for updates after the app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // Initialize patterns
    final res = await dbHelper.queryAllRows();
    ref.read(myPatternsProvider.notifier).initPatterns(res);
    
    // Check for updates after a short delay to allow the app to load
    await Future.delayed(const Duration(seconds: 2));
    await ref.read(versionCheckProvider.notifier).checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to version check state changes
    ref.listen<VersionCheckState>(versionCheckProvider, (previous, next) {
      if (next.versionInfo != null && next.versionInfo!.isUpdateAvailable) {
        // Show update dialog if update is available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showUpdateDialogIfNeeded(
            context,
            next.versionInfo!,
            onDismiss: () {
              // User chose to dismiss the dialog
            },
          );
        });
      }
    });

    return MaterialApp(
      title: 'Rosario',
      theme: ThemeData(
        primaryColor: MaterialColor(0xFF0A3042, colorMap),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: MaterialColor(0xFF0A3042, colorMap)))),
        colorScheme: ColorScheme.fromSwatch(
            brightness: Brightness.light,
            cardColor: const Color(0xFF6E8FBF),
            primarySwatch: MaterialColor(0xFFF0E6DD, colorMap),
            accentColor: const Color(0xFF64ee85)),
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        SelectPatternScreen.routeName: (context) => const SelectPatternScreen(),
        EditPatternScreen.routeName: (context) => const EditPatternScreen(),
        ImageImport.routeName: (context) => const ImageImport(),
        SettingsScreen.routeName: (context) => const SettingsScreen(),
      },
    );
  }
}
