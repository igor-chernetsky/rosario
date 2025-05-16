import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
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
        await FlutterImageGallerySaver.saveImage(image);
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
        iconSize: MediaQuery.of(context).size.width > 900 ? 24 : 20,
        icon: const Icon(Icons.image));
  }
}
