import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:p/Services/auth_service.dart';
import 'package:p/screens/login_screen.dart';
import '../widgets/custom_button.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();

  String selectedBloodGroup = '';
  String _selectedUserType = 'Donor';
 // String _selectedMaritalStatus = '';
  bool _isLoading = false;

  File? _cnicFile;
  File? _bloodReportFile;
  File? _profileImageFile;
  String? _profileImageUrl;

  final AuthService _authService = AuthService();

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: Duration(seconds: 1), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<String?> uploadToGoogleDrive(File file, String fileName) async {
    try {
      // 🔁 Replace with your actual Drive upload logic.
      // Return the public/shared file URL
      return 'https://drive.google.com/file/d/$fileName/view?usp=sharing';
    } catch (e) {
      print('Drive upload error: $e');
      return null;
    }
  }

  Future<void> _pickProfileImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      File imageFile = File(result.files.single.path!);
      setState(() {
        _profileImageFile = imageFile;
      });

      // Optional: Upload to Drive if required
      // _profileImageUrl = await uploadToGoogleDrive(imageFile, 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
    }
  }

  void _signup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? cnicUrl;
      String? bloodReportUrl;

      if (_cnicFile != null) {
        cnicUrl = await uploadToGoogleDrive(
          _cnicFile!,
          'cnic_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      if (_bloodReportFile != null) {
        bloodReportUrl = await uploadToGoogleDrive(
          _bloodReportFile!,
          'report_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
      }

      String? result = await _authService.signup(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        PhoneNo: phoneController.text.trim(),
        City: cityController.text.trim(),
        BloodGroup: selectedBloodGroup,
        SelectedUserType: _selectedUserType,
        CNICUrl: cnicUrl,
        BloodReportUrl: bloodReportUrl,
        profileImageUrl: _profileImageUrl,
      );

      setState(() => _isLoading = false);

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup Successful!")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Signup failed: $result")));
      }
    }
  }

  Future<void> _pickFile(bool isCnic) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isCnic) {
          _cnicFile = File(result.files.single.path!);
        } else {
          _bloodReportFile = File(result.files.single.path!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Sign Up')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text('Create Account!',
                        style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Sign up to get started',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600])),
                    SizedBox(height: 32),

                    // Profile Image Picker
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                        _profileImageFile != null ? FileImage(_profileImageFile!) : null,
                        child: _profileImageFile == null
                            ? Icon(Icons.add_a_photo, size: 40)
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),

                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: 'Full Name'),
                      validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter email';
                        final regex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        return regex.hasMatch(value) ? null : 'Invalid email';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.length < 8)
                          return 'Minimum 8 characters';
                        final regex = RegExp(
                            r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
                        return regex.hasMatch(value)
                            ? null
                            : 'Weak password';
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: 'Phone No'),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) =>
                      value == null || value.length != 11
                          ? '11-digit number'
                          : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: cityController,
                      decoration: InputDecoration(labelText: 'City'),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                      ],
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Enter city' : null,
                    ),
                  /*  SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Marital Status'),
                      value: _selectedMaritalStatus.isNotEmpty
                          ? _selectedMaritalStatus
                          : null,
                      items: ['Single', 'Married', 'Divorced', 'Widowed']
                          .map((status) => DropdownMenuItem(
                          value: status, child: Text(status)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedMaritalStatus = value!),
                      validator: (value) =>
                      value == null ? 'Select status' : null,
                    ),*/
                    SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Blood Group'),
                      value:
                      selectedBloodGroup.isNotEmpty ? selectedBloodGroup : null,
                      items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                          .map((group) => DropdownMenuItem(
                          value: group, child: Text(group)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => selectedBloodGroup = value!),
                      validator: (value) =>
                      value == null ? 'Select blood group' : null,
                    ),
                    SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'User Type'),
                      value: _selectedUserType,
                      items: ['Donor', 'Admin', 'Acceptor']
                          .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedUserType = value!),
                    ),
                    SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          'Optional: Upload CNIC and Blood Report for better approval chances.',
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickFile(true),
                          icon: Icon(Icons.picture_as_pdf),
                          label: Text(_cnicFile != null
                              ? 'CNIC Selected'
                              : 'Upload CNIC'),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _pickFile(false),
                          icon: Icon(Icons.medical_services),
                          label: Text(_bloodReportFile != null
                              ? 'Report Selected'
                              : 'Upload Report'),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    _isLoading
                        ? CircularProgressIndicator()
                        : AnimatedButton(onPressed: _signup, text: 'Save'),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
