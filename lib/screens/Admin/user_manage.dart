import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_user.dart';

class UserManageScreen extends StatelessWidget {
  final usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> _deleteUser(BuildContext context, String userId, String name) async {
    try {
      await usersRef.doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $name')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.red),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.red, Colors.pink]),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: usersRef.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());

              final users = snapshot.data?.docs ?? [];
              if (users.isEmpty)
                return Center(child: Text('No users found', style: TextStyle(color: Colors.white)));

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final data = user.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.red),
                      title: Text(data['name'] ?? ''),
                      subtitle: Text(data['email'] ?? ''),

                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.green),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditUserScreen(userId: user.id),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteUser(context, user.id, data['name'] ?? ''),
                          ),
                        ],
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
}