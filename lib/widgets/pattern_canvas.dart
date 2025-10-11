import 'package:confirm_dialog/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/widgets/bg_selector.dart';
import 'package:rosario/widgets/color_list.dart';
import 'package:rosario/widgets/color_selector.dart';
import 'package:rosario/widgets/patternn_painter.dart';
import 'package:rosario/widgets/row_editor.dart';
import 'package:rosario/widgets/screenshotButton.dart';
import 'package:screenshot/screenshot.dart';

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
  String? bgColor = 'bg1';
  bool moveble = true;
  bool isEditing = false;
  bool showNumber = false;
  int rotation = 0;
  bool canRefresh = false;
  bool isCopyMode = false;
  String? copyType; // 'rows' or 'columns'
  Set<int> selectedRows = <int>{};
  Set<int> selectedColumns = <int>{};
  bool isDragging = false;
  bool hasMoved = false;
  int? dragStartRow;
  int? dragStartColumn;
  ScreenshotController screenshotController = ScreenshotController();
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
        canvasKey.currentContext?.findRenderObject() as RenderBox?;

    if (canvasBox == null) {
      return;
    }

    Offset localClick = canvasBox.globalToLocal(event.position);
    final r = widget.pattern.radius;
    final Path path = Path();

    // Handle copy mode selection
    if (isCopyMode) {
      for (int x = 0; x < widget.pattern.width; x++) {
        for (int y = 0; y < widget.pattern.height; y++) {
          // Check column selection (column numbers at top)
          if (y == 0) {
            final xC = Offset(x * r + r * 2, r / 2);
            path.addRect(Rect.fromCircle(center: xC, radius: r / 2));
            if (path.contains(localClick)) {
              setState(() {
                if (copyType == 'columns') {
                  _handleColumnSelection(x);
                }
              });
              return;
            }
          }

          // Check row selection (row numbers on left)
          final yC = Offset(r / 2, y * r + r * 2);
          path.addRect(Rect.fromCircle(center: yC, radius: r / 2));
          if (path.contains(localClick)) {
            setState(() {
              if (copyType == 'rows') {
                _handleRowSelection(y);
              }
            });
            return;
          }

          // Check individual bead selection for row/column copy
          Offset? c = getOffset(x, y, widget.pattern, false);
          if (c != null) {
            path.addRect(Rect.fromCircle(center: c, radius: r / 2));
            if (path.contains(localClick)) {
              setState(() {
                if (copyType == 'rows') {
                  _handleRowSelection(y);
                } else if (copyType == 'columns') {
                  _handleColumnSelection(x);
                }
              });
              return;
            }
          }
        }
      }
      return;
    }

    // Original painting logic when not in copy mode
    // Note: selectedColor can be null for bead removal

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
                  element[x] = selectedColor; // null removes the bead
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
              widget.pattern.matrix![y][i] =
                  selectedColor; // null removes the bead
            }
          });
          return;
        }

        Offset? c = getOffset(x, y, widget.pattern, false);
        if (c != null) {
          path.addRect(Rect.fromCircle(center: c, radius: r / 2));
          if (path.contains(localClick)) {
            if (widget.pattern.matrix![y][x] != selectedColor) {
              ref
                  .read(historyProvider.notifier)
                  .pushChanges(widget.pattern.matrix!);
            }
            setState(() {
              if (widget.pattern.matrix != null) {
                widget.pattern.matrix![y][x] =
                    selectedColor; // null removes the bead
              }
            });
            return;
          }
        }
      }
    }
  }

  onPointerDown(PointerEvent event) {
    if (moveble) {
      return;
    }

    if (isCopyMode) {
      // Reset movement tracking
      hasMoved = false;
      isDragging = false;

      // Find the initial row/column under the pointer and start selection
      _findRowColumnAtPosition(event.position, (row, column) {
        if (copyType == 'rows' && row != null) {
          dragStartRow = row;
          _handleRowSelection(row);
        } else if (copyType == 'columns' && column != null) {
          dragStartColumn = column;
          _handleColumnSelection(column);
        }
      });
    } else {
      // Use original click logic for non-copy mode
      onCanvasClick(event);
    }
  }

  onPointerMove(PointerEvent event) {
    if (moveble) {
      return;
    }

    if (isCopyMode) {
      // Mark that movement has occurred
      if (!hasMoved) {
        hasMoved = true;
        isDragging = true;
      }

      // Only update selection if we're actually dragging
      if (isDragging) {
        // Update selection based on current position
        _findRowColumnAtPosition(event.position, (row, column) {
          if (copyType == 'rows' && row != null && dragStartRow != null) {
            _updateRowSelectionRange(dragStartRow!, row);
          } else if (copyType == 'columns' &&
              column != null &&
              dragStartColumn != null) {
            _updateColumnSelectionRange(dragStartColumn!, column);
          }
        });
      }
    } else {
      // Handle drawing with drag in non-copy mode
      onCanvasClick(event);
    }
  }

  onPointerUp(PointerEvent event) {
    if (isCopyMode) {
      // Reset drag state
      isDragging = false;
      hasMoved = false;
      dragStartRow = null;
      dragStartColumn = null;
    }
  }

  void _findRowColumnAtPosition(
      Offset position, Function(int?, int?) callback) {
    RenderBox? canvasBox =
        canvasKey.currentContext?.findRenderObject() as RenderBox?;

    if (canvasBox == null) {
      callback(null, null);
      return;
    }

    Offset localClick = canvasBox.globalToLocal(position);
    final r = widget.pattern.radius;
    final Path path = Path();

    for (int x = 0; x < widget.pattern.width; x++) {
      for (int y = 0; y < widget.pattern.height; y++) {
        // Check column selection (column numbers at top)
        if (y == 0) {
          final xC = Offset(x * r + r * 2, r / 2);
          path.addRect(Rect.fromCircle(center: xC, radius: r / 2));
          if (path.contains(localClick)) {
            callback(null, x);
            return;
          }
        }

        // Check row selection (row numbers on left)
        final yC = Offset(r / 2, y * r + r * 2);
        path.addRect(Rect.fromCircle(center: yC, radius: r / 2));
        if (path.contains(localClick)) {
          callback(y, null);
          return;
        }

        // Check individual bead selection for row/column copy
        Offset? c = getOffset(x, y, widget.pattern, false);
        if (c != null) {
          path.addRect(Rect.fromCircle(center: c, radius: r / 2));
          if (path.contains(localClick)) {
            callback(y, x);
            return;
          }
        }
      }
    }
    callback(null, null);
  }

  void _updateRowSelectionRange(int startRow, int currentRow) {
    setState(() {
      selectedRows.clear();
      int minRow = startRow < currentRow ? startRow : currentRow;
      int maxRow = startRow > currentRow ? startRow : currentRow;

      for (int i = minRow; i <= maxRow; i++) {
        selectedRows.add(i);
      }
    });
  }

  void _updateColumnSelectionRange(int startColumn, int currentColumn) {
    setState(() {
      selectedColumns.clear();
      int minColumn = startColumn < currentColumn ? startColumn : currentColumn;
      int maxColumn = startColumn > currentColumn ? startColumn : currentColumn;

      for (int i = minColumn; i <= maxColumn; i++) {
        selectedColumns.add(i);
      }
    });
  }

  changeColor(Color color, Color newColor) {
    ref.read(historyProvider.notifier).pushChanges(widget.pattern.matrix!);
    setState(() {
      for (int y = 0; y < widget.pattern.matrix!.length; y++) {
        var element = widget.pattern.matrix![y];
        for (int x = 0; x < element.length; x++) {
          if (widget.pattern.matrix != null &&
              widget.pattern.matrix![y][x] == color) {
            widget.pattern.matrix![y][x] = newColor;
          }
        }
      }
    });
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
      // Only set moveble to true if not in edit mode or copy mode
      if (!isEditing && !isCopyMode) {
        moveble = true;
      }
      _transformationController.value = matrix4;
    });
  }

  zoomOut() {
    if (_transformationController.value.row0[0] == 1) {
      return;
    }
    zoom(-1);
    zoomOut();
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

  void toggleCopyMode() {
    if (isCopyMode) {
      setState(() {
        isCopyMode = false;
        copyType = null;
        selectedRows.clear();
        selectedColumns.clear();
        isDragging = false;
        hasMoved = false;
        dragStartRow = null;
        dragStartColumn = null;
        moveble = true; // Restore movement when exiting copy mode
      });
    } else {
      // Enter copy mode with rows selected by default
      setState(() {
        isCopyMode = true;
        copyType = 'rows';
        selectedRows.clear();
        selectedColumns.clear();
        isDragging = false;
        hasMoved = false;
        dragStartRow = null;
        dragStartColumn = null;
        moveble = false; // Disable movement for selection
      });
    }
  }

  void _handleRowSelection(int rowIndex) {
    setState(() {
      if (selectedRows.contains(rowIndex)) {
        // Deselect the row
        selectedRows.remove(rowIndex);
      } else {
        // Check if this row is consecutive with existing selection
        if (selectedRows.isEmpty) {
          selectedRows.add(rowIndex);
        } else {
          // Check if the new row is consecutive with any existing row
          bool isConsecutive = selectedRows
              .any((selectedRow) => (selectedRow - rowIndex).abs() == 1);

          if (isConsecutive) {
            selectedRows.add(rowIndex);
          } else {
            // Clear existing selection and add new row
            selectedRows.clear();
            selectedRows.add(rowIndex);
          }
        }
      }
    });
  }

  void _handleColumnSelection(int columnIndex) {
    setState(() {
      if (selectedColumns.contains(columnIndex)) {
        // Deselect the column
        selectedColumns.remove(columnIndex);
      } else {
        // Check if this column is consecutive with existing selection
        if (selectedColumns.isEmpty) {
          selectedColumns.add(columnIndex);
        } else {
          // Check if the new column is consecutive with any existing column
          bool isConsecutive = selectedColumns.any(
              (selectedColumn) => (selectedColumn - columnIndex).abs() == 1);

          if (isConsecutive) {
            selectedColumns.add(columnIndex);
          } else {
            // Clear existing selection and add new column
            selectedColumns.clear();
            selectedColumns.add(columnIndex);
          }
        }
      }
    });
  }

  void switchCopyType(String type) {
    setState(() {
      copyType = type;
      selectedRows.clear();
      selectedColumns.clear();
    });
  }

  void insertRowsAbove() {
    if (selectedRows.isEmpty) return;

    ref.read(historyProvider.notifier).pushChanges(widget.pattern.matrix!);
    setState(() {
      // Get the selected row data
      List<List<Color?>> rowsToCopy = [];
      for (int row in selectedRows) {
        rowsToCopy.add(List<Color?>.from(widget.pattern.matrix![row]));
      }

      // Insert rows above the first selected row
      int insertIndex = selectedRows.first;
      for (int i = 0; i < rowsToCopy.length; i++) {
        widget.pattern.matrix!
            .insert(insertIndex + i, List<Color?>.from(rowsToCopy[i]));
      }

      // Update pattern height
      widget.pattern.height = widget.pattern.matrix!.length;
    });
  }

  void insertRowsBelow() {
    if (selectedRows.isEmpty) return;

    ref.read(historyProvider.notifier).pushChanges(widget.pattern.matrix!);
    setState(() {
      // Get the selected row data
      List<List<Color?>> rowsToCopy = [];
      for (int row in selectedRows) {
        rowsToCopy.add(List<Color?>.from(widget.pattern.matrix![row]));
      }

      // Insert rows below the last selected row
      int insertIndex = selectedRows.last + 1;
      for (int i = 0; i < rowsToCopy.length; i++) {
        widget.pattern.matrix!
            .insert(insertIndex + i, List<Color?>.from(rowsToCopy[i]));
      }

      // Update pattern height
      widget.pattern.height = widget.pattern.matrix!.length;
    });
  }

  void insertColumnsLeft() {
    if (selectedColumns.isEmpty) return;

    ref.read(historyProvider.notifier).pushChanges(widget.pattern.matrix!);
    setState(() {
      // Get the selected column data
      List<List<Color?>> columnsToCopy = [];
      for (int col in selectedColumns) {
        List<Color?> column = [];
        for (int row = 0; row < widget.pattern.matrix!.length; row++) {
          column.add(widget.pattern.matrix![row][col]);
        }
        columnsToCopy.add(column);
      }

      // Insert columns to the left of the first selected column
      int insertIndex = selectedColumns.first;
      for (int i = 0; i < columnsToCopy.length; i++) {
        for (int row = 0; row < widget.pattern.matrix!.length; row++) {
          widget.pattern.matrix![row]
              .insert(insertIndex + i, columnsToCopy[i][row]);
        }
      }

      // Update pattern width
      widget.pattern.width = widget.pattern.matrix![0].length;
    });
  }

  void insertColumnsRight() {
    if (selectedColumns.isEmpty) return;

    ref.read(historyProvider.notifier).pushChanges(widget.pattern.matrix!);
    setState(() {
      // Get the selected column data
      List<List<Color?>> columnsToCopy = [];
      for (int col in selectedColumns) {
        List<Color?> column = [];
        for (int row = 0; row < widget.pattern.matrix!.length; row++) {
          column.add(widget.pattern.matrix![row][col]);
        }
        columnsToCopy.add(column);
      }

      // Insert columns to the right of the last selected column
      int insertIndex = selectedColumns.last + 1;
      for (int i = 0; i < columnsToCopy.length; i++) {
        for (int row = 0; row < widget.pattern.matrix!.length; row++) {
          widget.pattern.matrix![row]
              .insert(insertIndex + i, columnsToCopy[i][row]);
        }
      }

      // Update pattern width
      widget.pattern.width = widget.pattern.matrix![0].length;
    });
  }

  showCopyPanel() {
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
                    // Copy type selection
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => switchCopyType('rows'),
                          icon: Icon(
                            Icons.view_list,
                            color:
                                copyType == 'rows' ? Colors.blue : Colors.grey,
                          ),
                          tooltip: 'Copy Rows',
                        ),
                        IconButton(
                          onPressed: () => switchCopyType('columns'),
                          icon: Icon(
                            Icons.view_column,
                            color: copyType == 'columns'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          tooltip: 'Copy Columns',
                        ),
                      ],
                    ),

                    // Insert buttons (only show when rows/columns are selected)
                    if (copyType == 'rows' && selectedRows.isNotEmpty) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: insertRowsAbove,
                            icon: const Icon(Icons.keyboard_arrow_up),
                            tooltip: 'Insert Above',
                          ),
                          IconButton(
                            onPressed: insertRowsBelow,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            tooltip: 'Insert Below',
                          ),
                        ],
                      ),
                    ],

                    if (copyType == 'columns' &&
                        selectedColumns.isNotEmpty) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: insertColumnsLeft,
                            icon: const Icon(Icons.keyboard_arrow_left),
                            tooltip: 'Insert Left',
                          ),
                          IconButton(
                            onPressed: insertColumnsRight,
                            icon: const Icon(Icons.keyboard_arrow_right),
                            tooltip: 'Insert Right',
                          ),
                        ],
                      ),
                    ],

                    // Undo button (only show when there are changes to undo)
                    if (ref.read(historyProvider).isNotEmpty)
                      IconButton(
                        onPressed: undo,
                        icon: const Icon(Icons.undo),
                        tooltip: 'Undo',
                      ),

                    // Exit copy mode button
                    IconButton(
                      onPressed: toggleCopyMode,
                      icon: const Icon(Icons.close),
                      tooltip: 'Exit Copy Mode',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  showColors() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: ColorList(pattern: widget.pattern),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCopyInfoMessage() {
    String message;
    IconData icon;

    if (copyType == 'rows') {
      if (selectedRows.isNotEmpty) {
        message = 'You can insert selected rows above or below';
      } else {
        message = 'Select rows to duplicate them above or below';
      }
      icon = Icons.view_list;
    } else if (copyType == 'columns') {
      if (selectedColumns.isNotEmpty) {
        message = 'You can insert selected columns to left or right';
      } else {
        message = 'Select columns to duplicate them left or right';
      }
      icon = Icons.view_column;
    } else {
      // Default message when no copy type is selected
      message = 'Choose rows or columns to copy from the panel';
      icon = Icons.copy;
    }

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 300,
        minWidth: 200,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  showControls() {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
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
      ),
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
          height: double.infinity,
          color: Colors.blueGrey,
        ),
        Screenshot(
            controller: screenshotController,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  image: DecorationImage(
                      opacity: 0.6,
                      image: AssetImage("assets/img/$bgColor.png"),
                      repeat: ImageRepeat.repeat)),
              height: double.infinity,
              padding: isEditing
                  ? const EdgeInsets.fromLTRB(12, 58, 82, 18)
                  : const EdgeInsets.fromLTRB(12, 58, 20, 18),
              child: FittedBox(
                child: Listener(
                    onPointerDown:
                        (isEditing || isCopyMode) ? onPointerDown : null,
                    onPointerMove:
                        (isEditing || isCopyMode) ? onPointerMove : null,
                    onPointerUp: (isEditing || isCopyMode) ? onPointerUp : null,
                    child: RotatedBox(
                      quarterTurns: rotation,
                      child: SizedBox(
                        width: canvasWidth,
                        height: canvasHeight,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          scaleEnabled: false,
                          panEnabled: moveble,
                          child: RepaintBoundary(
                            key: ValueKey(
                                '${selectedRows.toString()}_${selectedColumns.toString()}_${isCopyMode}_${copyType}'),
                            child: CustomPaint(
                              key: canvasKey,
                              painter: PatternPainter(
                                  rotation: rotation,
                                  pattern: widget.pattern,
                                  showNumbers: showNumber,
                                  color: selectedColor ?? Colors.transparent,
                                  isEditing: isEditing,
                                  selectedRows:
                                      isCopyMode ? selectedRows : null,
                                  selectedColumns:
                                      isCopyMode ? selectedColumns : null,
                                  copyType: isCopyMode ? copyType : null),
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    )),
              ),
            )),
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
                      moveble =
                          !value; // Disable movement when editing, enable when not editing
                    })),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                BgSelector(
                    selected: bgColor,
                    select: (String value) => setState(() {
                          bgColor = value;
                        })),
                IconButton(
                  onPressed: () {
                    setState(() {
                      showNumber = !showNumber;
                    });
                  },
                  icon: const Icon(Icons.onetwothree),
                  iconSize: 34,
                  color: showNumber ? Colors.red : Colors.black,
                ),
                IconButton(
                    onPressed: rotate,
                    iconSize: MediaQuery.of(context).size.width > 900 ? 24 : 20,
                    icon: const Icon(Icons.rotate_90_degrees_ccw)),
                IconButton(
                  onPressed: _transformationController.value.row0[0] == 3
                      ? null
                      : () => zoom(1),
                  iconSize: MediaQuery.of(context).size.width > 900 ? 24 : 20,
                  icon: const Icon(Icons.zoom_in),
                ),
                IconButton(
                  onPressed: _transformationController.value.row0[0] == 1
                      ? null
                      : () => zoom(-1),
                  iconSize: MediaQuery.of(context).size.width > 900 ? 24 : 20,
                  icon: const Icon(Icons.zoom_out),
                ),
                // if (widget.export != null)
                //   IconButton(
                //       onPressed: () => widget.export!(context, widget.pattern),
                //       icon: const Icon(Icons.ios_share)),
                if (isEditing)
                  IconButton(
                    onPressed: toggleCopyMode,
                    icon: Icon(isCopyMode ? Icons.close : Icons.copy),
                  ),
                if (!isEditing)
                  ScreenshotButton(
                      screenshotController: screenshotController,
                      zoomOut: zoomOut),
              ],
            )
          ],
        ),
        if (isCopyMode)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: showCopyPanel(),
          )
        else if (isEditing)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: showControls(),
          )
        else if (!isEditing)
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: showColors(),
          ),
        // Copy mode info message
        if (isCopyMode)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: _buildCopyInfoMessage(),
              ),
            ),
          ),
      ],
    );
  }
}
