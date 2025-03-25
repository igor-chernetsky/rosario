import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rosario/widgets/image_canvas.dart';

class ImageImport extends StatefulWidget {
  static String routeName = '/import';
  const ImageImport({Key? key}) : super(key: key);

  @override
  ImageImportState createState() => ImageImportState();
}

class ImageImportState extends State<ImageImport> {
  @override
  void initState() {
    pickImage(ImageSource.gallery).then((res) => {
          setState(() {
            img = File(res!.path);
          })
        });

    super.initState();
  }

  Widget imageBuilder(File file) {
    if (file.path.isNotEmpty) {
      return ImageCanvas(
        file: file,
      );
    } else {
      return imagePlaceHolder();
    }
  }

  Future<XFile?> pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        preferredCameraDevice: CameraDevice.rear);
    return image;
  }

  Widget imagePlaceHolder() {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(), bottom: BorderSide()),
      ),
      child: const Icon(Icons.add_a_photo),
    );
  }

  final _picker = ImagePicker();

  File img = File('');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(right: 60.0),
          child: Image.asset(
            'assets/img/rosario-logo.png',
            width: double.infinity,
            height: 40,
            fit: BoxFit.fitHeight,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: imageBuilder(img),
            ),
          ],
        ),
      ),
    );
  }
}
