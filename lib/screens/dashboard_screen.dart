import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../un_authorized/api_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../widgets/app_drawer.dart';

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

  @override
  void initState() {
    super.initState();
    checkInternet();
    fetchDashboardData();
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

      setState(() {
        users = data['users'] ?? [];
        students = data['students'] ?? [];
        teachers = data['teachers'] ?? [];
        classes = data['classes'] ?? [];
      });
    } catch (e) {
      setState(() {
        users = [];
        students = [];
        teachers = [];
        classes = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔥 Summary Card
  Widget summaryCard(String title, int count, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Total: $count"),
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

      /// ✅ Drawer added
      drawer: const AppDrawer(),

      body: RefreshIndicator(
        onRefresh: refreshPage,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isConnected)
              const Text("No Internet Connection",
                  style: TextStyle(color: Colors.red)),

            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 10),

            /// 📊 Summary Cards
            summaryCard("Users", users.length, Icons.person, Colors.blue),
            summaryCard(
                "Students", students.length, Icons.school, Colors.green),
            summaryCard(
                "Teachers", teachers.length, Icons.people, Colors.orange),
            summaryCard(
                "Classes", classes.length, Icons.class_, Colors.purple),
          ],
        ),
      ),
    );
  }
}