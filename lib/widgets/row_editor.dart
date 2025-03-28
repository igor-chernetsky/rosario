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

  sideSelector() {
    const List<String> list = <String>['top', 'bottom', 'left', 'right'];
    return DropdownButton<String>(
      value: side,
      items: list.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          side = value!;
        });
      },
    );
  }

  changeRow(bool isDeduct, bool fromBeginning) {
    setState(() {
      if (isDeduct) {
        widget.pattern.width -= widget.pattern.xdelta;
        for (var element in widget.pattern.matrix!) {
          if (fromBeginning) {
            if (widget.pattern.xdelta > 1) {
              element.removeRange(0, widget.pattern.xdelta - 1);
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
      }
    });
    widget.afterChange();
  }

  changeColumn(bool isDeduct, bool fromBeginning) {
    for (var i = 0; i < widget.pattern.ydelta; i++) {
      setState(() {
        if (isDeduct) {
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
          } else {
            widget.pattern.matrix!.add(row);
          }
        }
      });
    }
    widget.afterChange();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (((side == 'top' || side == 'bottom') &&
                widget.pattern.height > widget.pattern.ydelta) ||
            ((side == 'left' || side == 'right') &&
                widget.pattern.width > widget.pattern.xdelta))
          IconButton(
              onPressed: () => (side == 'top' || side == 'bottom')
                  ? changeColumn(true, side == 'top')
                  : changeRow(true, side == 'left'),
              icon: const Icon(Icons.remove)),
        IconButton(
            onPressed: () => (side == 'top' || side == 'bottom')
                ? changeColumn(false, side == 'top')
                : changeRow(false, side == 'left'),
            icon: const Icon(Icons.add)),
        sideSelector()
      ],
    );
  }
}
