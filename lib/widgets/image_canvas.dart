import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rosario/models/pattern.dart';
import 'package:rosario/providers/mypatterns.dart';
import 'package:rosario/utils/canvas_utils.dart';
import 'package:rosario/utils/img_utils.dart';
import 'package:hold_down_button/hold_down_button.dart';

class ImageCanvas extends ConsumerStatefulWidget {
  final GlobalKey canvasKey = GlobalKey();
  File file;
  BeadsPattern? pattern;
  ImageBreakDetails? details;
  bool moving = false;
  double dx = 0;
  double dy = 0;
  ImageCanvas({super.key, required this.file});

  @override
  ConsumerState<ImageCanvas> createState() => _ImageCanvasState();
}

class _ImageCanvasState extends ConsumerState<ImageCanvas> {
  final nameController = TextEditingController();
  @override
  void initState() {
    decodeImageFromList(widget.file.readAsBytesSync()).then((res) {
      double radius = MediaQuery.sizeOf(context).width / (2 * res.width);
      setState(() {
        widget.details =
            getImgSizing(res.width, res.height, 20, radius, 'Square Stitch');
      });
    });
    super.initState();
  }

  updatePattern() {
    BeadsPattern ptrn =
        breakImage(widget.details!, widget.file, widget.dx, widget.dy);
    setState(() {
      widget.pattern = ptrn;
    });
  }

