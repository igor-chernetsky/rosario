import 'package:flutter/material.dart';

class BgSelector extends StatefulWidget {
  final Function select;
  final String? selected;
  const BgSelector({super.key, required this.select, required this.selected});

  @override
  State<BgSelector> createState() => _BgSelectorState();
}

List<String> backgrounds = ['bg1', 'bg2', 'bg3', 'bg5', 'bg7'];

class _BgSelectorState extends State<BgSelector> {
  openBackgroundSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  mainAxisSize: MainAxisSize.min,
                  children: backgrounds
                      .map((bg) => GestureDetector(
                            onTap: () {
                              widget.select(bg);
                              Navigator.pop(context);
                            },
                            child: Container(
                                width: MediaQuery.of(context).size.width > 900
                                    ? 60
                                    : 40,
                                height: MediaQuery.of(context).size.width > 900
                                    ? 60
                                    : 40,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: (widget.selected == bg ||
                                                (widget.selected == null &&
                                                    bg == 'bg1'))
                                            ? Colors.white
                                            : Colors.transparent,
                                        width: 3),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(30)),
                                    image: DecorationImage(
                                        image: AssetImage('assets/img/$bg.png'),
                                        repeat: ImageRepeat.repeat))),
                          ))
                      .toList()),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        openBackgroundSelector(context);
      },
      child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: const BorderRadius.all(Radius.circular(15)),
              image: DecorationImage(
                  image:
                      AssetImage('assets/img/${widget.selected ?? 'bg1'}.png'),
                  repeat: ImageRepeat.repeat))),
    );
  }
}
