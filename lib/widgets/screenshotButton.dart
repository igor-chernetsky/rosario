import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';

class ScreenshotButton extends StatelessWidget {
  final ScreenshotController screenshotController;
  final Function zoomOut;
  const ScreenshotButton(
      {super.key, required this.screenshotController, required this.zoomOut});

  makeScreenshot(BuildContext context) async {
    zoomOut();
    Uint8List? image = await screenshotController.capture();
    try {
      if (image != null) {
        await ImageGallerySaver.saveImage(image);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Image Saved!',
          style: TextStyle(color: Colors.green, fontSize: 20),
        ),
      ));
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
        onPressed: () => makeScreenshot(context),
        icon: const Icon(Icons.image));
  }
}
