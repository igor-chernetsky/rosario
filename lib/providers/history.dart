import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryNotifier extends StateNotifier<List<List<List<Color?>>>> {
  HistoryNotifier() : super([]);

  initPatterns(List<List<List<Color>>> matrix) {
    state = matrix;
  }

  resetChanges() {
    state = [];
  }

  pushChanges(List<List<Color?>> matrix) {
    var value = matrix.map((e) => [...e]);
    state = [
      ...state,
      [...value]
    ];
  }

  popChange() {
    List<List<Color?>> prev = [...state.last];
    List<List<List<Color?>>> newState = [...state];
    newState.removeLast();
    state = newState;
    return prev;
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<List<List<Color?>>>>(
        (ref) => HistoryNotifier());
