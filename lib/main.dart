import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/providers/mypatterns.dart';
import 'package:rosario/screens/edit.dart';
import 'package:rosario/screens/home.dart';
import 'package:rosario/screens/select_pattern.dart';
import 'data/database_helper.dart';

final dbHelper = DatabaseHelper();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.init();
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
        primarySwatch: Colors.indigo,
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
