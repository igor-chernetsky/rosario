import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/providers/mypatterns.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/screens/home.dart';
import 'package:rosario/screens/select_pattern.dart';
import 'package:rosario/utils/colors_utils.dart';
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

class SagradaApp extends ConsumerWidget {
  const SagradaApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    dbHelper
        .queryAllRows()
        .then((res) => ref.read(myPatternsProvider.notifier).initPatterns(res));
    return MaterialApp(
      title: 'Rosario',
      theme: ThemeData(
        primaryColor: MaterialColor(0xFF0A3042, colorMap),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                side: BorderSide(color: MaterialColor(0xFF0A3042, colorMap)))),
        colorScheme: ColorScheme.fromSwatch(
            brightness: Brightness.light,
            cardColor: const Color.fromARGB(200, 180, 180, 180),
            primarySwatch: MaterialColor(0xFF0A3042, colorMap),
            accentColor: const Color(0xFF64ee85)),
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        SelectPatternScreen.routeName: (context) => const SelectPatternScreen(),
        EditPatternScreen.routeName: (context) => const EditPatternScreen()
      },
    );
  }
}
