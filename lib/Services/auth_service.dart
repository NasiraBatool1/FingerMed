import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        return "User record not found in Firestore.";
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      if (userData['isApproved'] == true) {
        return userData['SelectedUserType']; // allow login, return role
      } else {
        await _auth.signOut(); // sign out the user since not approved
        return "Your account is pending admin approval.";
      }
    } catch (e) {
      return "Login failed: ${e.toString()}";
    }
  }

  Future<String?> signup({
    required String name,
    required String email,
    required String password,
    required String PhoneNo,
    required String City,
    required String BloodGroup,
    required String SelectedUserType,
    //  required String MaritalStatus,
    String? CNICUrl,
    String? BloodReportUrl,
    String? profileImageUrl,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'PhoneNo': PhoneNo.trim(),
        'City': City.trim(),
        'BloodGroup': BloodGroup.trim(),
        'SelectedUserType': SelectedUserType.trim(),
        // 'MaritalStatus': MaritalStatus.trim(),
        'isApproved': false,
        'status': 'pending',
        'CNICUrl': CNICUrl,
        'BloodReportUrl': BloodReportUrl,

      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
