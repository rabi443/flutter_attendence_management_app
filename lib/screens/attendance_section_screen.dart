import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../un_authorized/api_handler.dart';
import '../widgets/app_drawer.dart';

class AttendanceSectionScreen extends StatefulWidget {
  final int classId;
  final String className;

  const AttendanceSectionScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  _AttendanceSectionScreenState createState() =>
      _AttendanceSectionScreenState();
}

class _AttendanceSectionScreenState extends State<AttendanceSectionScreen> {
  List sections = [];
  List students = [];
  int? selectedSectionId;
  bool isLoadingSections = true;
  bool isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    fetchSections();
  }

  Future<void> fetchSections() async {
    try {
      final data = await handleApi(
          context,
              () => ApiService.getData(
              "classes/${widget.classId}/sections")); // API to get sections

      setState(() {
        sections = data ?? [];
      });
    } catch (e) {
      print("Error fetching sections: $e");
      sections = [];
    } finally {
      setState(() => isLoadingSections = false);
    }
  }

  Future<void> fetchStudents(int sectionId) async {
    setState(() => isLoadingStudents = true);
    try {
      final data = await handleApi(
          context,
              () => ApiService.getData(
              "sections/$sectionId/students")); // API to get students by section

      setState(() {
        students = data ?? [];
      });
    } catch (e) {
      print("Error fetching students: $e");
      students = [];
    } finally {
      setState(() => isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Attendance : ${widget.className}")),
      // ✅ Add the drawer here
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ✅ Section Dropdown Filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: isLoadingSections
                ? const CircularProgressIndicator()
                : DropdownButtonFormField<int>(
              value: selectedSectionId,
              hint: const Text("Select Section"),
              items: sections.map<DropdownMenuItem<int>>((section) {
                return DropdownMenuItem<int>(
                  value: section['id'],
                  child: Text(section['section_name'] ?? "Section"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedSectionId = val;
                });
                if (val != null) fetchStudents(val);
              },
            ),
          ),

          // ✅ Students List
          Expanded(
            child: isLoadingStudents
                ? const Center(child: CircularProgressIndicator())
                : students.isEmpty
                ? const Center(child: Text("No students found."))
                : ListView.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];

                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: student['user']?['profile_photo'] != null
                        ? NetworkImage(student['user']!['profile_photo'])
                        : const AssetImage('assets/images/B.png')
                    as ImageProvider, // fallback image
                  ),
                  title: Text(student['user']?['name'] ?? "Student"),
                  subtitle: Text("Roll No: ${student['roll_number'] ?? ""}"),
                  trailing: Checkbox(
                    value: student['isPresent'] ?? false,
                    onChanged: (val) {
                      setState(() {
                        student['isPresent'] = val;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}