import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../un_authorized/api_handler.dart';

class AttendanceStudentsScreen extends StatefulWidget {
  final int classId;
  final int sectionId;

  const AttendanceStudentsScreen({
    super.key,
    required this.classId,
    required this.sectionId,
  });

  @override
  _AttendanceStudentsScreenState createState() =>
      _AttendanceStudentsScreenState();
}

class _AttendanceStudentsScreenState extends State<AttendanceStudentsScreen> {
  List<dynamic> students = [];
  bool isLoading = true;
  Map<int, bool> attendance = {};

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() => isLoading = true);

    try {
      final data = await handleApi(
        context,
            () => ApiService.getData(
          "students?class_id=${widget.classId}&section_id=${widget.sectionId}",
        ),
      );

      setState(() {
        students = data ?? [];
        // Initialize attendance map for all students
        for (var student in students) {
          int id = student['id'] ?? 0;
          attendance[id] = false;
        }
      });
    } catch (e) {
      setState(() => students = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to fetch students")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void saveAttendance() {
    // Here you can send 'attendance' map to API
    print("Attendance: $attendance");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Attendance saved (demo)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mark Attendance"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : students.isEmpty
          ? const Center(child: Text("No students found"))
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          final int id = student['id'] ?? 0;

          return CheckboxListTile(
            title: Text(student['name'] ?? "Student"),
            value: attendance[id] ?? false,
            onChanged: (val) {
              setState(() {
                attendance[id] = val ?? false;
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: saveAttendance,
        child: const Icon(Icons.save),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}