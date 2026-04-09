import 'package:flutter/material.dart';
// import '../screens/login_screen.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../un_authorized/api_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/app_drawer.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// 👇 IMPORT SCREENS
import '../screens/data_screen.dart';
import '../screens/students_screen.dart';
import '../screens/teachers_screen.dart';
import '../screens/classes_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/attendance_classes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List users = [];
  List students = [];
  List teachers = [];
  List classes = [];

  bool isConnected = true;
  bool isLoading = false;

  final List<String> images = [
    "https://picsum.photos/800/300?1",
    "https://picsum.photos/800/300?2",
    "https://picsum.photos/800/300?3",
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await checkInternet();
    if (isConnected) {
      await fetchDashboardData();
    }
  }

  /// 🌐 Internet check
  Future<void> checkInternet() async {
    var result = await Connectivity().checkConnectivity();
    bool connected = result != ConnectivityResult.none;

    setState(() => isConnected = connected);

    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No Internet Connection ❌"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🔄 Refresh
  Future<void> refreshPage() async {
    await checkInternet();
    if (isConnected) {
      await fetchDashboardData();
    }
  }

  /// 📊 Fetch dashboard data
  Future<void> fetchDashboardData() async {
    if (!isConnected) return;

    setState(() => isLoading = true);

    try {
      final data =
      await handleApi(context, () => ApiService.getDashboardData());

      if (data == null) return; // 🔥 FIX

      setState(() {
        users = data['users'] ?? [];
        students = data['students'] ?? [];
        teachers = data['teachers'] ?? [];
        classes = data['classes'] ?? [];
      });
    } catch (e) {
      users = [];
      students = [];
      teachers = [];
      classes = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔥 COMMON NAVIGATION FUNCTION (USED EVERYWHERE)
  void navigate(String title, String endpoint) {
    if (endpoint == "dashboard") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else if (endpoint == "profile") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    } else if (endpoint == "students") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentsScreen(title: title, endpoint: endpoint),
        ),
      );
    } else if (endpoint == "teachers") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TeachersScreen(title: title, endpoint: endpoint),
        ),
      );
    } else if (endpoint == "classes") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClassesScreen(title: title, endpoint: endpoint),
        ),
      );
    }else if (endpoint == "attendance") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AttendanceClassesScreen(),
        ),
      );
    }else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DataScreen(title: title, endpoint: endpoint),
        ),
      );
    }
  }

  /// 🎞 Hero Section
  Widget heroSection() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        viewportFraction: 1,
      ),
      items: images.map((img) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(img, fit: BoxFit.cover, width: double.infinity),
        );
      }).toList(),
    );
  }

  /// 📢 Notice Section
  Widget noticeSection() {
    DateTime now = DateTime.now();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📢 Notices",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Date: ${now.day}-${now.month}-${now.year}"),
            Text("Weekday: ${getWeekday(now.weekday)}"),
            const Divider(),
            const Text("• Exam starts next week"),
            const Text("• New admission open"),
            const Text("• Holiday on Friday"),
          ],
        ),
      ),
    );
  }

  String getWeekday(int day) {
    const days = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ];
    return days[day - 1];
  }

  /// 📊 Grid Dashboard
  Widget dashboardGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        gridItem("Users", users.length, Icons.person, Colors.blue, "users"),
        gridItem("Students", students.length, Icons.school, Colors.green, "students"),
        gridItem("Teachers", teachers.length, Icons.people, Colors.orange, "teachers"),
        gridItem("Classes", classes.length, Icons.class_, Colors.purple, "classes"),
        gridItem("Attendance", 0, Icons.assignment, Colors.red, "attendance"),
      ],
    );
  }

  Widget gridItem(String title, int count, IconData icon, Color color, String endpoint) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => navigate(title, endpoint),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("$count", style: TextStyle(fontSize: 18, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isConnected)
              const Text("No Internet Connection",
                  style: TextStyle(color: Colors.red)),

            heroSection(),
            const SizedBox(height: 15),
            noticeSection(),
            const SizedBox(height: 15),

            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            dashboardGrid(),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(Icons.info, color: Colors.blue),
                title: const Text("More Features Coming Soon"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}