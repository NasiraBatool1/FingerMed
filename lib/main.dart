import 'package:flutter/material.dart';
import 'package:p/screens/User/profile_screen.dart';


import 'package:p/screens/signup_screen.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/User/profile_screen.dart';
import 'screens/User/Home.dart';
import 'screens/User/blood_request.dart';
import 'screens/User/search_donors.dart';
import 'screens/User/blood_group_detection_screen.dart';
import 'screens/User/Home.dart';
import 'screens/User/location_screen.dart';
import 'screens/Admin/admin_dashboard.dart';
import 'screens/Admin/approve_donors_screen.dart';
import 'screens/Admin/user_manage.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
 );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/', // Set the initial route
      routes: {
        '/':(context)=>const SplashScreen(),

        '/login': (context) => LoginScreen(),// LoginScreen as the home screen
        '/signup':(context)=> SignupScreen(),
        '/searchDonor':(context)=>SearchDonorScreen(),
        '/bloodGroupDetection':(context)=>BloodGroupDetectionScreen(),
        '/adminDashboard':(context)=>AdminDashboard(),
        '/approveDonor':(context)=>ApproveDonorScreen(),
         '/userManage':(context)=>UserManageScreen(),
         '/postBloodRequest':(context)=>PostBloodRequestScreen(),
         '/home':(context)=>HomeScreen(),
        '/location':(context)=>LocationScreen(),


        // Add other routes as needed, e.g., '/profile', '/blood_requests', etc.
      },
    );
  }
}


