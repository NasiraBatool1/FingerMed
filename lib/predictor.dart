import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class BloodGroupDetector extends StatefulWidget {
  @override
  _BloodGroupDetectorState createState() => _BloodGroupDetectorState();
}

class _BloodGroupDetectorState extends State<BloodGroupDetector> {
  File? _image;
  String? _result;
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _image = imageFile;
      });
      await predict(imageFile);
    }
  }

  Future<void> predict(File imageFile) async {
    final interpreter = await Interpreter.fromAsset('Model/blood_model.tflite');

    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes)!;

    final resized = img.copyResize(image, width: 224, height: 224);

    var input = imageToByteListFloat32(resized, 224);
    var output = List.filled(1 * 8, 0.0).reshape([1, 8]);

    interpreter.run(input, output);

    int predictedIndex = output[0].indexWhere(
          (element) => element == output[0].reduce((a, b) => a > b ? a : b),
    );

    const bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    setState(() {
      _result = bloodTypes[predictedIndex];
    });
  }

  Uint8List imageToByteListFloat32(img.Image image, int inputSize) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = image.getPixel(x, y);
        buffer[pixelIndex++] = (img.getRed(pixel)) / 255.0;
        buffer[pixelIndex++] = (img.getGreen(pixel)) / 255.0;
        buffer[pixelIndex++] = (img.getBlue(pixel)) / 255.0;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Blood Group Detection")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null) Image.file(_image!, height: 200),
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.upload),
              label: Text("Upload Fingerprint"),
            ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Predicted Blood Group: $_result", style: TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
  }
}