  savePattern(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        if (widget.pattern!.name != null) {
          nameController.text = widget.pattern!.name!;
        }
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    controller: nameController,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            widget.pattern!.name = nameController.text;
                            widget.pattern!.height =
                                widget.pattern!.matrix!.length;
                            widget.pattern!.width =
                                widget.pattern!.matrix![0].length;
                          });
                          ref
                              .read(myPatternsProvider.notifier)
                              .addPattern(widget.pattern!);
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: const Text('Save'),
                      ),
                      OutlinedButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  changePattern(patternId) {
    double radius =
        MediaQuery.sizeOf(context).width / (2 * widget.details!.width);
    setState(() {
      widget.details!.patternId = patternId;
      widget.details = getImgSizing(
          widget.details!.width,
          widget.details!.height,
          widget.details!.horizontal,
          radius,
          widget.details!.patternId);
    });
  }

  movePattern(bool isX, double value) {
    setState(() {
      if (isX) {
        widget.dx += value;
      } else {
        widget.dy += value;
      }
    });
  }

  getMoveImageWidgets() {
    return [
      HoldDownButton(
        onHoldDown: widget.dy >= -(widget.details?.radius ?? 0)
            ? () => movePattern(false, -1)
            : () => {},
        child: IconButton(
          onPressed: widget.dy >= -(widget.details?.radius ?? 0)
              ? () => movePattern(false, -1)
              : null,
          icon: const Icon(Icons.arrow_upward),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          HoldDownButton(
            onHoldDown: widget.dx > -(widget.details?.radius ?? 0)
                ? () => movePattern(true, -1)
                : () => {},
            child: IconButton(
              onPressed: widget.dx > -(widget.details?.radius ?? 0)
                  ? () => movePattern(true, -1)
                  : null,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          HoldDownButton(
            onHoldDown: widget.dx < 2 * (widget.details?.radius ?? 0)
                ? () => movePattern(true, 1)
                : () => {},
            child: IconButton(
              onPressed: widget.dx < 2 * (widget.details?.radius ?? 0)
                  ? () => movePattern(true, 1)
                  : null,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ],
      ),
      HoldDownButton(
        onHoldDown: widget.dy < 2 * (widget.details?.radius ?? 0)
            ? () => movePattern(false, 1)
            : () => {},
        child: IconButton(
          onPressed: widget.dy < 2 * (widget.details?.radius ?? 0)
              ? () => movePattern(false, 1)
              : null,
          icon: const Icon(Icons.arrow_downward),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => {
            setState(() {
              widget.moving = !widget.moving;
            })
          },
          icon: const Icon(Icons.arrow_back),
          label: const Text('Stom Moving'),
        ),
      ),
    ];
  }

  List<Widget> getButtons() {
    if (widget.details == null) {
      return [];
    }
    if (widget.moving) {
      return getMoveImageWidgets();
    }
    if (widget.pattern == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.details!.patternId == 'Square Stitch'
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor),
                  onPressed: () {
                    changePattern('Square Stitch');
                  },
                  child: Text('Square',
                      style: TextStyle(
                          color: widget.details!.patternId == 'Square Stitch'
                              ? Colors.white
                              : Theme.of(context).primaryColor))),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.details!.patternId == 'Brick Stitch'
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor),
                  onPressed: () {
                    changePattern('Brick Stitch');
                  },
                  child: Text(
                    'Brick',
                    style: TextStyle(
                        color: widget.details!.patternId == 'Brick Stitch'
                            ? Colors.white
                            : Theme.of(context).primaryColor),
                  )),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor:
                          widget.details!.patternId == 'Peyote Stitch'
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).cardColor),
                  onPressed: () {
                    changePattern('Peyote Stitch');
                  },
                  child: Text('Peyote',
                      style: TextStyle(
                          color: widget.details!.patternId == 'Peyote Stitch'
                              ? Colors.white
                              : Theme.of(context).primaryColor))),
            ],
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed:
                    widget.details != null && widget.details!.horizontal > 5
                        ? () => {
                              setState(() {
                                widget.details = widget.details!.change(-1);
                              })
                            }
                        : null,
                icon: const Icon(Icons.arrow_downward_outlined),
                label: const Text('Less Beads'),
              ),
              ElevatedButton.icon(
                onPressed:
                    widget.details != null && widget.details!.horizontal < 50
                        ? () => {
                              setState(() {
                                widget.details = widget.details!.change(1);
                              })
                            }
                        : null,
                icon: const Icon(Icons.arrow_upward_outlined),
                label: const Text('More Beads'),
              )
            ],
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => {
              setState(() {
                widget.moving = !widget.moving;
              })
            },
            icon: const Icon(Icons.open_with),
            label: const Text('Move Pattern'),
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.details != null ? () => {updatePattern()} : null,
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            label: const Text(
              'Make The Pattern',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor),
          ),
        )
      ];
    }
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ElevatedButton.icon(
            onPressed: () => {
              setState(() {
                widget.pattern = null;
              })
            },
            icon: const Icon(Icons.edit),
            label: const Text('Change'),
          ),
          ElevatedButton.icon(
            onPressed: () => {savePattern(context)},
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              CustomPaint(
                key: widget.canvasKey,
                painter: TemplatePainter(
                    details: widget.details,
                    pattern: widget.pattern,
                    dx: widget.dx,
                    dy: widget.dy),
                child: SizedBox(
                  width: double.infinity,
                  child: Image.file(
                    opacity: AlwaysStoppedAnimation(
                        widget.pattern == null ? .7 : 0.2),
                    File(
                      widget.file.path,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Column(
                children: getButtons(),
              )
            ],
          ),
        )
      ],
    );
  }
}

class TemplatePainter extends CustomPainter {
  ImageBreakDetails? details;
  BeadsPattern? pattern;
  double dx;
  double dy;
  TemplatePainter(
      {required this.details, this.pattern, this.dx = 0, this.dy = 0});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(Paint()..color = Colors.transparent);
    if (details != null) {
      for (int x = 0; x < details!.horizontal; x++) {
        for (int y = 0; y < details!.vertical; y++) {
          final paint = pattern == null ||
                  pattern?.matrix == null ||
                  pattern!.matrix![y][x] == null
              ? (Paint()..color = const Color.fromRGBO(255, 255, 255, 0.9))
              : (Paint()..color = pattern!.matrix![y][x]!);
          final c = getOffset(
              x,
              y,
              BeadsPattern(
                  width: x,
                  height: y,
                  patternId: details!.patternId,
                  radius: details!.radius * 2),
              true);
          if (c != null) {
            canvas.drawCircle(
                Offset(c.dx + dx, c.dy + dy), details!.radius, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
