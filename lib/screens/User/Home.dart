import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p/screens/User/inbox_screen.dart';
import 'package:p/screens/User/profile_screen.dart';
import 'package:p/screens/User/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';





class DonorDashboard extends StatefulWidget {

  @override
  _DonorDashboardState createState() => _DonorDashboardState();
}

class _DonorDashboardState extends State<DonorDashboard> {
  int _selectedIndex = 0;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Async-safe Firebase auth
  }

  void _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List<Widget> _screens = [
      HomeScreen(),
      InboxScreen(currentUserId: currentUserId!), // 👈 Pass the user ID here
      ProfileScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildDashboardOption(BuildContext context,
      {required String title, required IconData icon, required String route}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(icon, color: Colors.red),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.red),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Welcome!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildDashboardOption(
                        context,
                        title: 'Post For Blood',
                        icon: Icons.person,
                        route: '/postBloodRequest',
                      ),
                      _buildDashboardOption(
                        context,
                        title: 'Search Donors',
                        icon: Icons.search,
                        route: '/searchDonor',
                      ),
                      _buildDashboardOption(
                        context,
                        title: 'Blood Group Detection',
                        icon: Icons.bloodtype,
                        route: '/bloodGroupDetection',
                      ),
                      _buildDashboardOption(
                        context,
                        title: 'Search By location',
                        icon: Icons.bloodtype,
                        route: '/location',
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Column(
                          children: [
                            Icon(Icons.volunteer_activism,
                                size: 100, color: Colors.white24),
                            const SizedBox(height: 10),
                            Text(
                              '"Saving lives starts with a single drop."',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
