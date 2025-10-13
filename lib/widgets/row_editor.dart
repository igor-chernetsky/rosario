import 'package:flutter/material.dart';
import '../models/pattern.dart';

class RowEditor extends StatefulWidget {
  final BeadsPattern pattern;
  final Function afterChange;
  const RowEditor(
      {super.key, required this.pattern, required this.afterChange});

  @override
  State<RowEditor> createState() => _RowEditorState();
}

class _RowEditorState extends State<RowEditor> {
  String side = 'bottom';
  String selectedStitchType = 'Square Stitch';

  List<DropdownMenuItem<String>> _getDropdownItems() {
    List<String> options = [];
    
    if (widget.pattern.patternId == 'Square Stitch') {
      if (side == 'left' || side == 'right') {
        options = ['Square Stitch', 'Peyote Stitch'];
      } else {
        options = ['Square Stitch', 'Brick Stitch'];
      }
    } else if (widget.pattern.patternId == 'Brick Stitch') {
      if (side == 'top' || side == 'bottom') {
        options = ['Square Stitch', 'Brick Stitch'];
      }
    } else if (widget.pattern.patternId == 'Peyote Stitch') {
      if (side == 'left' || side == 'right') {
        options = ['Square Stitch', 'Peyote Stitch'];
      }
    }
    
    return options.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  void _showEditDialog() {
    // Initialize selectedStitchType based on current pattern
    selectedStitchType = widget.pattern.patternId;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Size'),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Stitch type selector based on pattern and direction
                  if ((widget.pattern.patternId == 'Square Stitch') ||
                      (widget.pattern.patternId == 'Brick Stitch' && (side == 'top' || side == 'bottom')) ||
                      (widget.pattern.patternId == 'Peyote Stitch' && (side == 'left' || side == 'right'))) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text('Stitch Type:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: selectedStitchType,
                          items: _getDropdownItems(),
                          onChanged: (String? value) {
                            setState(() {
                              selectedStitchType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Side selector with arrows
                  const Text('Select Side:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Top arrow
                      IconButton(
                        onPressed: () {
                          setState(() {
                            side = 'top';
                            selectedStitchType = widget.pattern.patternId;
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_up),
                        tooltip: 'Top',
                        style: IconButton.styleFrom(
                          backgroundColor: side == 'top'
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      // Bottom arrow
                      IconButton(
                        onPressed: () {
                          setState(() {
                            side = 'bottom';
                            selectedStitchType = widget.pattern.patternId;
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_down),
                        tooltip: 'Bottom',
                        style: IconButton.styleFrom(
                          backgroundColor: side == 'bottom'
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      // Left arrow
                      IconButton(
                        onPressed: () {
                          setState(() {
                            side = 'left';
                            selectedStitchType = widget.pattern.patternId;
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_left),
                        tooltip: 'Left',
                        style: IconButton.styleFrom(
                          backgroundColor: side == 'left'
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                      // Right arrow
                      IconButton(
                        onPressed: () {
                          setState(() {
                            side = 'right';
                            selectedStitchType = widget.pattern.patternId;
                          });
                        },
                        icon: const Icon(Icons.keyboard_arrow_right),
                        tooltip: 'Right',
                        style: IconButton.styleFrom(
                          backgroundColor: side == 'right'
                              ? Colors.blue.shade200
                              : Colors.grey.shade200,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () {
                          _performAction(true);
                        },
                        icon: const Icon(Icons.remove),
                        tooltip: 'Remove',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _performAction(false);
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Add',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _performAction(bool isDeduct) {
    if (side == 'top' || side == 'bottom') {
      changeRow(isDeduct, side == 'top');
    } else {
      changeColumn(isDeduct, side == 'left');
    }
  }

  changeRow(bool isDeduct, bool fromBeginning) {
    for (var i = 0; i < widget.pattern.ydelta; i++) {
      setState(() {
        if (isDeduct) {
          // Handle rowsPattern when removing rows
          if (widget.pattern.rowsPattern != null) {
            List<int> rows =
                List<int>.from(widget.pattern.rowsPattern!['rows'] ?? []);

            if (fromBeginning) {
              // Remove from beginning - shift all indices down by 1
              rows = rows
                  .map((index) => index - 1)
                  .where((index) => index >= 0)
                  .toList();
            } else {
              // Remove from end - remove indices that are being removed
              int removedIndex = widget.pattern.height - 1;
              rows = rows.where((index) => index != removedIndex).toList();
            }

            // Update or remove rowsPattern
            if (rows.isEmpty) {
              widget.pattern.rowsPattern = null;
            } else {
              widget.pattern.rowsPattern!['rows'] = rows;
            }
          }

          widget.pattern.height -= 1;
          if (fromBeginning) {
            widget.pattern.matrix!.removeAt(0);
          } else {
            widget.pattern.matrix!.removeLast();
          }
        } else {
          widget.pattern.height += 1;
          List<Color?> row = [];
          for (var x = 0; x < widget.pattern.width; x++) {
            row.add(Colors.white);
          }
          if (fromBeginning) {
            widget.pattern.matrix!.insert(0, row);

            // Handle rowsPattern when adding rows at beginning
            if (selectedStitchType != widget.pattern.patternId) {
              widget.pattern.rowsPattern ??= {
                'patternId': selectedStitchType,
                'rows': <int>[]
              };

              // Shift existing indices up by 1
              List<int> rows =
                  List<int>.from(widget.pattern.rowsPattern!['rows'] ?? []);
              rows = rows.map((index) => index + 1).toList();
              rows.insert(0, 0);
              widget.pattern.rowsPattern!['rows'] = rows;
            } else if (widget.pattern.rowsPattern != null) {
              // Shift existing indices up by 1 even if patternId is the same
              List<int> rows =
                  List<int>.from(widget.pattern.rowsPattern!['rows'] ?? []);
              rows = rows.map((index) => index + 1).toList();
              widget.pattern.rowsPattern!['rows'] = rows;
            }
            
            // Handle columnsPattern when adding rows at beginning
            if (widget.pattern.columnsPattern != null) {
              // Shift existing column indices up by 1
              List<int> columns =
                  List<int>.from(widget.pattern.columnsPattern!['columns'] ?? []);
              columns = columns.map((index) => index + 1).toList();
              widget.pattern.columnsPattern!['columns'] = columns;
            }
          } else {
            widget.pattern.matrix!.add(row);

            // Handle rowsPattern when adding rows at end
            if (selectedStitchType != widget.pattern.patternId) {
              widget.pattern.rowsPattern ??= {
                'patternId': selectedStitchType,
                'rows': <int>[]
              };

              List<int> rows =
                  List<int>.from(widget.pattern.rowsPattern!['rows'] ?? []);
              int newRowIndex = widget.pattern.height - 1;
              if (!rows.contains(newRowIndex)) {
                rows.add(newRowIndex);
              }
              widget.pattern.rowsPattern!['rows'] = rows;
            }
          }
        }
      });
    }
    widget.afterChange();
  }

  changeColumn(bool isDeduct, bool fromBeginning) {
    setState(() {
      if (isDeduct) {
        // Handle columnsPattern when removing columns
        if (widget.pattern.columnsPattern != null) {
          List<int> columns =
              List<int>.from(widget.pattern.columnsPattern!['columns'] ?? []);

          if (fromBeginning) {
            // Remove from beginning - shift all indices down by xdelta
            columns = columns
                .map((index) => index - widget.pattern.xdelta)
                .where((index) => index >= 0)
                .toList();
          } else {
            // Remove from end - remove indices that are being removed
            int startIndex = widget.pattern.width - widget.pattern.xdelta;
            columns = columns.where((index) => index < startIndex).toList();
          }

          // Update or remove columnsPattern
          if (columns.isEmpty) {
            widget.pattern.columnsPattern = null;
          } else {
            widget.pattern.columnsPattern!['columns'] = columns;
          }
        }

        widget.pattern.width -= widget.pattern.xdelta;
        for (var element in widget.pattern.matrix!) {
          if (fromBeginning) {
            if (widget.pattern.xdelta > 1) {
              element.removeRange(0, widget.pattern.xdelta);
            } else {
              element.removeAt(0);
            }
          } else {
            if (widget.pattern.xdelta > 1) {
              element.removeRange(
                  element.length - widget.pattern.xdelta, element.length);
            } else {
              element.removeLast();
            }
          }
        }
      } else {
        widget.pattern.width += widget.pattern.xdelta;
        for (var element in widget.pattern.matrix!) {
          for (var i = 0; i < widget.pattern.xdelta; i++) {
            if (fromBeginning) {
              element.insert(0, Colors.white);
            } else {
              element.add(Colors.white);
            }
          }
        }

        // Handle columnsPattern when adding columns
        if (selectedStitchType != widget.pattern.patternId) {
          // Initialize columnsPattern if null
          widget.pattern.columnsPattern ??= {
            'patternId': selectedStitchType,
            'columns': <int>[]
          };

          // Add column indices to columnsPattern
          List<int> columns =
              List<int>.from(widget.pattern.columnsPattern!['columns'] ?? []);
          for (var i = 0; i < widget.pattern.xdelta; i++) {
            int columnIndex = fromBeginning
                ? i
                : widget.pattern.width - widget.pattern.xdelta + i;
            if (!columns.contains(columnIndex)) {
              columns.add(columnIndex);
            }
          }
          widget.pattern.columnsPattern!['columns'] = columns;
        } else if (widget.pattern.columnsPattern != null && fromBeginning) {
          // Shift existing column indices up by xdelta even if patternId is the same
          List<int> columns =
              List<int>.from(widget.pattern.columnsPattern!['columns'] ?? []);
          columns = columns.map((index) => index + widget.pattern.xdelta).toList();
          widget.pattern.columnsPattern!['columns'] = columns;
        }
        
        // Handle rowsPattern when adding columns at beginning
        if (widget.pattern.rowsPattern != null && fromBeginning) {
          // Shift existing row indices up by xdelta
          List<int> rows =
              List<int>.from(widget.pattern.rowsPattern!['rows'] ?? []);
          rows = rows.map((index) => index + widget.pattern.xdelta).toList();
          widget.pattern.rowsPattern!['rows'] = rows;
        }
      }
    });
    widget.afterChange();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: _showEditDialog,
          child:
              const Text('Change Size', style: TextStyle(color: Colors.black)),
          style: TextButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ],
    );
  }
}
