import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:rosario/models/pattern.dart';

class ColorSelector extends StatefulWidget {
  final Function select;
  final Color? selectedColor;
  final BeadsPattern pattern;
  const ColorSelector(
      {super.key,
      required this.select,
      required this.selectedColor,
      required this.pattern});

  @override
  State<ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends State<ColorSelector> {
  List<Color> colorsList = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.green
  ];

  addColor() {
    setState(() {
      Color randomColor =
          Colors.primaries[Random().nextInt(Colors.primaries.length)];
      colorsList.add(randomColor);
    });
  }

  Color editColor = Colors.white;
  colorPicker(Color color, int index) {
    Color borderColor = color == widget.selectedColor &&
            widget.selectedColor != null
        ? (widget.selectedColor == Colors.black ? Colors.white : Colors.black)
        : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => widget.select(color),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, blurRadius: 2)
                ],
                borderRadius: const BorderRadius.all(
                  Radius.circular(4),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 22,
            child: IconButton(
                onPressed: () {
                  editColor = color;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a color!'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: editColor,
                          onColorChanged: (c) => setState(() {
                            editColor = c;
                          }),
                          paletteType: PaletteType.hslWithLightness,
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          child: const Text('Select Color'),
                          onPressed: () {
                            setState(() => colorsList[index] = editColor);
                            widget.pattern.colors = colorsList;
                            widget.select(editColor);
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
                padding: const EdgeInsets.all(4),
                splashRadius: 4,
                icon: const Icon(Icons.arrow_drop_down)),
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
    if (colorsList.length < 9)
      colorWidgets.add(
          IconButton(onPressed: addColor, icon: const Icon(Icons.plus_one)));
    return Column(children: colorWidgets);
  }
}
