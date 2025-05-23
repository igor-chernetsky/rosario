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

  openPicker(color, index) {
    editColor = color;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color!'),
        content: SingleChildScrollView(
          child: isPaletteDynamic
              ? ColorPicker(
                  pickerColor: editColor,
                  onColorChanged: (c) => setState(() {
                    editColor = c;
                  }),
                  enableAlpha: false,
                  hexInputBar: true,
                  paletteType: PaletteType.hueWheel,
                )
              : BlockPicker(
                  availableColors: const [
                      Colors.black,
                      Colors.white,
                      Colors.red,
                      Colors.redAccent,
                      Colors.pink,
                      Colors.pinkAccent,
                      Colors.purple,
                      Colors.purpleAccent,
                      Colors.lightBlue,
                      Colors.lightBlueAccent,
                      Colors.blue,
                      Colors.blueAccent,
                      Colors.indigo,
                      Colors.indigoAccent,
                      Colors.green,
                      Colors.greenAccent,
                      Colors.lightGreen,
                      Colors.lightGreenAccent,
                      Colors.teal,
                      Colors.tealAccent,
                      Colors.lime,
                      Colors.limeAccent,
                      Colors.yellow,
                      Colors.yellowAccent,
                      Colors.orange,
                      Colors.orangeAccent,
                      Colors.brown,
                      Colors.amber,
                      Colors.amberAccent,
                      Colors.blueGrey,
                      Colors.grey,
                    ],
                  pickerColor: editColor,
                  onColorChanged: (c) => setState(() {
                        editColor = c;
                      })),
        ),
        actions: <Widget>[
          OutlinedButton(
            child: const Text('Change Palette'),
            onPressed: () {
              setState(() => isPaletteDynamic = !isPaletteDynamic);
              Navigator.of(context).pop();
              openPicker(color, index);
            },
          ),
          ElevatedButton(
            child: const Text('Select Color'),
            onPressed: () {
              setState(() {
                Color oldColor = colorsList[index];
                colorsList[index] = editColor;
                for (int y = 0; y < widget.pattern.matrix!.length; y++) {
                  var element = widget.pattern.matrix![y];
                  for (int x = 0; x < element.length; x++) {
                    if (widget.pattern.matrix != null &&
                        widget.pattern.matrix![y][x] == oldColor) {
                      widget.pattern.matrix![y][x] = editColor;
                    }
                  }
                }
              });
              widget.pattern.colors = colorsList;
              widget.select(editColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  bool isPaletteDynamic = false;
  Color editColor = Colors.white;
  colorPicker(Color color, int index) {
    Color borderColor = color == widget.selectedColor &&
            widget.selectedColor != null
        ? (widget.selectedColor == Colors.black ? Colors.white : Colors.black)
        : Colors.transparent;
    bool isBig = MediaQuery.of(context).size.width > 900;
    return Row(
      children: [
        GestureDetector(
          onTap: () => widget.select(color),
          child: Container(
            width: isBig ? 24 : 20,
            height: isBig ? 24 : 20,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: const [BoxShadow(color: Colors.black, blurRadius: 2)],
              borderRadius: const BorderRadius.all(
                Radius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 22,
          child: IconButton(
              onPressed: () => openPicker(color, index),
              padding: const EdgeInsets.all(4),
              splashRadius: 4,
              icon: const Icon(Icons.arrow_drop_down)),
        )
      ],
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
    if (colorsList.length < 9) {
      colorWidgets.add(
          IconButton(onPressed: addColor, icon: const Icon(Icons.plus_one)));
    }
    return Column(children: colorWidgets);
  }
}
