import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/widgets/color_selector.dart';
import 'package:rosario/widgets/patternn_painter.dart';
import 'package:rosario/widgets/row_editor.dart';

import '../data/saved_patterns.dart';
import '../models/pattern.dart';
import '../providers/history.dart';
import '../utils/canvas_utils.dart';
import 'edit_switch.dart';

class PatternCanvas extends ConsumerStatefulWidget {
  final BeadsPattern pattern;
  final Function? export;
  const PatternCanvas({super.key, required this.pattern, this.export});

  @override
  ConsumerState<PatternCanvas> createState() => _PatternCanvasState();
}

class _PatternCanvasState extends ConsumerState<PatternCanvas> {
  final GlobalKey canvasKey = GlobalKey();
  Color? selectedColor;
  bool moveble = true;
  bool isEditing = false;
  int rotation = 0;
  bool canRefresh = false;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    getSavedPatters().then((value) {
      setState(() {
        canRefresh = value
                .indexWhere((element) => element.name == widget.pattern.name) !=
            -1;
      });
    });
    Future.delayed(const Duration(microseconds: 200))
        .then((value) => ref.read(historyProvider.notifier).resetChanges());
  }

  onCanvasClick(PointerEvent event) {
    if (moveble) {
      return;
    }
    RenderBox? canvasBox =
        canvasKey.currentContext?.findRenderObject() as RenderBox;
    Offset localClick = canvasBox.globalToLocal(event.position);
    final r = widget.pattern.radius;
    final Path path = Path();
    for (int x = 0; x < widget.pattern.width; x++) {
      for (int y = 0; y < widget.pattern.height; y++) {
        // paint column
        if (y == 0) {
          final xC = Offset(x * r + r * 2, r / 2);
          path.addRect(Rect.fromCircle(center: xC, radius: r / 2));
          if (path.contains(localClick)) {
            ref
                .read(historyProvider.notifier)
                .pushChanges(widget.pattern.matrix!);
            setState(() {
              for (var element in widget.pattern.matrix!) {
                if (element[x] != null) {
                  element[x] = selectedColor;
                }
              }
            });
            return;
          }
        }

        // paint row
        final yC = Offset(r / 2, y * r + r * 2);
        path.addRect(Rect.fromCircle(center: yC, radius: r / 2));
        if (path.contains(localClick)) {
          ref
              .read(historyProvider.notifier)
              .pushChanges(widget.pattern.matrix!);
          setState(() {
            for (var i = 0; i < widget.pattern.matrix![y].length; i++) {
              widget.pattern.matrix![y][i] = selectedColor;
            }
          });
          return;
        }

        Offset? c = getOffset(x, y, widget.pattern);
        if (c != null) {
          path.addRect(Rect.fromCircle(center: c, radius: r / 2));
          if (path.contains(localClick)) {
            if (widget.pattern.matrix![y][x] != selectedColor) {
              ref
                  .read(historyProvider.notifier)
                  .pushChanges(widget.pattern.matrix!);
            }
            setState(() {
              widget.pattern.matrix![y][x] = selectedColor;
            });
            return;
          }
        }
      }
    }
  }

  paintAll() {
    ref.read(historyProvider.notifier).pushChanges(widget.pattern.matrix!);
    setState(() {
      for (int y = 0; y < widget.pattern.matrix!.length; y++) {
        var element = widget.pattern.matrix![y];
        for (int x = 0; x < element.length; x++) {
          if (widget.pattern.matrix != null) {
            widget.pattern.matrix![y][x] = selectedColor;
          }
        }
      }
    });
  }

  undo() {
    List<List<Color?>> prev = ref.read(historyProvider.notifier).popChange();
    setState(() {
      widget.pattern.matrix = prev;
      if (widget.pattern.width != widget.pattern.matrix!.length) {
        widget.pattern.width = widget.pattern.matrix![0].length;
      }
      if (widget.pattern.height != widget.pattern.matrix!.length) {
        widget.pattern.height = widget.pattern.matrix!.length;
      }
    });
  }

  zoom(int value) {
    var newValue = _transformationController.value.row0[0];
    newValue += value / 2;
    Matrix4 matrix4 =
        Matrix4(newValue, 0, 0, 0, 0, newValue, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    setState(() {
      selectedColor = null;
      moveble = true;
      _transformationController.value = matrix4;
    });
  }

  rotate() {
    setState(() {
      rotation++;
      if (rotation == 4) {
        rotation = 0;
      }
    });
  }

  refresh() async {
    confirm(context,
            textOK: const Text('Refresh'),
            content: const Text('Are you sure want to remove your changes?'),
            title: const Text('Pattern Refresh'))
        .then((approved) {
      if (approved) {
        getSavedPatters().then((value) {
          setState(() {
            BeadsPattern defaultPattern = value
                .firstWhere((element) => element.name == widget.pattern.name);
            widget.pattern.matrix = [...defaultPattern.matrix!];
          });
        });
      }
    });
  }

  showControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Card(
                color: const Color.fromARGB(255, 202, 202, 202),
                child: Column(
                  children: [
                    if (_transformationController.value.row0[0] > 1)
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: moveble && selectedColor == null
                                    ? Colors.black
                                    : Colors.transparent,
                                width: 2)),
                        child: IconButton(
                            padding: const EdgeInsets.all(2),
                            onPressed: () {
                              setState(() {
                                moveble = true;
                                selectedColor = null;
                              });
                            },
                            icon: const Icon(Icons.open_with)),
                      ),
                    Container(
                      height: 34,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: !moveble && selectedColor == null
                                  ? Colors.black
                                  : Colors.transparent,
                              width: 2)),
                      child: IconButton(
                          padding: const EdgeInsets.all(2),
                          onPressed: () {
                            setState(() {
                              moveble = false;
                              selectedColor = null;
                            });
                          },
                          icon: const Icon(Icons.close)),
                    ),
                    ColorSelector(
                        select: (color) => setState(() {
                              moveble = false;
                              selectedColor = color;
                            }),
                        pattern: widget.pattern,
                        selectedColor: selectedColor),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          SizedBox(
              width: 330,
              child: Card(
                  color: const Color.fromARGB(255, 202, 202, 202),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            selectedColor == null || moveble ? null : paintAll,
                        color: selectedColor,
                        icon: const Icon(Icons.format_color_fill),
                      ),
                      if (canRefresh)
                        IconButton(
                          onPressed: refresh,
                          icon: const Icon(Icons.refresh),
                        ),
                      IconButton(
                        onPressed:
                            ref.read(historyProvider).isNotEmpty ? undo : null,
                        icon: const Icon(Icons.undo),
                      ),
                      RowEditor(
                          pattern: widget.pattern,
                          afterChange: () {
                            setState(() {
                              selectedColor = null;
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                ref
                                    .read(historyProvider.notifier)
                                    .pushChanges(widget.pattern.matrix!);
                              });
                            });
                          })
                    ],
                  )))
        ])
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double canvasWidth = rotation == 0 || rotation == 2
        ? MediaQuery.of(context).size.width
        : MediaQuery.of(context).size.height - 140;
    double canvasHeight = rotation == 0 || rotation == 2
        ? MediaQuery.of(context).size.height - 140
        : MediaQuery.of(context).size.width;
    double patternWidth = widget.pattern.width * widget.pattern.radius +
        widget.pattern.radius * 4;
    double patternHeight = widget.pattern.height * widget.pattern.radius +
        widget.pattern.radius * 4;
    if (patternWidth > canvasWidth) canvasWidth = patternWidth;
    if (patternHeight > canvasHeight) canvasHeight = patternHeight;
    return Stack(
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey,
          height: double.infinity,
          padding: isEditing
              ? const EdgeInsets.fromLTRB(12, 58, 52, 18)
              : const EdgeInsets.fromLTRB(12, 58, 20, 18),
          child: FittedBox(
            child: Listener(
                onPointerDown: isEditing ? onCanvasClick : null,
                onPointerMove: isEditing ? onCanvasClick : null,
                child: RotatedBox(
                  quarterTurns: rotation,
                  child: SizedBox(
                    width: canvasWidth,
                    height: canvasHeight,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      scaleEnabled: false,
                      panEnabled: moveble,
                      child: CustomPaint(
                        key: canvasKey,
                        painter: PatternPainter(
                            rotation: rotation,
                            pattern: widget.pattern,
                            color: selectedColor ?? Colors.transparent,
                            isEditing: isEditing),
                        child: Container(),
                      ),
                    ),
                  ),
                )),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            EditSwitch(
                isEditing: isEditing,
                change: (bool value) => setState(() {
                      Color? firstColor = widget.pattern.colors?[0] == null
                          ? Colors.white
                          : widget.pattern.colors![0];
                      selectedColor = value ? firstColor : null;
                      isEditing = value;
                    })),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                    onPressed: rotate,
                    icon: const Icon(Icons.rotate_90_degrees_ccw)),
                IconButton(
                  onPressed: _transformationController.value.row0[0] == 3
                      ? null
                      : () => zoom(1),
                  icon: const Icon(Icons.zoom_in),
                ),
                IconButton(
                  onPressed: _transformationController.value.row0[0] == 1
                      ? null
                      : () => zoom(-1),
                  icon: const Icon(Icons.zoom_out),
                ),
                if (widget.export != null)
                  IconButton(
                      onPressed: () => widget.export!(context, widget.pattern),
                      icon: const Icon(Icons.ios_share))
              ],
            )
          ],
        ),
        if (isEditing)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: showControls(),
          )
      ],
    );
  }
}
