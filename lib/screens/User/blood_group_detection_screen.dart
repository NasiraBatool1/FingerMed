import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class BloodGroupDetectionScreen extends StatefulWidget {
  const BloodGroupDetectionScreen({Key? key}) : super(key: key);
  @override
  _BloodGroupDetectionScreenState createState() =>
      _BloodGroupDetectionScreenState();
}

class _BloodGroupDetectionScreenState extends State<BloodGroupDetectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  bool isDetecting = false;
  String? detectedBloodGroup;
  File? fingerprintImage;

  final ImagePicker _picker = ImagePicker();
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/Model/blood_type_model.tflite');

    // 🔍 Debug print for input/output tensor info
    final inputTensor = _interpreter.getInputTensor(0);
    final outputTensor = _interpreter.getOutputTensor(0);

    print('📥 Model input shape: ${inputTensor.shape}');
    print('📥 Model input type: ${inputTensor.type}');
    print('📤 Model output shape: ${outputTensor.shape}');
    print('📤 Model output type: ${outputTensor.type}');

  }

  Future<void> pickFingerprintImage() async {
    final XFile? pickedImage =
    await _picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        fingerprintImage = File(pickedImage.path);
        isDetecting = true;
        detectedBloodGroup = null;
      });

      // Wait and run detection
      final result = await runModelOnImage(File(pickedImage.path));

      setState(() {
        detectedBloodGroup = result;
        isDetecting = false;
      });
    }
  }

  Future<String> runModelOnImage(File imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final img.Image? oriImage = img.decodeImage(imageBytes);

    if (oriImage == null) return "Invalid Image";

    // Resize image to model input size (adjust 224 to match your model)
    final img.Image resizedImage = img.copyResize(oriImage, width: 128, height: 128);


    // Normalize image and reshape
    var input = List.generate(
      1,
          (i) => List.generate(
        128,
            (x) => List.generate(
          128,
              (y) {
            final pixel = resizedImage.getPixel(y, x);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    // Output shape depends on your model. Assuming 8 classes here:
    var output = [List.filled(8, 0.0)];
    print('Feeding input of shape: ${input.length}x${input[0].length}x${input[0][0].length}');

    _interpreter.run(input, output);
    print('Model output: $output');


    const bloodLabels = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

    int maxIndex = 0;
    double maxConfidence = output[0][0];

    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > maxConfidence) {
        maxConfidence = output[0][i];
        maxIndex = i;
      }
    }

    return bloodLabels[maxIndex];
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Blood Group Detection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.redAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Upload your fingerprint image to detect your blood group.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: isDetecting ? null : pickFingerprintImage,
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.upload_file,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (fingerprintImage != null)
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            fingerprintImage!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  if (isDetecting)
                    Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Detecting...',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  else if (detectedBloodGroup != null)
                    Column(
                      children: [
                        Text(
                          'Detected Blood Group:',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          detectedBloodGroup!,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: isDetecting
                        ? null
                        : () {
                      setState(() {
                        fingerprintImage = null;
                        detectedBloodGroup = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
