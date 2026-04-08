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

class _AttendanceStudentsScreenState
    extends State<AttendanceStudentsScreen> {
  List students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      final data = await handleApi(
        context,
            () => ApiService.getData(
          "students?class_id=${widget.classId}&section_id=${widget.sectionId}",
        ),
      );

      setState(() {
        students = data;
      });
    } catch (e) {
      students = [];
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<int, bool> attendance = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mark Attendance")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: students.length,
        itemBuilder: (context, index) {
          final student = students[index];
          int id = student['id'];

          return CheckboxListTile(
            title: Text(student['name'] ?? "Student"),
            value: attendance[id] ?? false,
            onChanged: (val) {
              setState(() {
                attendance[id] = val!;
              });
            },
          );
        },
      ),
    );
  }
}