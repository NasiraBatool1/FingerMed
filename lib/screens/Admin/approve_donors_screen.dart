import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApproveDonorScreen extends StatelessWidget {
  final donorsRef = FirebaseFirestore.instance.collection('users');

  void _updateApproval(BuildContext context, String id, bool isApproved) async {
    try {
      await donorsRef.doc(id).update({'isApproved': isApproved});
      String statusText = isApproved ? 'approved' : 'rejected';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donor $statusText')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Donors', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.pink],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: donorsRef.where('isApproved', isEqualTo: false).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());

              final donors = snapshot.data?.docs ?? [];
              if (donors.isEmpty)
                return Center(child: Text('No pending donors', style: TextStyle(color: Colors.white)));

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: donors.length,
                itemBuilder: (context, index) {
                  final donor = donors[index];
                  final data = donor.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onTap: () => _showDialog(context, donor.id, data['name'], data),
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text(data['name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Blood: ${data['BloodGroup']} • City: ${data['City']}'),
                            if (data['CNICUrl'] != null)
                              Text('CNIC Uploaded ✅', style: TextStyle(fontSize: 12)),
                            if (data['BloodReportUrl'] != null)
                              Text('Report Uploaded ✅', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.red),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, String donorId, String name, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Approve Donor'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Approve $name as donor?'),
            SizedBox(height: 10),
            if (data['CNICUrl'] == null)
              Text('CNIC is missing!'),
            if (data['BloodReportUrl'] == null)
              Text('Blood Report is missing!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (data['CNICUrl'] != null && data['BloodReportUrl'] != null) {
                _updateApproval(context, donorId, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Cannot approve. Missing CNIC or Blood Report.')),
                );
              }
            },
            child: Text('Approve', style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateApproval(context, donorId, false);
            },
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
