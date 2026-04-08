import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../un_authorized/api_handler.dart';
import '../screens/attendance_section_screen.dart';
import '../widgets/app_drawer.dart';

class AttendanceClassesScreen extends StatefulWidget {
  const AttendanceClassesScreen({super.key});

  @override
  _AttendanceClassesScreenState createState() =>
      _AttendanceClassesScreenState();
}

class _AttendanceClassesScreenState
    extends State<AttendanceClassesScreen> {
  List classes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClasses();
  }

  Future<void> fetchClasses() async {
    try {
      final data =
      await handleApi(context, () => ApiService.getData("classes"));

      print("API RESPONSE: $data"); // 👈 ADD THIS

      setState(() {
        classes = data ?? [];
      });
    } catch (e) {
      print("ERROR: $e"); // 👈 ADD THIS
      classes = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Class")),
      // ✅ Add the drawer here
      drawer: const AppDrawer(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final cls = classes[index];

          return ListTile(
            title: Text(cls['class_name'] ?? "Class"),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttendanceSectionScreen(
                    classId: cls['id'],
                    className: cls['class_name'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}