import 'package:flutter/material.dart';
import 'package:rosario/models/pattern.dart';
import 'package:rosario/utils/colors_utils.dart';

class ColorList extends StatefulWidget {
  final BeadsPattern pattern;
  const ColorList({super.key, required this.pattern});

  @override
  State<ColorList> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorList> {
  List<Color> colorsList = [];

  getColorNumber(Color color) {
    int result = 0;
    for (int i = 0; i < widget.pattern.matrix!.length; i++) {
      for (int j = 0; j < widget.pattern.matrix![i].length; j++) {
        if (widget.pattern.matrix![i][j] == color) {
          result++;
        }
      }
    }
    return result.toString();
  }

  bool isPaletteDynamic = false;
  Color editColor = Colors.white;
  colorPicker(Color color, int index) {
    bool isDark = getColorLight(color) < 400;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 2)],
              borderRadius: const BorderRadius.all(
                Radius.circular(16),
              ),
            ),
            child: Center(
                child: Text(
              getColorNumber(color),
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            )),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pattern.colors != null) {
      colorsList = widget.pattern.colors!;
    }
    List<Widget> colorWidgets = [];
    for (var index = 0; index < colorsList.length; index++) {
      colorWidgets.add(colorPicker(colorsList[index], index));
    }
    return Column(children: colorWidgets);
  }
}
