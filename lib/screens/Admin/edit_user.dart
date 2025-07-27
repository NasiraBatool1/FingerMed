import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditUserScreen extends StatefulWidget {
  final String userId;
  const EditUserScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _EditUserScreenState createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedRole = 'Donor';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['PhoneNo'] ?? ''; // ✅ Corrected
        _selectedRole = data['SelectedUserType'] ?? 'Donor'; // ✅ Corrected
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading user data')));
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'PhoneNo': _phoneController.text.trim(), // ✅ Corrected
          'SelectedUserType': _selectedRole, // ✅ Corrected
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User updated successfully')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit User', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.red),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.pink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: [
                  Text(
                    'Update User Information',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    hintText: 'Enter full name',
                    validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'Enter email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || !val.contains('@') ? 'Enter valid email' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone',
                    hintText: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                    validator: (val) => val == null || val.length < 10 ? 'Enter valid phone' : null,
                  ),
                  SizedBox(height: 16),
                  _buildRoleDropdown(),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: InputDecoration(border: InputBorder.none, labelText: 'Role'),
        items: ['Donor', 'Admin', 'Acceptor'].map((selectedUserType) {
          return DropdownMenuItem(value: selectedUserType, child: Text(selectedUserType));
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedRole = value!;
          });
        },
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
