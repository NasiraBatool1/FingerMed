import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PostBloodRequestScreen extends StatefulWidget {
  @override
  _PostBloodRequestScreenState createState() => _PostBloodRequestScreenState();
}

class _PostBloodRequestScreenState extends State<PostBloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _patientNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _bloodGroupController = TextEditingController();

  String _selectedStatus = 'Donor';
  String _selectedUrgency = 'Normal';
  String? _editingDocId;

  void _clearForm() {
    _patientNameController.clear();
    _locationController.clear();
    _contactController.clear();
    _bloodGroupController.clear();
    _selectedStatus = 'Donor';
    _selectedUrgency = 'Normal';
    _editingDocId = null;
  }

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'patient_name': _patientNameController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'blood_group': _bloodGroupController.text.trim(),
        'status': _selectedStatus,
        'urgency': _selectedUrgency,
        'created_at': Timestamp.now(),
      };

      if (_editingDocId != null) {
        await FirebaseFirestore.instance.collection('blood_requests').doc(_editingDocId).update(data);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request updated!')));
      } else {
        await FirebaseFirestore.instance.collection('blood_requests').add(data);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Posted successfully!')));
      }

      _clearForm();
      Navigator.pop(context);
    }
  }

  Future<void> _deleteRequest(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Request'),
        content: Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(child: Text('Cancel'), onPressed: () => Navigator.pop(ctx, false)),
          TextButton(child: Text('Delete', style: TextStyle(color: Colors.red)), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('blood_requests').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post Deleted')));
    }
  }

  void _showPostForm({DocumentSnapshot? doc}) {
    if (doc != null) {
      final data = doc.data() as Map<String, dynamic>;
      _editingDocId = doc.id;
      _patientNameController.text = data['patient_name'] ?? '';
      _locationController.text = data['location'] ?? '';
      _contactController.text = data['contact'] ?? '';
      _bloodGroupController.text = data['blood_group'] ?? '';
      _selectedStatus = data['status'] ?? 'Donor';
      _selectedUrgency = data['urgency'] ?? 'Normal';
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            _editingDocId != null ? 'Edit Post' : 'New Blood Request',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_patientNameController, 'Name'),
                  _buildTextField(_locationController, 'Location'),
                  _buildTextField(_contactController, 'Contact Number'),
                  _buildTextField(_bloodGroupController, 'Blood Group'),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Donor', 'Acceptor'].map((status) {
                      return DropdownMenuItem(value: status, child: Text(status));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                    },
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedUrgency,
                    decoration: InputDecoration(
                      labelText: 'Urgency',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Urgent', 'Normal'].map((urgency) {
                      return DropdownMenuItem(value: urgency, child: Text(urgency));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedUrgency = value!);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _clearForm();
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              onPressed: _submitRequest,
              child: Text(_editingDocId != null ? 'Update' : 'Post'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildRequestItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final urgency = data['urgency'] ?? 'Normal';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: urgency == 'Urgent' ? Colors.red[50] : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: urgency == 'Urgent' ? Colors.red : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(Icons.bloodtype, color: urgency == 'Urgent' ? Colors.red : Colors.grey),
        title: Text(
          '${data['patient_name']} (${data['status'] ?? 'N/A'})',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Group: ${data['blood_group']}\nLocation: ${data['location']}\nUrgency: $urgency',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 8,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showPostForm(doc: doc),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteRequest(doc.id),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Posts', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Colors.red, Colors.redAccent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('blood_requests')
                .orderBy('urgency', descending: true)
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error loading requests'));
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return Center(child: Text('No blood requests found.', style: GoogleFonts.poppins(color: Colors.white)));

              return ListView(
                children: docs.map((doc) => _buildRequestItem(doc)).toList(),
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostForm(),
        backgroundColor: Colors.red,
        child: Icon(Icons.add),
        tooltip: 'New Blood Request',
      ),
    );
  }
}
