import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/main.dart';
import 'package:uuid/uuid.dart';

import '../models/pattern.dart';

class MyPatternsNotifier extends StateNotifier<List<BeadsPattern>> {
  MyPatternsNotifier() : super([]);

  initPatterns(List<BeadsPattern> patterns) {
    state = patterns;
  }

  addPattern(BeadsPattern pattern) {
    var newState = [...state];
    var existingPatternIndex =
        newState.indexWhere((element) => element.id == pattern.id);
    if (existingPatternIndex == -1) {
      pattern.id = const Uuid().v4();
      newState.add(pattern);
      dbHelper.insert(pattern);
    } else {
      newState[existingPatternIndex] = pattern;
      dbHelper.update(pattern);
    }
    state = newState;
  }

  removePattern(String patternId) {
    state = state.where((element) => element.id != patternId).toList();
    dbHelper.delete(patternId);
  }
}

final myPatternsProvider =
    StateNotifierProvider<MyPatternsNotifier, List<BeadsPattern>>(
        (ref) => MyPatternsNotifier());
