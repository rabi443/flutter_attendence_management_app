import 'package:flutter/material.dart';
import '../screens/data_screen.dart';
import '../screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/students_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/teachers_screen.dart';
import '../screens/classes_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  /// 🔥 Logout
  Future<void> logout(BuildContext context) async {
    try {
      await ApiService.logout();
    } catch (e) {}

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  /// 🔥 Menu Item Widget
  Widget menuItem(
      BuildContext context, String title, IconData icon, String endpoint) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);

        if (endpoint == "dashboard") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
          );
        } else if (endpoint == "profile") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }else if (endpoint == "students") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  StudentsScreen(title: title, endpoint: endpoint),
            ),
          );
        }else if (endpoint == "teachers") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TeachersScreen(title: title, endpoint: endpoint),
            ),
          );
        }else if (endpoint == "classes") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ClassesScreen(title: title, endpoint: endpoint),
            ),
          );
        }else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DataScreen(title: title, endpoint: endpoint),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          /// 🔥 PROFILE HEADER (LEFT + RIGHT CLOSE)
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.deepPurple),
            child: Stack(
              children: [
                /// ❌ Top-right Close Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                /// 👤 Profile + Name (center-left)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Profile Image
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=3",
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    /// Name + View Profile
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfileScreen()),
                          );
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Rabin Chaudhary",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "View Profile",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 📂 Navigation
          menuItem(context, "Dashboard", Icons.dashboard, "dashboard"),
          menuItem(context, "Users", Icons.person, "users"),
          menuItem(context, "Students", Icons.school, "students"),
          menuItem(context, "Teachers", Icons.people, "teachers"),
          menuItem(context, "Classes", Icons.class_, "classes"),
          menuItem(context, "Profile", Icons.person_outline, "profile"),

          const Divider(),

          /// 🚪 Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red),
            ),
            onTap: () => logout(context),
          ),
        ],
      ),
    );
  }
}